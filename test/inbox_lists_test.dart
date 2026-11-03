import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/core/utils/format.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/repositories/admin_actions.dart';
import 'package:premium_store_admin/data/sync/app_data.dart';
import 'package:premium_store_admin/data/sync/db_table.dart';
import 'package:premium_store_admin/data/sync/signal_notifier.dart';
import 'package:premium_store_admin/features/inbox/controllers/inbox_lists.dart';

const now = 1800000000000;

DbRow order(String id, String status, {int? submittedAt, String? code, bool unused = false, String customer = 'c1', int? expiresAt}) {
  return {
    'id': id,
    'customer_id': customer,
    'plan_id': 'p',
    'plan_name': '3 Months',
    'amount': 769,
    'method_name': 'Easypaisa',
    'status': status,
    'created_at': now - 1000,
    'expires_at': expiresAt ?? now + 1000,
    'submitted_at': submittedAt,
    'code': code,
    'code_unused': unused,
  };
}

DbRow customer(String id, {bool blocked = false, String? whatsapp, int? number}) {
  return {
    'id': id,
    'email': '$id@test.com',
    'created_at': 1,
    'last_seen_at': 1,
    'blocked': blocked,
    'whatsapp': whatsapp,
    'customer_number': number,
  };
}

DbRow ticket(String id, String status, String kind) {
  return {'id': id, 'customer_id': 'c1', 'kind': kind, 'message': 'help', 'status': status, 'created_at': now};
}

void main() {
  test('tab counts follow the same rules as the web', () {
    var data = const AppData().withAllRows(DbTable.orders, [
      order('A', 'pending_review'),
      order('B', 'rejected'),
      order('C', 'completed', unused: true),
      order('D', 'completed'),
    ]);
    data = data.withAllRows(DbTable.tickets, [ticket('T1', 'open', 'support'), ticket('T2', 'open', 'payment'), ticket('T3', 'resolved', 'support')]);
    data = data.withAllRows(DbTable.customers, [customer('c1', blocked: true), customer('c2')]);

    expect(countInboxTabs(data), {'pending': 2, 'issues': 1, 'completed': 0, 'unused': 1, 'blocked': 1});
  });

  test('pending orders show newest first and only waiting ones are unread', () {
    final data = const AppData().withAllRows(DbTable.orders, [
      order('old', 'pending_review', submittedAt: now - 5000),
      order('new', 'rejected', submittedAt: now - 1000),
    ]);

    final items = pendingItems(data, now);
    expect(items.map((item) => item.key), ['new', 'old']);
    expect(items.first.unread, isFalse);
    expect(items.last.unread, isTrue);
  });

  test('a customer shows by number, or email for older accounts', () {
    expect(customerTitle(const AppData().withRow(DbTable.customers, customer('c1', whatsapp: '03001234567')).customers.first), '03001234567');
    expect(customerTitle(const AppData().withRow(DbTable.customers, customer('c1')).customers.first), 'c1@test.com');
    expect(customerTag(null), 'New');
  });

  test('an order past its time can no longer be paid', () {
    final data = const AppData().withAllRows(DbTable.orders, [order('A', 'awaiting_payment', expiresAt: now + 1), order('B', 'awaiting_payment', expiresAt: now - 1)]);
    expect(activeOrderItems(data, now).map((item) => item.key), ['A']);
  });

  test('a code already sent is found in orders and in admin messages', () {
    var data = const AppData().withAllRows(DbTable.customers, [customer('c1')]);
    data = data.withAllRows(DbTable.orders, [order('A', 'completed', code: 'ABC123')]);
    data = data.withAllRows(DbTable.messages, [
      {'id': 'm', 'customer_id': 'c1', 'sender': 'admin', 'kind': 'text', 'text': 'Your code\n\nXYZ789\nthanks', 'created_at': now},
    ]);

    expect(findCodeAlreadySent(data, 'abc123')?.code, 'ABC123');
    expect(findCodeAlreadySent(data, 'XYZ789')?.customerEmail, 'c1@test.com');
    expect(findCodeAlreadySent(data, 'NEW456'), isNull);
  });

  test('times show in Pakistan time', () {
    final utcEvening = DateTime.utc(2026, 10, 30, 16, 41).millisecondsSinceEpoch;
    expect(formatTime(utcEvening), '9:41 PM');
    expect(formatDate(utcEvening), '30 Oct 2026');
    expect(formatDateTime(utcEvening), '30 Oct 2026, 9:41 PM');
    expect(chatListTime(utcEvening, utcEvening + Duration.millisecondsPerDay), 'Yesterday');
  });

  test('money and age labels read like the web', () {
    expect(formatMoney(769), 'Rs 769');
    expect(formatMoney(1200), 'Rs 1,200');
    expect(timeAgo(now - 10000, now), 'just now');
    expect(timeAgo(now - 5 * Duration.millisecondsPerMinute, now), '5m ago');
    expect(timeAgo(now - 3 * Duration.millisecondsPerHour, now), '3h ago');
  });

  test('a slower reply shows fewer signal bars', () {
    expect(barsFor(100), 5);
    expect(barsFor(300), 4);
    expect(barsFor(700), 3);
    expect(barsFor(1000), 2);
    expect(barsFor(3000), 1);
  });

  test('a chat older than two days stays in the list before its messages are loaded', () {
    const day = Duration.millisecondsPerDay;
    var data = const AppData().withAllRows(DbTable.customers, [customer('c1'), customer('c2')]);
    data = data.withAllRows(DbTable.conversations, [
      {'customer_id': 'c1', 'stage': 'menu', 'unread_by_admin': 0, 'last_message_at': now - 5 * day},
      {'customer_id': 'c2', 'stage': 'menu', 'unread_by_admin': 0, 'last_message_at': now - 20 * day},
    ]);

    final items = chatItems(data, active: false, now: now);

    expect(items.map((item) => item.customerId), ['c1']);
    expect(items.single.subtitle, '');
  });
}
