import 'dart:math';

import '../models/db_row.dart';

enum OpKind { insert, update, delete, config }

class OutboxOp {
  OutboxOp({required this.kind, required this.table, this.rows = const [], this.ids = const [], this.tries = 0});

  final OpKind kind;
  final String table;
  final List<DbRow> rows;
  final List<String> ids;
  int tries;

  factory OutboxOp.fromJson(DbRow json) {
    return OutboxOp(
      kind: OpKind.values.byName(json['kind'] as String),
      table: json['table'] as String,
      rows: (json['rows'] as List<dynamic>).cast<DbRow>(),
      ids: (json['ids'] as List<dynamic>).cast<String>(),
      tries: json['tries'] as int,
    );
  }

  DbRow toJson() => {'kind': kind.name, 'table': table, 'rows': rows, 'ids': ids, 'tries': tries};
}

Duration retryDelay(int tries) => Duration(seconds: min(30, 1 << min(tries, 5)));
