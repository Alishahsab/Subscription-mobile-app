import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/models/order.dart';
import 'package:premium_store_admin/features/dashboard/widgets/completed_chart.dart';

final now = DateTime(2026, 11, 4, 15).millisecondsSinceEpoch;

Order completed(int daysAgo) {
  return Order.fromRow({
    'id': 'PS-$daysAgo',
    'customer_id': 'c1',
    'plan_id': 'p',
    'plan_name': '1 Month',
    'amount': 299,
    'method_name': 'JazzCash',
    'status': 'completed',
    'created_at': 1,
    'expires_at': 2,
    'reviewed_at': now - daysAgo * Duration.millisecondsPerDay,
    'code_unused': false,
  });
}

void main() {
  final orders = [completed(0), completed(3), completed(8), completed(20)];

  test('this week ends today', () {
    final days = completedByDay(orders, now);
    expect(days.last.label, 'Today');
    expect(days.last.count, 1);
    expect(weekLabel(days, 0), 'Last 7 days');
  });

  test('a week back shows the seven days before, with dates', () {
    final days = completedByDay(orders, now, weeksBack: 1);
    expect(days.fold(0, (sum, day) => sum + day.count), 1);
    expect(days.last.label, isNot('Today'));
    expect(weekLabel(days, 1), contains('Oct'));
  });

  test('the arrows stop at the first completed order', () {
    expect(oldestWeekBack(orders, now), 2);
    expect(oldestWeekBack(const [], now), 0);
  });
}
