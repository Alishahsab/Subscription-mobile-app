import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/db_row.dart';
import 'db_table.dart';
import 'outbox_op.dart';
import 'recent_writes.dart';

bool canRetry(Object error) {
  if (error is! PostgrestException) return true;
  final code = error.code;
  if (code == null) return true;
  final status = code.length == 3 ? int.tryParse(code) : null;
  if (status != null) return status == 401 || status == 408 || status == 429 || status >= 500;
  return code == 'PGRST301' || code == 'PGRST303';
}

class Outbox extends ChangeNotifier {
  Outbox(this._preferences, this._writes);

  final SharedPreferences _preferences;
  final RecentWrites _writes;
  final _problems = StreamController<String>.broadcast();

  List<OutboxOp> _ops = [];
  String _key = '';
  Timer? _retryTimer;
  Future<void>? _sending;

  void Function()? onRefused;
  void Function()? onDone;
  bool refreshWanted = false;

  Stream<String> get problems => _problems.stream;

  bool get isEmpty => _ops.isEmpty;

  bool get blockingRefresh => _ops.isNotEmpty && _ops.first.tries < 3;

  Set<String> get pendingMessageIds {
    return {
      for (final op in _ops)
        if (op.kind == OpKind.insert && op.table == DbTable.messages.name)
          for (final row in op.rows) row['id'] as String,
    };
  }

  void load(String userId) {
    _key = 'outbox_$userId';
    final saved = _preferences.getString(_key);
    final list = saved == null ? <dynamic>[] : jsonDecode(saved) as List<dynamic>;
    _ops = list.map((item) => OutboxOp.fromJson(item as DbRow)).toList();
  }

  void add(OutboxOp op) {
    _ops.add(op);
    _save();
    send();
  }

  void stop() {
    _retryTimer?.cancel();
    _ops = [];
    _key = '';
  }

  Future<void> send() {
    return _sending ??= _sendAll().whenComplete(() => _sending = null);
  }

  Future<void> _sendAll() async {
    var refused = false;

    while (_ops.isNotEmpty) {
      final op = _ops.first;
      try {
        await _run(op);
        _ops.removeAt(0);
        _save();
        _confirm(op);
      } catch (error) {
        if (canRetry(error)) {
          op.tries += 1;
          _save();
          _retryTimer?.cancel();
          _retryTimer = Timer(retryDelay(op.tries), send);
          return;
        }
        _ops.removeAt(0);
        _save();
        _forget(op);
        refused = true;
        _problems.add(error is PostgrestException ? error.message : error.toString());
      }
    }

    if (refused) {
      onRefused?.call();
    } else if (refreshWanted) {
      refreshWanted = false;
      onDone?.call();
    }
  }

  Future<void> _run(OutboxOp op) async {
    final client = Supabase.instance.client;
    final table = DbTable.all.where((item) => item.name == op.table).firstOrNull;

    switch (op.kind) {
      case OpKind.insert:
        final rows = op.tries > 0 ? await _missingRows(op, table!) : op.rows;
        if (rows.isNotEmpty) await client.from(op.table).insert(rows);
      case OpKind.update:
        final row = op.rows.first;
        await client.from(op.table).update(row).eq(table!.key, row[table.key] as Object);
      case OpKind.delete:
        await client.from(op.table).delete().inFilter(table!.key, op.ids);
      case OpKind.config:
        await client.from('store_config').upsert(op.rows.first);
    }
  }

  Future<List<DbRow>> _missingRows(OutboxOp op, DbTable table) async {
    final ids = op.rows.map((row) => row[table.key] as Object).toList();
    final saved = await Supabase.instance.client.from(op.table).select(table.key).inFilter(table.key, ids);
    final savedIds = saved.map((row) => row[table.key]).toSet();
    return op.rows.where((row) => !savedIds.contains(row[table.key])).toList();
  }

  void _confirm(OutboxOp op) {
    if (op.kind != OpKind.update) return;
    final table = DbTable.all.firstWhere((item) => item.name == op.table);
    _writes.confirmed(table, op.rows.first[table.key].toString());
  }

  void _forget(OutboxOp op) {
    if (op.kind == OpKind.delete || op.kind == OpKind.config) return;
    final table = DbTable.all.firstWhere((item) => item.name == op.table);
    for (final row in op.rows) {
      _writes.forget(table, row[table.key].toString());
    }
  }

  void _save() {
    notifyListeners();
    if (_key.isEmpty) return;
    if (_ops.isEmpty) {
      _preferences.remove(_key);
    } else {
      _preferences.setString(_key, jsonEncode(_ops));
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _problems.close();
    super.dispose();
  }
}
