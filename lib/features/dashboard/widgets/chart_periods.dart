import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../data/models/order.dart';

enum ChartView { daily, hourly, monthly, custom }

const chartViews = {
  ChartView.daily: ('Daily', 'Last 7 days'),
  ChartView.hourly: ('Hourly', 'Orders per hour, one day'),
  ChartView.monthly: ('Monthly', 'Last 6 months'),
  ChartView.custom: ('Custom range', 'Pick start and end dates'),
};

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _longCustomDays = 31;

class ChartBucket {
  const ChartBucket(this.label, this.title, this.start, this.end, this.plans);

  final String label;
  final String title;
  final int start;
  final int end;
  final Map<String, int> plans;

  int get count => plans.values.fold(0, (sum, value) => sum + value);

  int countFor(String? plan) => plan == null ? count : plans[plan] ?? 0;
}

class ChartPeriod {
  const ChartPeriod(this.range, this.buckets);

  final String range;
  final List<ChartBucket> buckets;
}

typedef _Slot = (String label, String title, DateTime start, DateTime end);

DateTime _midnight(DateTime date) => DateTime(date.year, date.month, date.day);

String _hourName(int hour) => '${hour % 12 == 0 ? 12 : hour % 12} ${hour < 12 ? 'AM' : 'PM'}';

String _dayTitle(DateTime day) => '${shortWeekday(day)}, ${shortDate(day.millisecondsSinceEpoch)}';

Iterable<Order> _completed(List<Order> orders) => orders.where((order) => order.status == 'completed' && order.reviewedAt != null);

int _months(String plan) {
  final match = RegExp(r'(\d+)\s*(year|yr)?', caseSensitive: false).firstMatch(plan);
  if (match == null) return 999;
  final count = int.parse(match.group(1)!);
  return match.group(2) == null ? count : count * 12;
}

String shortPlan(String plan) {
  final months = _months(plan);
  return months == 999 ? plan : '${months}M';
}

List<String> plansIn(List<ChartBucket> buckets) {
  final plans = {for (final bucket in buckets) ...bucket.plans.keys}.toList();
  return plans..sort((a, b) => _months(a).compareTo(_months(b)));
}

ChartBucket _bucket(List<Order> completed, _Slot slot) {
  final (label, title, start, end) = slot;
  final from = start.millisecondsSinceEpoch;
  final to = end.millisecondsSinceEpoch;
  final plans = <String, int>{};
  for (final order in completed) {
    if (order.reviewedAt! >= from && order.reviewedAt! < to) plans.update(order.planName, (count) => count + 1, ifAbsent: () => 1);
  }
  return ChartBucket(label, title, from, to, plans);
}

List<ChartBucket> _fill(List<Order> orders, List<_Slot> slots) {
  final completed = _completed(orders).toList();
  return [for (final slot in slots) _bucket(completed, slot)];
}

List<_Slot> _days(DateTime first, int count, {DateTime? today}) {
  return List.generate(count, (index) {
    final day = DateTime(first.year, first.month, first.day + index);
    final label = today != null && day == today ? 'Today' : (count > 7 ? '${day.day}' : shortWeekday(day));
    return (label, _dayTitle(day), day, DateTime(day.year, day.month, day.day + 1));
  });
}

List<_Slot> _monthSlots(DateTime first, int count) {
  return List.generate(count, (index) {
    final month = DateTime(first.year, first.month + index);
    return (_monthNames[month.month - 1], '${_monthNames[month.month - 1]} ${month.year}', month, DateTime(month.year, month.month + 1));
  });
}

ChartPeriod chartPeriod(List<Order> orders, int now, ChartView view, {int pagesBack = 0, DateTimeRange? custom}) {
  final today = _midnight(DateTime.fromMillisecondsSinceEpoch(now));

  switch (view) {
    case ChartView.hourly:
      final day = DateTime(today.year, today.month, today.day - pagesBack);
      final slots = List.generate(24, (hour) {
        final start = DateTime(day.year, day.month, day.day, hour);
        return (hour % 6 == 0 ? _hourName(hour).replaceAll(' ', '').toLowerCase() : '', '${_hourName(hour)} – ${_hourName((hour + 1) % 24)}', start, start.add(const Duration(hours: 1)));
      });
      return ChartPeriod(pagesBack == 0 ? 'Today' : _dayTitle(day), _fill(orders, slots));
    case ChartView.monthly:
      final first = DateTime(today.year, today.month - 5 - pagesBack * 6);
      final slots = _monthSlots(first, 6);
      return ChartPeriod('${slots.first.$2} – ${slots.last.$2}', _fill(orders, slots));
    case ChartView.custom:
      final range = custom ?? DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      final start = _midnight(range.start);
      final days = _midnight(range.end).difference(start).inDays + 1;
      final slots = days > _longCustomDays
          ? _monthSlots(DateTime(start.year, start.month), (range.end.year - start.year) * 12 + range.end.month - start.month + 1)
          : _days(start, days, today: today);
      return ChartPeriod('${shortDate(start.millisecondsSinceEpoch)} – ${shortDate(range.end.millisecondsSinceEpoch)}', _fill(orders, slots));
    case ChartView.daily:
      final first = DateTime(today.year, today.month, today.day - 6 - pagesBack * 7);
      final slots = _days(first, 7, today: today);
      return ChartPeriod('${shortDate(first.millisecondsSinceEpoch)} – ${shortDate(slots.last.$3.millisecondsSinceEpoch)}', _fill(orders, slots));
  }
}

int? firstCompletedAt(List<Order> orders) {
  final times = _completed(orders).map((order) => order.reviewedAt!);
  return times.isEmpty ? null : times.reduce(min);
}
