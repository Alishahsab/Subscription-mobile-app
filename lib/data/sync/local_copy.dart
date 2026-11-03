import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import '../models/db_row.dart';
import '../models/store_config.dart';
import 'app_data.dart';
import 'chat_window.dart';
import 'db_table.dart';

const _version = 1;

class SavedCopy {
  const SavedCopy(this.data, this.changesSince, this.lastFullLoadAt);

  final AppData data;
  final int? changesSince;
  final int lastFullLoadAt;
}

DbRow copyToJson(AppData data, int? changesSince, int lastFullLoadAt, int now) {
  final recentFrom = chatShownFrom(now);
  final recent = data.copyWith(messages: data.messages.where((item) => item.createdAt > recentFrom).toList());

  return {
    'version': _version,
    'changesSince': changesSince,
    'lastFullLoadAt': lastFullLoadAt,
    'config': data.config?.toRow(),
    'tables': {for (final table in DbTable.all) table.name: recent.rowsOf(table).toList()},
  };
}

SavedCopy? copyFromJson(DbRow json) {
  if (json['version'] != _version) return null;

  var data = const AppData(loaded: true);
  final tables = json['tables'] as DbRow;
  for (final table in DbTable.all) {
    data = data.withAllRows(table, (tables[table.name] as List<dynamic>).cast<DbRow>());
  }

  final config = json['config'] as DbRow?;
  if (config != null) data = data.copyWith(config: StoreConfig.fromRow(config));
  return SavedCopy(data, json['changesSince'] as int?, json['lastFullLoadAt'] as int);
}

class LocalCopy {
  File? _file;

  Future<SavedCopy?> load(String userId) async {
    final folder = await getApplicationSupportDirectory();
    final file = File('${folder.path}/copy_$userId.json');
    _file = file;

    try {
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      return await Isolate.run(() => copyFromJson(jsonDecode(text) as DbRow));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DbRow json) async {
    final file = _file;
    if (file == null) return;

    try {
      final text = await Isolate.run(() => jsonEncode(json));
      await file.writeAsString(text, flush: true);
    } catch (_) {
      await remove();
    }
  }

  Future<void> remove() async {
    final file = _file;
    _file = null;
    if (file != null && await file.exists()) await file.delete();
  }
}
