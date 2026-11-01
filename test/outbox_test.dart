import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/sync/db_table.dart';
import 'package:premium_store_admin/data/sync/outbox.dart';
import 'package:premium_store_admin/data/sync/outbox_op.dart';
import 'package:premium_store_admin/data/sync/recent_writes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('only a server refusal stops a change from being sent again', () {
    expect(canRetry(Exception('no internet')), isTrue);
    expect(canRetry(const PostgrestException(message: 'x')), isTrue);
    expect(canRetry(const PostgrestException(message: 'x', code: '401')), isTrue);
    expect(canRetry(const PostgrestException(message: 'x', code: '503')), isTrue);
    expect(canRetry(const PostgrestException(message: 'x', code: 'PGRST301')), isTrue);
    expect(canRetry(const PostgrestException(message: 'x', code: 'P0001')), isFalse);
    expect(canRetry(const PostgrestException(message: 'x', code: '23505')), isFalse);
  });

  test('the wait between tries grows up to 30 seconds', () {
    expect(retryDelay(0).inSeconds, 1);
    expect(retryDelay(1).inSeconds, 2);
    expect(retryDelay(4).inSeconds, 16);
    expect(retryDelay(9).inSeconds, 30);
  });

  test('a waiting change survives being saved and read back', () {
    final op = OutboxOp(kind: OpKind.update, table: 'orders', rows: [{'id': 'PS-1', 'status': 'completed'}], tries: 2);
    final saved = OutboxOp.fromJson(jsonDecode(jsonEncode(op)) as DbRow);

    expect(saved.kind, OpKind.update);
    expect(saved.rows.single['status'], 'completed');
    expect(saved.tries, 2);
  });

  test('own changes win over an older echo from the server', () {
    final writes = RecentWrites();
    writes.remember(DbTable.orders, {'id': 'PS-1', 'status': 'completed'}, inserted: false);

    final merged = writes.merge(
      DbTable.orders,
      {'id': 'PS-1', 'status': 'pending_review', 'code': 'ABC123'},
      () => {'id': 'PS-1', 'status': 'completed', 'code': null},
    );

    expect(merged['status'], 'completed');
    expect(merged['code'], 'ABC123');
  });

  test('a row nobody changed here is taken from the server as it is', () {
    final writes = RecentWrites();
    final row = {'id': 'PS-2', 'status': 'expired'};
    expect(writes.merge(DbTable.orders, row, () => throw StateError('not needed')), row);
  });

  test('empty columns of a new row can be filled by the server', () {
    final writes = RecentWrites();
    writes.remember(DbTable.messages, {'id': 'm1', 'text': 'hi', 'seen_at': null, 'created_at': 5}, inserted: true);

    final merged = writes.merge(
      DbTable.messages,
      {'id': 'm1', 'text': 'server', 'seen_at': 9, 'created_at': 7},
      () => {'id': 'm1', 'text': 'hi', 'seen_at': null, 'created_at': 5},
    );

    expect(merged['text'], 'hi');
    expect(merged['seen_at'], 9);
    expect(merged['created_at'], 7);
  });
}
