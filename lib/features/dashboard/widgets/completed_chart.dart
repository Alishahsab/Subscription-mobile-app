import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/order.dart';

const _days = 7;
const _minTop = 4;
const _swipeSpeed = 200.0;
const _barsHeight = 210.0;

class ChartDay {
  const ChartDay(this.label, this.start, this.plans);

  final String label;
  final int start;
  final Map<String, int> plans;

  int get count => plans.values.fold(0, (sum, value) => sum + value);

  int countFor(String? plan) => plan == null ? count : plans[plan] ?? 0;
}

DateTime _midnight(int time) {
  final date = DateTime.fromMillisecondsSinceEpoch(time);
  return DateTime(date.year, date.month, date.day);
}

Iterable<Order> _completed(List<Order> orders) {
  return orders.where((order) => order.status == 'completed' && order.reviewedAt != null);
}

int _months(String plan) => int.tryParse(RegExp(r'\d+').firstMatch(plan)?.group(0) ?? '') ?? 999;

String shortPlan(String plan) {
  final months = _months(plan);
  return months == 999 ? plan : '${months}M';
}

List<String> plansIn(List<ChartDay> days) {
  final plans = {for (final day in days) ...day.plans.keys}.toList();
  return plans..sort((a, b) => _months(a).compareTo(_months(b)));
}

List<ChartDay> completedByDay(List<Order> orders, int now, {int weeksBack = 0}) {
  final today = _midnight(now);
  final completed = _completed(orders).toList();

  return List.generate(_days, (index) {
    final start = DateTime(today.year, today.month, today.day - weeksBack * _days - (_days - 1 - index));
    final end = DateTime(start.year, start.month, start.day + 1);
    final plans = <String, int>{};
    for (final order in completed) {
      if (order.reviewedAt! >= start.millisecondsSinceEpoch && order.reviewedAt! < end.millisecondsSinceEpoch) {
        plans.update(order.planName, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final label = weeksBack == 0 && index == _days - 1 ? 'Today' : shortWeekday(start);
    return ChartDay(label, start.millisecondsSinceEpoch, plans);
  });
}

int oldestWeekBack(List<Order> orders, int now) {
  final times = _completed(orders).map((order) => order.reviewedAt!);
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
  String? _plan;

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
    final plans = plansIn(days);
    final plan = plans.contains(_plan) ? _plan : null;
    final planColors = {for (var index = 0; index < plans.length; index++) plans[index]: tones.chartPlans[index % tones.chartPlans.length]};
    final total = days.fold(0, (sum, day) => sum + day.countFor(plan));
    final top = days.fold(_minTop, (highest, day) => max(highest, day.countFor(plan)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        '${days.last.countFor(plan)} today',
                        style: TextStyle(color: tones.greenText, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PlanChip(label: 'All ${days.fold(0, (sum, day) => sum + day.count)}', selected: plan == null, onTap: () => setState(() => _plan = null)),
                for (final name in plans)
                  _PlanChip(
                    label: '${shortPlan(name)} ${days.fold(0, (sum, day) => sum + day.countFor(name))}',
                    color: planColors[name],
                    selected: plan == name,
                    onTap: () => setState(() => _plan = plan == name ? null : name),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 30),
          SizedBox(
            height: _barsHeight,
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
                      child: _Bar(
                        day: days[index],
                        plans: plan == null ? plans : [plan],
                        planColors: planColors,
                        top: top,
                        picked: index == _picked,
                        onTap: () => setState(() => _picked = index),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DaySummary(day: days[_picked], plans: plans, planColors: planColors),
          ],
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

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.label, required this.selected, required this.onTap, this.color});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? tones.chartTrack : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.onSurfaceVariant : tones.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(color: selected ? colors.onSurface : colors.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.plans, required this.planColors, required this.top, required this.picked, required this.onTap});

  final ChartDay day;
  final List<String> plans;
  final Map<String, Color> planColors;
  final int top;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;
    final shown = plans.where((plan) => day.countFor(plan) > 0).toList().reversed.toList();
    final count = shown.fold(0, (sum, plan) => sum + day.countFor(plan));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: tones.chartTrack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: picked ? tones.chartPicked : Colors.transparent, width: 1.5),
              ),
              child: FractionallySizedBox(
                heightFactor: max(0.03, count / top),
                widthFactor: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: count == 0
                            ? ColoredBox(color: tones.chartBar)
                            : Column(
                                children: [
                                  for (var index = 0; index < shown.length; index++)
                                    Expanded(
                                      flex: day.countFor(shown[index]),
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: index < shown.length - 1 ? 2 : 0),
                                        color: planColors[shown[index]],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    if (picked)
                      Positioned(
                        top: -30,
                        left: -12,
                        right: -12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '$count',
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

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, required this.plans, required this.planColors});

  final ChartDay day;
  final List<String> plans;
  final Map<String, Color> planColors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tones.chartTrack, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.label} · ${day.count} completed',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final plan in plans)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.countFor(plan)}',
                        style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.w700, height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: planColors[plan], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 4),
                          Text(shortPlan(plan), style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
