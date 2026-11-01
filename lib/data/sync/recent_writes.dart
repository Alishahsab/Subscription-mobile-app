import '../models/db_row.dart';
import 'db_table.dart';

const _protectedFor = Duration(seconds: 10);

class _Write {
  _Write(this.at, this.columns);

  DateTime at;
  final Set<String> columns;
}

class RecentWrites {
  final _writes = <String, _Write>{};

  void remember(DbTable table, DbRow row, {required bool inserted}) {
    final id = _idOf(table, row[table.key].toString());
    final previous = _writes[id];
    final stillFresh = previous != null && DateTime.now().difference(previous.at) < _protectedFor;
    final columns = stillFresh ? previous.columns : <String>{};

    row.forEach((column, value) {
      final isKey = column == table.key || column == 'created_at';
      if (!isKey && !(inserted && value == null)) columns.add(column);
    });
    _writes[id] = _Write(DateTime.now(), columns);
  }

  void confirmed(DbTable table, String id) => _writes[_idOf(table, id)]?.at = DateTime.now();

  void forget(DbTable table, String id) => _writes.remove(_idOf(table, id));

  DbRow merge(DbTable table, DbRow serverRow, DbRow? Function() localRow) {
    final write = _writes[_idOf(table, serverRow[table.key].toString())];
    if (write == null) return serverRow;
    if (DateTime.now().difference(write.at) >= _protectedFor) return serverRow;
    final local = localRow();
    if (local == null) return serverRow;

    return {
      ...serverRow,
      for (final column in write.columns)
        if (local.containsKey(column)) column: local[column],
    };
  }

  String _idOf(DbTable table, String id) => '${table.name}:$id';
}
