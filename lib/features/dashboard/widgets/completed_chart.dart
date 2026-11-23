import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/models/order.dart';
import 'chart_periods.dart';

const _minTop = 4;
const _swipeSpeed = 200.0;
const _barsHeight = 210.0;
const _viewLabels = {ChartView.daily: 'Last 7 days', ChartView.hourly: 'Hourly', ChartView.monthly: 'Last 6 months', ChartView.custom: 'Custom range'};

class CompletedChart extends StatefulWidget {
  const CompletedChart({super.key, required this.orders, required this.now});

  final List<Order> orders;
  final int now;

  @override
  State<CompletedChart> createState() => _CompletedChartState();
}

class _CompletedChartState extends State<CompletedChart> {
  ChartView _view = ChartView.daily;
  DateTimeRange? _custom;
  int _pagesBack = 0;
  int? _picked;
  String? _plan;

  bool get _pages => _view != ChartView.custom;

  void _showPage(int pagesBack) {
    setState(() {
      _pagesBack = pagesBack;
      _picked = null;
    });
  }

  Future<void> _pickView() async {
    final view = await showAppSheet<ChartView>(
      context,
      title: 'View by',
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in chartViews.entries)
            SheetOption(title: entry.value.$1, sub: entry.value.$2, selected: entry.key == _view, onTap: () => Navigator.pop(context, entry.key)),
        ],
      ),
    );
    if (view == null || !mounted) return;

    var custom = _custom;
    if (view == ChartView.custom) {
      final today = DateTime.fromMillisecondsSinceEpoch(widget.now);
      final first = firstCompletedAt(widget.orders);
      custom = await showDateRangePicker(
        context: context,
        firstDate: first == null ? today : DateTime.fromMillisecondsSinceEpoch(first),
        lastDate: today,
        initialDateRange: _custom,
      );
      if (custom == null) return;
    }

    setState(() {
      _view = view;
      _custom = custom;
      _pagesBack = 0;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final period = chartPeriod(widget.orders, widget.now, _view, pagesBack: _pagesBack, custom: _custom);
    final buckets = period.buckets;
    final first = firstCompletedAt(widget.orders);
    final canGoBack = _pages && first != null && buckets.first.start > first;
    final canGoForward = _pages && _pagesBack > 0;
    final plans = plansIn(buckets);
    final plan = plans.contains(_plan) ? _plan : null;
    final planColors = {for (var index = 0; index < plans.length; index++) plans[index]: tones.chartPlans[index % tones.chartPlans.length]};
    final total = buckets.fold(0, (sum, bucket) => sum + bucket.count);
    final top = buckets.fold(_minTop, (highest, bucket) => max(highest, bucket.countFor(plan)));
    final picked = min(_picked ?? buckets.length - 1, buckets.length - 1);
    final thin = buckets.length > 12;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Completed orders',
                  style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (_pages) ...[
                _PageArrow(icon: Icons.chevron_left_rounded, label: 'Earlier', onTap: canGoBack ? () => _showPage(_pagesBack + 1) : null),
                const SizedBox(width: 6),
                _PageArrow(icon: Icons.chevron_right_rounded, label: 'Later', onTap: canGoForward ? () => _showPage(_pagesBack - 1) : null),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ViewButton(label: _viewLabels[_view]!, onTap: _pickView),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  period.range,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PlanBox(label: 'All', count: total, selected: plan == null, onTap: () => setState(() => _plan = null))),
                for (final name in plans) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PlanBox(
                      label: shortPlan(name),
                      count: buckets.fold(0, (sum, bucket) => sum + bucket.countFor(name)),
                      color: planColors[name],
                      selected: plan == name,
                      onTap: () => setState(() => _plan = plan == name ? null : name),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 30),
          SizedBox(
            height: _barsHeight,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed < -_swipeSpeed && canGoForward) _showPage(_pagesBack - 1);
                if (speed > _swipeSpeed && canGoBack) _showPage(_pagesBack + 1);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < buckets.length; index++) ...[
                    if (index > 0) SizedBox(width: thin ? 3 : 8),
                    Expanded(
                      child: _Bar(
                        bucket: buckets[index],
                        plans: plan == null ? plans : [plan],
                        planColors: planColors,
                        top: top,
                        thin: thin,
                        picked: index == picked,
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
            _Summary(bucket: buckets[picked], plans: plans, planColors: planColors),
          ],
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return Material(
      color: tones.chartTrack,
      shape: StadiumBorder(side: BorderSide(color: tones.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: context.tones.chartTrack,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: onTap == null ? context.tones.faint : colors.onSurface),
          ),
        ),
      ),
    );
  }
}

class _PlanBox extends StatelessWidget {
  const _PlanBox({required this.label, required this.count, required this.selected, required this.onTap, this.color});

  final String label;
  final int count;
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tones.chartTrack : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tones.chartPicked : tones.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            _PlanLabel(label: label, color: color),
            const SizedBox(height: 2),
            FittedBox(
              child: Text('$count', style: TextStyle(color: colors.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanLabel extends StatelessWidget {
  const _PlanLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final square = color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (square != null) ...[
          Container(width: 7, height: 7, decoration: BoxDecoration(color: square, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bucket, required this.plans, required this.planColors, required this.top, required this.thin, required this.picked, required this.onTap});

  final ChartBucket bucket;
  final List<String> plans;
  final Map<String, Color> planColors;
  final int top;
  final bool thin;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;
    final shown = plans.where((plan) => bucket.countFor(plan) > 0).toList().reversed.toList();
    final count = shown.fold(0, (sum, plan) => sum + bucket.countFor(plan));
    final outer = BorderRadius.circular(thin ? 6 : 14);
    final inner = BorderRadius.circular(thin ? 5 : 12);

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
                borderRadius: outer,
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
                        borderRadius: inner,
                        child: count == 0
                            ? ColoredBox(color: tones.chartBar)
                            : Column(
                                children: [
                                  for (var index = 0; index < shown.length; index++)
                                    Expanded(
                                      flex: bucket.countFor(shown[index]),
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
                        left: -16,
                        right: -16,
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
          SizedBox(
            height: 14,
            child: OverflowBox(
              maxWidth: 40,
              child: Text(
                bucket.label,
                style: TextStyle(color: picked ? colors.onSurface : tones.faint, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.bucket, required this.plans, required this.planColors});

  final ChartBucket bucket;
  final List<String> plans;
  final Map<String, Color> planColors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    Widget column(String label, int count, {Color? color, Color? countColor}) {
      return Expanded(
        child: Column(
          children: [
            _PlanLabel(label: label, color: color),
            const SizedBox(height: 2),
            FittedBox(
              child: Text('$count', style: TextStyle(color: countColor ?? colors.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(color: tones.chartTrack, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bucket.title,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              column('All', bucket.count, countColor: tones.chartPicked),
              for (final plan in plans) column(shortPlan(plan), bucket.countFor(plan), color: planColors[plan]),
            ],
          ),
        ],
      ),
    );
  }
}
