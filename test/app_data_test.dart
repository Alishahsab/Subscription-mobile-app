import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/sync/app_data.dart';
import 'package:premium_store_admin/data/sync/db_table.dart';
import 'package:premium_store_admin/data/sync/local_copy.dart';

DbRow message(String id, int createdAt, {String customerId = 'c1'}) {
  return {'id': id, 'customer_id': customerId, 'sender': 'bot', 'kind': 'text', 'text': 'hello', 'created_at': createdAt};
}

DbRow order(String id, {bool codeUnused = false, String customerId = 'c1'}) {
  return {
    'id': id,
    'customer_id': customerId,
    'plan_id': 'p',
    'plan_name': '3 Months',
    'amount': 769,
    'method_name': 'Easypaisa',
    'status': 'completed',
    'created_at': 1000,
    'expires_at': 2000,
    'code_unused': codeUnused,
  };
}

void main() {
  test('messages stay oldest first and a repeated id replaces the old one', () {
    var data = const AppData();
    data = data.withRow(DbTable.messages, message('b', 200));
    data = data.withRow(DbTable.messages, message('a', 100));
    data = data.withRow(DbTable.messages, {...message('b', 200), 'text': 'changed'});

    expect(data.messages.map((item) => item.id), ['a', 'b']);
    expect(data.messages.last.text, 'changed');
  });

  test('numbers sent as text by realtime are read correctly', () {
    final data = const AppData().withRow(DbTable.messages, {...message('a', 0), 'created_at': '1700000000000'});
    expect(data.messages.single.createdAt, 1700000000000);
  });

  test('a refresh replaces recent messages and keeps older ones', () {
    var data = const AppData().withAllRows(DbTable.messages, [message('old', 100), message('gone', 900)]);
    data = data.withRecentMessages([message('new', 950)], 500);

    expect(data.messages.map((item) => item.id), ['old', 'new']);
  });

  test('older messages are added once', () {
    var data = const AppData().withAllRows(DbTable.messages, [message('a', 500)]);
    data = data.withOlderMessages([message('a', 500), message('b', 100)]);

    expect(data.messages.map((item) => item.id), ['b', 'a']);
  });

  test('chat older than 15 days is removed unless the customer has an unused code', () {
    const day = Duration.millisecondsPerDay;
    final now = 100 * day;
    var data = const AppData().withAllRows(DbTable.messages, [
      message('old', now - 16 * day),
      message('kept', now - 16 * day, customerId: 'c2'),
      message('recent', now - day),
    ]);
    data = data.withAllRows(DbTable.orders, [order('PS-1', codeUnused: true, customerId: 'c2')]);

    expect(data.withoutOldMessages(now).messages.map((item) => item.id), ['kept', 'recent']);
  });

  test('a saved copy keeps the data, and only two days of messages', () {
    const day = Duration.millisecondsPerDay;
    final now = 100 * day;
    var data = const AppData().withAllRows(DbTable.orders, [order('PS-1')]);
    data = data.withAllRows(DbTable.messages, [message('old', now - 3 * day), message('new', now - day)]);

    final json = jsonDecode(jsonEncode(copyToJson(data, 123, 456, now))) as DbRow;
    final copy = copyFromJson(json)!;

    expect(copy.data.loaded, isTrue);
    expect(copy.data.orders.single.id, 'PS-1');
    expect(copy.data.messages.map((item) => item.id), ['new']);
    expect(copy.changesSince, 123);
    expect(copy.lastFullLoadAt, 456);
  });

  test('a saved copy can be read in the background', () async {
    final data = const AppData().withAllRows(DbTable.orders, [order('PS-1')]);
    final text = jsonEncode(copyToJson(data, 123, 456, 0));

    final copy = await Isolate.run(() => copyFromJson(jsonDecode(text) as DbRow));

    expect(copy!.data.orders.single.id, 'PS-1');
  });

  test('a saved copy from another version is ignored', () {
    expect(copyFromJson({'version': 0}), isNull);
  });
}
