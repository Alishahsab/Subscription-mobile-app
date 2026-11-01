import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/widgets/expanding_search.dart';
import '../../../core/widgets/signal_button.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';

const _signalSpace = 52.0;

const _statuses = {
  'active': ('Active', Color(0xFF10B981)),
  'away': ('Away', Color(0xFFFBBF24)),
  'away_closed': ('Away · Closed', Color(0xFFF97316)),
  'offline': ('Offline', Color(0xFFA1A1AA)),
};

class DashboardTopBar extends ConsumerWidget {
  const DashboardTopBar({super.key, required this.searching, required this.onToggleSearch, required this.onSearch});

  final bool searching;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dataProvider).config;
    final status = _statuses[config?.effectiveStatus(watchNow(ref))] ?? _statuses['active']!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                Positioned.fill(
                  right: _signalSpace * 2,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: searching ? 0 : 1,
                    child: _StatusPill(label: status.$1, dot: status.$2),
                  ),
                ),
                const SignalButton(),
                Positioned(
                  right: _signalSpace,
                  child: ExpandingSearch(
                    open: searching,
                    width: constraints.maxWidth - _signalSpace,
                    placeholder: 'Search customers, codes…',
                    onToggle: onToggleSearch,
                    onChanged: onSearch,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.dot});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(child: Image.asset(AppInfo.logoBadge, width: 40, height: 40)),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppInfo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
