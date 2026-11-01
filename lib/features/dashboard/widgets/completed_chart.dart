import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/order.dart';

const _days = 7;
const _minTop = 4;

class ChartDay {
  const ChartDay(this.label, this.count);

  final String label;
  final int count;
}

List<ChartDay> completedByDay(List<Order> orders, int now) {
  final today = DateTime.fromMillisecondsSinceEpoch(now);
  final midnight = DateTime(today.year, today.month, today.day);

  return List.generate(_days, (index) {
    final start = DateTime(midnight.year, midnight.month, midnight.day - (_days - 1 - index));
    final end = DateTime(start.year, start.month, start.day + 1);
    final count = orders.where((order) {
      final reviewedAt = order.reviewedAt ?? 0;
      return order.status == 'completed' && reviewedAt >= start.millisecondsSinceEpoch && reviewedAt < end.millisecondsSinceEpoch;
    }).length;
    return ChartDay(index == _days - 1 ? 'Today' : shortWeekday(start), count);
  });
}

class CompletedChart extends StatefulWidget {
  const CompletedChart({super.key, required this.days});

  final List<ChartDay> days;

  @override
  State<CompletedChart> createState() => _CompletedChartState();
}

class _CompletedChartState extends State<CompletedChart> {
  int _picked = _days - 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final days = widget.days;
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
                    Text('Completed orders', style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Last 7 days · $total orders', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tones.greenFill, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: tones.greenText),
                    const SizedBox(width: 4),
                    Text('${days.last.count} today', style: TextStyle(color: tones.greenText, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
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
        ],
      ),
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
                            child: Text('${day.count}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
