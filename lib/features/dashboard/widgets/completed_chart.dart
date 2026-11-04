import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/order.dart';

const _days = 7;
const _minTop = 4;
const _swipeSpeed = 200.0;

class ChartDay {
  const ChartDay(this.label, this.count, this.start);

  final String label;
  final int count;
  final int start;
}

DateTime _midnight(int time) {
  final date = DateTime.fromMillisecondsSinceEpoch(time);
  return DateTime(date.year, date.month, date.day);
}

Iterable<int> _completedTimes(List<Order> orders) {
  return orders.where((order) => order.status == 'completed' && order.reviewedAt != null).map((order) => order.reviewedAt!);
}

List<ChartDay> completedByDay(List<Order> orders, int now, {int weeksBack = 0}) {
  final today = _midnight(now);
  final times = _completedTimes(orders).toList();

  return List.generate(_days, (index) {
    final start = DateTime(today.year, today.month, today.day - weeksBack * _days - (_days - 1 - index));
    final end = DateTime(start.year, start.month, start.day + 1);
    final count = times.where((time) => time >= start.millisecondsSinceEpoch && time < end.millisecondsSinceEpoch).length;
    final label = weeksBack == 0 && index == _days - 1 ? 'Today' : shortWeekday(start);
    return ChartDay(label, count, start.millisecondsSinceEpoch);
  });
}

int oldestWeekBack(List<Order> orders, int now) {
  final times = _completedTimes(orders);
  if (times.isEmpty) return 0;
  final first = _midnight(times.reduce(min));
  return max(0, _midnight(now).difference(first).inDays ~/ _days);
}

String weekLabel(List<ChartDay> days, int weeksBack) {
  if (weeksBack == 0) return 'Last 7 days';
  return '${shortDate(days.first.start)} – ${shortDate(days.last.start)}';
}

class CompletedChart extends StatefulWidget {
  const CompletedChart({super.key, required this.orders, required this.now});

  final List<Order> orders;
  final int now;

  @override
  State<CompletedChart> createState() => _CompletedChartState();
}

class _CompletedChartState extends State<CompletedChart> {
  int _picked = _days - 1;
  int _weeksBack = 0;

  void _showWeek(int weeksBack) {
    setState(() {
      _weeksBack = weeksBack;
      _picked = _days - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final oldest = oldestWeekBack(widget.orders, widget.now);
    final days = completedByDay(widget.orders, widget.now, weeksBack: _weeksBack);
    final total = days.fold(0, (sum, day) => sum + day.count);
    final top = days.fold(_minTop, (highest, day) => max(highest, day.count));

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(26)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed orders',
                      style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${weekLabel(days, _weeksBack)} · $total orders',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _WeekArrow(icon: Icons.chevron_left_rounded, label: 'Previous week', onTap: _weeksBack < oldest ? () => _showWeek(_weeksBack + 1) : null),
              _WeekArrow(icon: Icons.chevron_right_rounded, label: 'Next week', onTap: _weeksBack > 0 ? () => _showWeek(_weeksBack - 1) : null),
              if (_weeksBack == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: tones.greenFill, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: tones.greenText),
                      const SizedBox(width: 4),
                      Text(
                        '${days.last.count} today',
                        style: TextStyle(color: tones.greenText, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed < -_swipeSpeed && _weeksBack > 0) _showWeek(_weeksBack - 1);
                if (speed > _swipeSpeed && _weeksBack < oldest) _showWeek(_weeksBack + 1);
              },
              child: Row(
                children: [
                  for (var index = 0; index < days.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Bar(day: days[index], top: top, picked: index == _picked, onTap: () => setState(() => _picked = index)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(icon, size: 22),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.top, required this.picked, required this.onTap});

  final ChartDay day;
  final int top;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(color: tones.chartTrack, borderRadius: BorderRadius.circular(999)),
              child: FractionallySizedBox(
                heightFactor: max(0.06, day.count / top),
                widthFactor: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(color: picked ? tones.chartPicked : tones.chartBar, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    if (picked)
                      Positioned(
                        top: -28,
                        left: -12,
                        right: -12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '${day.count}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day.label,
            style: TextStyle(color: picked ? colors.onSurface : tones.faint, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
