import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/swipe_area.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/controllers/inbox_navigation.dart';
import '../../inbox/widgets/customer_avatar.dart';
import '../../inbox/widgets/inbox_card.dart';
import '../../search/screens/search_screen.dart';
import '../widgets/completed_chart.dart';
import '../widgets/customer_list_card.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/pending_hero.dart';
import '../widgets/stat_card.dart';

const _tabBarSpace = 96.0;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final now = watchNow(ref);
    final counts = countInboxTabs(data);
    final pending = counts['pending'] ?? 0;

    void openInbox(String tab) {
      ref.read(inboxTabProvider.notifier).state = tab;
      context.go(AppRoutes.inbox);
    }

    void openBot(String filter) {
      ref.read(botFilterProvider.notifier).state = filter;
      context.go(AppRoutes.bot);
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          DashboardTopBar(searching: _searching, onToggleSearch: () => setState(() => _searching = !_searching), onSearch: (query) => setState(() => _query = query)),
          Expanded(
            child: _searching
                ? SearchResultsView(query: _query)
                : SwipeArea(
                    onNext: () => context.go(AppRoutes.inbox),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, _tabBarSpace),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight - _tabBarSpace - 4),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PendingHero(pending: pending, onTap: () => openInbox('pending')),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(label: 'Pending orders', value: pending, dot: inboxColors['pending']!, onTap: () => openInbox('pending')),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: StatCard(label: 'App issues', value: counts['issues'] ?? 0, dot: inboxColors['issues']!, onTap: () => openInbox('issues')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(
                                          label: 'Active chats',
                                          value: chatItems(data, active: true, now: now).length,
                                          dot: StatusColors.activeChat,
                                          onTap: () => openBot(BotFilter.activeChats),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: StatCard(label: 'Active orders', value: activeOrderItems(data, now).length, dot: StatusColors.activeOrder, onTap: () => openBot(BotFilter.activeOrders)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(child: CompletedChart(orders: data.orders, now: now)),
                                  const SizedBox(height: 12),
                                  CustomerListCard(count: data.customers.length, onTap: () => context.push(AppRoutes.customers)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
