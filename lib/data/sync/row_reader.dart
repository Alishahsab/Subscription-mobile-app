import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/db_row.dart';
import 'db_table.dart';

const _pageSize = 1000;

class RowReader {
  RowReader(this._client);

  final SupabaseClient _client;

  Future<List<DbRow>> readAll(DbTable table, {int? after, int? upTo, String? changedSince}) async {
    final first = await _page(table, 0, after, upTo, changedSince).count(CountOption.exact);
    final rows = <DbRow>[...first.data];
    if (rows.length < _pageSize) return rows;

    final starts = <int>[for (var from = _pageSize; from < first.count; from += _pageSize) from];
    final pages = await Future.wait(starts.map((from) => _page(table, from, after, upTo, changedSince)));
    for (final page in pages) {
      rows.addAll(page);
    }

    var from = _pageSize * (starts.length + 1);
    while (rows.length == from) {
      rows.addAll(await _page(table, from, after, upTo, changedSince));
      from += _pageSize;
    }

    final unique = {for (final row in rows) row[table.key]: row};
    return unique.values.toList();
  }

  Future<List<DbRow>> readChat(String customerId, {required int before}) {
    return _client.from(DbTable.messages.name).select().eq('customer_id', customerId).lt('created_at', before).order('created_at');
  }

  Future<bool> hasChatBefore(String customerId, int before) async {
    final rows = await _client.from(DbTable.messages.name).select('id').eq('customer_id', customerId).lt('created_at', before).limit(1);
    return rows.isNotEmpty;
  }

  Future<DbRow?> readConfig({String? changedSince}) async {
    var query = _client.from('store_config').select();
    if (changedSince != null) query = query.gte('updated_at', changedSince);
    return query.maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestList> _page(DbTable table, int from, int? after, int? upTo, String? changedSince) {
    var query = _client.from(table.name).select();
    if (after != null) query = query.gt('created_at', after);
    if (upTo != null) query = query.lte('created_at', upTo);
    if (changedSince != null) query = query.gte('updated_at', changedSince);
    return query.order(table.key).range(from, from + _pageSize - 1);
  }
}
