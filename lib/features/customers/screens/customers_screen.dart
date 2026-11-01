import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/category_chips.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/customer.dart';
import '../../../data/sync/app_data.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/customer_avatar.dart';
import '../widgets/customer_row.dart';

const _pageSize = 30;

bool matchesCustomer(Customer customer, String words) {
  return customer.email.toLowerCase().contains(words) ||
      (customer.whatsapp?.contains(words) ?? false) ||
      customerTag(customer).toLowerCase().contains(words);
}

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _filter = 'all';
  String _query = '';
  int _shownCount = _pageSize;

  bool _onScroll(ScrollNotification notification, int total) {
    if (notification.metrics.extentAfter < 400 && _shownCount < total) {
      setState(() => _shownCount += _pageSize);
    }
    return false;
  }

  List<Customer> _sorted(AppData data) {
    final activity = {for (final customer in data.customers) customer.id: lastActivityAt(data, customer.id)};
    return [...data.customers]..sort((a, b) => activity[b.id]!.compareTo(activity[a.id]!));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final now = watchNow(ref);
    final colors = Theme.of(context).colorScheme;

    final customers = _sorted(data);
    final active = customers.where((customer) => isCustomerActive(data, customer.id, now)).toList();
    final blocked = customers.where((customer) => customer.blocked).toList();
    final lists = {'all': customers, 'active': active, 'blocked': blocked};

    final words = _query.trim().toLowerCase();
    final rows = lists[_filter]!.where((customer) => words.isEmpty || matchesCustomer(customer, words)).toList();
    final shown = rows.take(_shownCount).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Customers',
              placeholder: 'WhatsApp, email or ID',
              onBack: () => context.pop(),
              onSearch: (query) => setState(() {
                _query = query;
                _shownCount = _pageSize;
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                '${customers.length} customers · each one sees only their own chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
            CategoryChips(
              selected: _filter,
              onSelect: (filter) => setState(() {
                _filter = filter;
                _shownCount = _pageSize;
              }),
              chips: [
                CategoryChip(key: 'all', label: 'All', count: customers.length),
                CategoryChip(key: 'active', label: 'Active now', count: active.length, dot: StatusColors.activeChat),
                CategoryChip(key: 'blocked', label: 'Blocked', count: blocked.length, dot: StatusColors.blocked),
              ],
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => _onScroll(notification, rows.length),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (rows.isEmpty)
                      EmptyState(
                        icon: Icons.group_outlined,
                        title: 'No customers found',
                        description: words.isEmpty ? null : 'No match for your search.',
                      )
                    else
                      GroupedListCard(children: [for (final customer in shown) CustomerRow(key: ValueKey(customer.id), customer: customer, now: now)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
