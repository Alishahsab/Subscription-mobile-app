import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/category_chips.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_out_list.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/slide_switcher.dart';
import '../../../core/widgets/swipe_area.dart';
import '../../../data/models/default_settings.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../controllers/inbox_lists.dart';
import '../controllers/inbox_navigation.dart';
import '../models/inbox_item.dart';
import '../widgets/inbox_card.dart';

const _emptyText = {
  'pending': 'No payments are waiting for review.',
  'issues': 'No open app issues.',
  'completed': 'Completed orders will show here.',
  'unused': 'No unused codes right now.',
  'blocked': 'No blocked customers.',
};

const _urgentTabs = ['pending', 'issues'];
const _pageSize = 30;

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _query = '';
  int _shownCount = _pageSize;

  void _selectTab(String tab) {
    ref.read(inboxTabProvider.notifier).state = tab;
    setState(() => _shownCount = _pageSize);
  }

  void _step(List<String> tabs, String current, int by) {
    final index = tabs.indexOf(current) + by;
    if (index < 0) {
      context.go(AppRoutes.dashboard);
    } else if (index >= tabs.length) {
      context.go(AppRoutes.bot);
    } else {
      _selectTab(tabs[index]);
    }
  }

  bool _onScroll(ScrollNotification notification, int total) {
    if (notification.metrics.extentAfter < 400 && _shownCount < total) {
      setState(() => _shownCount += _pageSize);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final now = watchNow(ref);
    final tabs = data.config?.inboxTabs ?? defaultInboxTabs;
    final keys = tabs.map((tab) => tab['key']!).toList();
    final tab = ref.watch(inboxTabProvider) ?? keys.first;

    final counts = countInboxTabs(data);
    final words = _query.trim().toLowerCase();
    final all = inboxItems(data, tab, now);
    final items = words.isEmpty ? all : all.where((item) => matchesSearch(data, item, words)).toList();
    final shown = items.take(_shownCount).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Inbox',
            onSearch: (query) => setState(() {
              _query = query;
              _shownCount = _pageSize;
            }),
          ),
          const SizedBox(height: 8),
          CategoryChips(
            selected: tab,
            onSelect: _selectTab,
            chips: [
              for (final item in tabs)
                CategoryChip(key: item['key']!, label: item['label']!, count: counts[item['key']] ?? 0, dot: inboxColors[item['key']], urgent: _urgentTabs.contains(item['key'])),
            ],
          ),
          Expanded(
            child: SwipeArea(
              onNext: () => _step(keys, tab, 1),
              onPrevious: () => _step(keys, tab, -1),
              child: SlideSwitcher(
                index: keys.indexOf(tab),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _onScroll(notification, items.length),
                  child: FadeOutList<InboxItem>(
                    key: ValueKey(words),
                    storageKey: PageStorageKey(tab),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    items: shown,
                    keyOf: (item) => item.key,
                    itemBuilder: (item) => InboxCard(tab: tab, item: item, now: now),
                    empty: EmptyState(icon: Icons.inbox_rounded, title: 'Nothing here', description: words.isNotEmpty ? 'No match for your search.' : _emptyText[tab]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
