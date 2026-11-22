import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tones.dart';
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
const _sortLabels = {'newest': 'New → Old', 'oldest': 'Old → New', 'active': 'Last active'};

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
  String _sort = 'newest';
  String _query = '';
  int _shownCount = _pageSize;

  bool _onScroll(ScrollNotification notification, int total) {
    if (notification.metrics.extentAfter < 400 && _shownCount < total) {
      setState(() => _shownCount += _pageSize);
    }
    return false;
  }

  List<Customer> _sorted(AppData data) {
    final customers = [...data.customers];
    int joined(Customer customer) => customer.number ?? 1 << 31;

    switch (_sort) {
      case 'oldest':
        return customers..sort((a, b) => joined(a).compareTo(joined(b)));
      case 'active':
        final activity = {for (final customer in customers) customer.id: lastActivityAt(data, customer.id)};
        return customers..sort((a, b) => activity[b.id]!.compareTo(activity[a.id]!));
      default:
        return customers..sort((a, b) => joined(b).compareTo(joined(a)));
    }
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
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${customers.length} customers',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                  PopupMenuButton<String>(
                    initialValue: _sort,
                    onSelected: (sort) => setState(() {
                      _sort = sort;
                      _shownCount = _pageSize;
                    }),
                    offset: const Offset(0, 34),
                    constraints: const BoxConstraints(minWidth: 150, maxWidth: 170),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      for (final entry in _sortLabels.entries)
                        PopupMenuItem(
                          value: entry.key,
                          height: 38,
                          child: Text(
                            entry.value,
                            style: TextStyle(fontSize: 12.5, fontWeight: entry.key == _sort ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ),
                    ],
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: context.tones.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 14, color: colors.onSurface),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabels[_sort]!,
                            style: TextStyle(color: colors.onSurface, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.arrow_drop_down_rounded, size: 18, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
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
