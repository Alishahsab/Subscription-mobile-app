import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/category_chips.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/slide_switcher.dart';
import '../../../core/widgets/swipe_area.dart';
import '../../../data/models/default_settings.dart';
import '../../../data/sync/app_data.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/controllers/inbox_navigation.dart';
import '../../inbox/models/inbox_item.dart';
import '../../inbox/widgets/customer_avatar.dart';
import '../widgets/bot_row.dart';

const _pageSize = 30;

const _filters = [
  (BotFilter.activeChats, 'Active chats', StatusColors.activeChat),
  (BotFilter.activeOrders, 'Active orders', StatusColors.activeOrder),
  (BotFilter.cancelled, 'Cancelled', StatusColors.cancelled),
  (BotFilter.inactiveChats, 'Inactive', StatusColors.inactiveChat),
];

const _emptyText = {
  BotFilter.activeOrders: 'Orders waiting for the customer to pay show up here.',
  BotFilter.cancelled: 'Cancelled and expired orders show up here.',
  BotFilter.activeChats: 'Customers active right now show up here.',
  BotFilter.inactiveChats: 'Customers who have gone quiet show up here.',
};

class BotChatScreen extends ConsumerStatefulWidget {
  const BotChatScreen({super.key});

  @override
  ConsumerState<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  String _query = '';
  int _shownCount = _pageSize;

  void _selectFilter(String filter) {
    ref.read(botFilterProvider.notifier).state = filter;
    setState(() => _shownCount = _pageSize);
  }

  void _step(String current, int by) {
    final keys = _filters.map((filter) => filter.$1).toList();
    final index = keys.indexOf(current) + by;

    if (index >= keys.length) {
      context.go(AppRoutes.settings);
    } else if (index >= 0) {
      _selectFilter(keys[index]);
    } else {
      final tabs = ref.read(dataProvider).config?.inboxTabs ?? defaultInboxTabs;
      ref.read(inboxTabProvider.notifier).state = tabs.first['key'];
      context.go(AppRoutes.inbox);
    }
  }

  bool _onScroll(ScrollNotification notification, int total) {
    if (notification.metrics.extentAfter < 400 && _shownCount < total) {
      setState(() => _shownCount += _pageSize);
    }
    return false;
  }

  Widget _row(AppData data, InboxItem item, String filter, int now) {
    final orderList = filter == BotFilter.activeOrders || filter == BotFilter.cancelled;
    return BotRow(
      key: ValueKey(item.key),
      item: item,
      filter: filter,
      order: orderList ? data.orders.where((entry) => entry.id == item.key).firstOrNull : null,
      unreadCount: orderList ? 0 : (data.conversations[item.customerId]?.unreadByAdmin ?? 0),
      now: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final now = watchNow(ref);
    final filter = ref.watch(botFilterProvider);

    final words = _query.trim().toLowerCase();
    final all = botItems(data, filter, now);
    final items = words.isEmpty ? all : all.where((item) => matchesSearch(data, item, words)).toList();
    final shown = items.take(_shownCount).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Bot chat',
            onSearch: (query) => setState(() {
              _query = query;
              _shownCount = _pageSize;
            }),
          ),
          const SizedBox(height: 8),
          CategoryChips(
            selected: filter,
            onSelect: _selectFilter,
            chips: [for (final (key, label, dot) in _filters) CategoryChip(key: key, label: label, count: botItems(data, key, now).length, dot: dot)],
          ),
          Expanded(
            child: SwipeArea(
              onNext: () => _step(filter, 1),
              onPrevious: () => _step(filter, -1),
              child: SlideSwitcher(
                index: _filters.indexWhere((item) => item.$1 == filter),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _onScroll(notification, items.length),
                  child: ListView(
                    key: PageStorageKey(filter),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    children: [
                      if (shown.isEmpty)
                        EmptyState(icon: Icons.inbox_rounded, title: 'Nothing here', description: words.isNotEmpty ? 'No match for your search.' : _emptyText[filter])
                      else
                        GroupedListCard(children: [for (final item in shown) _row(data, item, filter, now)]),
                    ],
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
