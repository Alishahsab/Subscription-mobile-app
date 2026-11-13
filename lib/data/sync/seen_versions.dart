import '../models/db_row.dart';

class SeenVersions {
  final _versions = <String, Object>{};

  bool isNew(String table, String key, DbRow row) {
    final version = row['updated_at'];
    if (version == null) return true;

    final id = '$table:${row[key]}';
    if (_versions[id] == version) return false;
    _versions[id] = version;
    return true;
  }

  void clear() => _versions.clear();
}
