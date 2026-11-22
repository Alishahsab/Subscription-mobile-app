import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/models/order.dart';
import 'package:premium_store_admin/features/dashboard/widgets/chart_periods.dart';

final now = DateTime(2026, 11, 4, 15).millisecondsSinceEpoch;

Order completed(Duration ago, [String plan = '1 Month']) {
  return Order.fromRow({
    'id': 'PS-${ago.inMinutes}-$plan',
    'customer_id': 'c1',
    'plan_id': 'p',
    'plan_name': plan,
    'amount': 299,
    'method_name': 'JazzCash',
    'status': 'completed',
    'created_at': 1,
    'expires_at': 2,
    'reviewed_at': now - ago.inMilliseconds,
    'code_unused': false,
  });
}

void main() {
  final orders = [completed(Duration.zero), completed(const Duration(days: 3)), completed(const Duration(days: 8)), completed(const Duration(days: 40), '3 Months')];

  test('daily shows the last seven days ending today', () {
    final period = chartPeriod(orders, now, ChartView.daily);
    expect(period.buckets, hasLength(7));
    expect(period.buckets.last.label, 'Today');
    expect(period.buckets.last.count, 1);
    expect(period.range, '29 Oct – 4 Nov');
    expect(chartPeriod(orders, now, ChartView.daily, pagesBack: 1).buckets.fold(0, (sum, bucket) => sum + bucket.count), 1);
  });

  test('hourly splits one day into 24 hours', () {
    final period = chartPeriod([completed(Duration.zero), completed(const Duration(minutes: 30))], now, ChartView.hourly);
    expect(period.buckets, hasLength(24));
    expect(period.buckets[14].count, 1);
    expect(period.buckets[15].count, 1);
  });

  test('monthly shows six months and custom ranges count every plan', () {
    expect(chartPeriod(orders, now, ChartView.monthly).buckets.fold(0, (sum, bucket) => sum + bucket.count), 4);
    final custom = chartPeriod(orders, now, ChartView.custom, custom: DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 11, 4)));
    expect(custom.buckets, hasLength(3));
    expect(plansIn(custom.buckets).map(shortPlan), ['1M', '3M']);
  });

  test('first completed order stops the arrows', () {
    expect(firstCompletedAt(orders), now - const Duration(days: 40).inMilliseconds);
    expect(firstCompletedAt(const []), isNull);
  });
}
