import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/theme_controller.dart';
import '../models/db_row.dart';
import '../models/store_config.dart';
import 'app_data.dart';
import 'chat_window.dart';
import 'data_notifier.dart';
import 'db_table.dart';
import 'local_copy.dart';
import 'outbox.dart';
import 'outbox_op.dart';
import 'recent_writes.dart';
import 'row_reader.dart';
import 'server_clock.dart';

const _refreshEvery = Duration(minutes: 1);
const _loadRetry = Duration(seconds: 5);
const _saveDelay = Duration(milliseconds: 1500);
const _catchUpAfterHidden = Duration(seconds: 10);
const _fullLoadEvery = Duration(hours: 24);
const _changesOverlap = Duration(seconds: 15);
const _missingColumn = '42703';

enum _ChangesResult { done, failed, unsupported }

final clockProvider = Provider((ref) => ServerClock(ref.read(preferencesProvider)));

final syncProvider = Provider((ref) => SyncService(ref));

class SyncService with WidgetsBindingObserver {
  SyncService(this._ref) {
    _outbox = Outbox(_ref.read(preferencesProvider), _writes);
    _outbox.onRefused = () => catchUp(fullLoad: true);
    _outbox.onDone = catchUp;
  }

  final Ref _ref;
  final _writes = RecentWrites();
  late final Outbox _outbox;
  final _copy = LocalCopy();

  String? _userId;
  RealtimeChannel? _channel;
  Timer? _refreshTimer;
  Timer? _loadTimer;
  Timer? _saveTimer;
  DateTime? _hiddenSince;
  int? _changesSince;
  int _lastFullLoadAt = 0;
  int _localVersion = 0;
  bool _changesSupported = true;
  final _loadedChats = <String>{};
  final _olderChats = <String, bool>{};

  Outbox get outbox => _outbox;

  SupabaseClient get _client => Supabase.instance.client;

  RowReader get _reader => RowReader(_client);

  ServerClock get _clock => _ref.read(clockProvider);

  AppData get _data => _ref.read(dataProvider);

  void _change(AppData Function(AppData data) update) => _ref.read(dataProvider.notifier).change(update);

  int get _recentFrom => chatShownFrom(_clock.now);

  Future<void> start() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || _userId != null) return;
    _userId = userId;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_clock.sync());

    _outbox.load(userId);
    final copy = await _copy.load(userId);
    if (copy != null) {
      _change((_) => copy.data.withMessagesFrom(_recentFrom));
      _changesSince = copy.changesSince;
      _lastFullLoadAt = copy.lastFullLoadAt;
    }
    await _outbox.send();

    final fresh = copy != null && _changesSince != null && _fullLoadIsRecent;
    if (!fresh || await _loadChanges() == _ChangesResult.unsupported) await _loadEverything();

    if (_userId == null) return;
    _listen();
    _refreshTimer = Timer.periodic(_refreshEvery, (_) => _refreshIfVisible());
  }

  Future<void> stop({bool removeCopy = false}) async {
    if (_userId == null) return;
    _userId = null;
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _loadTimer?.cancel();
    _saveTimer?.cancel();
    _outbox.stop();
    _loadedChats.clear();
    _olderChats.clear();
    _changesSince = null;
    _lastFullLoadAt = 0;

    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
    if (removeCopy) await _copy.remove();
    _ref.read(dataProvider.notifier).clear();
  }

  void insert(DbTable table, DbRow row) {
    _changeLocally(table, row, inserted: true);
    _outbox.add(OutboxOp(kind: OpKind.insert, table: table.name, rows: [row]));
  }

  void update(DbTable table, String id, DbRow columns) {
    final row = {table.key: id, ...columns};
    final local = _data.rowOf(table, id);
    if (local == null) return;
    _changeLocally(table, {...local, ...row}, written: row);
    _outbox.add(OutboxOp(kind: OpKind.update, table: table.name, rows: [row]));
  }

  void delete(DbTable table, List<String> ids) {
    _localVersion += 1;
    _change((data) => ids.fold(data, (current, id) => current.withoutRow(table, id)));
    _outbox.add(OutboxOp(kind: OpKind.delete, table: table.name, ids: ids));
    _saveSoon();
  }

  void saveConfig(StoreConfig config) {
    _localVersion += 1;
    _change((data) => data.copyWith(config: config));
    _outbox.add(OutboxOp(kind: OpKind.config, table: 'store_config', rows: [config.toRow()]));
    _saveSoon();
  }

  Future<bool> hasOlderChat(String customerId) async {
    if (_loadedChats.contains(customerId)) return false;
    final known = _olderChats[customerId];
    if (known != null) return known;
    try {
      final found = await _reader.hasChatBefore(customerId, _recentFrom);
      _olderChats[customerId] = found;
      return found;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadOlderChat(String customerId) async {
    try {
      final rows = await _reader.readChat(customerId, before: _recentFrom);
      if (_userId == null) return false;
      _loadedChats.add(customerId);
      _olderChats[customerId] = false;
      _change((data) => data.withOlderMessages(rows));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _hiddenOlderMessage(DbTable table, DbRow row, AppData data) {
    if (table != DbTable.messages) return false;
    final createdAt = row['created_at'];
    if (createdAt is! int || createdAt > _recentFrom || _loadedChats.contains(row['customer_id'])) return false;
    return data.rowOf(table, row[table.key].toString()) == null;
  }

  Future<void> catchUp({bool fullLoad = false}) async {
    if (_userId == null) return;
    unawaited(_clock.sync());

    if (_outbox.blockingRefresh) {
      _outbox.refreshWanted = true;
      unawaited(_outbox.send());
      return;
    }
    if (_client.auth.currentSession == null) return;

    if (!fullLoad && _changesSupported && _fullLoadIsRecent) {
      final result = await _loadChanges();
      if (result != _ChangesResult.unsupported) return;
    }
    await _loadEverything(retry: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _hiddenSince = DateTime.now();
      _saveNow();
    }
    if (state == AppLifecycleState.resumed) {
      final hiddenSince = _hiddenSince;
      _hiddenSince = null;
      if (hiddenSince != null && DateTime.now().difference(hiddenSince) > _catchUpAfterHidden) catchUp();
    }
  }

  bool get _fullLoadIsRecent {
    return DateTime.now().millisecondsSinceEpoch - _lastFullLoadAt < _fullLoadEvery.inMilliseconds;
  }

  void _refreshIfVisible() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) catchUp();
  }

  void _changeLocally(DbTable table, DbRow row, {bool inserted = false, DbRow? written}) {
    _localVersion += 1;
    _writes.remember(table, written ?? row, inserted: inserted);
    _change((data) => data.withRow(table, row));
    _saveSoon();
  }

  Future<void> _loadEverything({bool retry = true}) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final version = _localVersion;
      final startedAt = _clock.now;
      final since = _recentFrom;

      try {
        final results = await Future.wait(DbTable.all.map((table) {
          return _reader.readAll(table, after: table == DbTable.messages ? since : null);
        }));
        final config = await _reader.readConfig();
        if (_userId == null) return;

        final customers = results[DbTable.all.indexOf(DbTable.customers)];
        if (customers.isEmpty && _data.customers.isNotEmpty) break;

        if (version == _localVersion || attempt == 2) {
          _applyEverything(results, config, since);
          _changesSince = _changesSupported ? startedAt : null;
          _lastFullLoadAt = DateTime.now().millisecondsSinceEpoch;
          _saveSoon();
          return;
        }
      } catch (_) {
        break;
      }
    }

    if (!retry || _userId == null) return;
    _loadTimer?.cancel();
    _loadTimer = Timer(_loadRetry, _loadEverything);
  }

  void _applyEverything(List<List<DbRow>> results, DbRow? config, int since) {
    _change((data) {
      var next = data;
      for (var index = 0; index < DbTable.all.length; index++) {
        final table = DbTable.all[index];
        next = table == DbTable.messages ? next.withRecentMessages(results[index], since) : next.withAllRows(table, results[index]);
      }
      if (config != null) next = next.copyWith(config: StoreConfig.fromRow(config));
      return next.copyWith(loaded: true);
    });
  }

  Future<_ChangesResult> _loadChanges() async {
    final changesSince = _changesSince;
    if (changesSince == null) return _ChangesResult.unsupported;
    final overlap = _changesOverlap.inMilliseconds;
    final changedSince = DateTime.fromMillisecondsSinceEpoch(changesSince - overlap, isUtc: true).toIso8601String();

    for (var attempt = 0; attempt < 3; attempt++) {
      final version = _localVersion;
      final startedAt = _clock.now;

      try {
        final results = await Future.wait(DbTable.all.map((table) => _reader.readAll(table, changedSince: changedSince)));
        final config = await _reader.readConfig(changedSince: changedSince);
        if (_userId == null) return _ChangesResult.failed;
        if (version != _localVersion) continue;

        if (config == null && results.every((rows) => rows.isEmpty)) {
          _changesSince = startedAt;
          return _ChangesResult.done;
        }

        _change((data) {
          var next = data;
          for (var index = 0; index < DbTable.all.length; index++) {
            final table = DbTable.all[index];
            for (final row in results[index]) {
              if (_hiddenOlderMessage(table, row, next)) continue;
              final local = next;
              next = next.withRow(table, _writes.merge(table, row, () => local.rowOf(table, row[table.key].toString())));
            }
          }
          if (config != null) next = next.copyWith(config: StoreConfig.fromRow(config));
          return next;
        });
        _changesSince = startedAt;
        _saveSoon();
        return _ChangesResult.done;
      } on PostgrestException catch (error) {
        if (error.code != _missingColumn) return _ChangesResult.failed;
        _changesSupported = false;
        return _ChangesResult.unsupported;
      } catch (_) {
        return _ChangesResult.failed;
      }
    }
    return _ChangesResult.failed;
  }

  void _listen() {
    final name = 'premium-store-admin-${Random().nextInt(1 << 32)}';
    var channel = _client.channel(name);

    for (final table in DbTable.all) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table.name,
        callback: (payload) => _onRemoteChange(table, payload),
      );
    }

    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'store_config',
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.delete) return;
        _change((data) => data.copyWith(config: StoreConfig.fromRow(payload.newRecord)));
      },
    );

    var subscribedBefore = false;
    channel.subscribe((status, [_]) {
      if (status != RealtimeSubscribeStatus.subscribed) return;
      if (subscribedBefore) catchUp();
      subscribedBefore = true;
    });
    _channel = channel;
  }

  void _onRemoteChange(DbTable table, PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord[table.key].toString();
      _change((data) => data.withoutRow(table, id));
    } else {
      final row = payload.newRecord;
      if (_hiddenOlderMessage(table, row, _data)) return;
      _change((data) => data.withRow(table, _writes.merge(table, row, () => data.rowOf(table, row[table.key].toString()))));
    }
    _saveSoon();
  }

  void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _saveNow);
  }

  void _saveNow() {
    _saveTimer?.cancel();
    if (_userId == null || !_data.loaded) return;
    _copy.save(copyToJson(_data, _changesSince, _lastFullLoadAt, _clock.now));
  }
}
