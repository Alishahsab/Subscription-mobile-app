import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list_card.dart';
import '../../../data/models/order.dart';
import '../../../data/sync/app_data.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/controllers/inbox_navigation.dart';
import '../controllers/search_results.dart';
import '../widgets/highlighted_text.dart';

const _senderLabels = {'customer': 'Customer', 'admin': 'You', 'bot': 'Auto-reply'};

class SearchResultsView extends ConsumerStatefulWidget {
  const SearchResultsView({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<SearchResultsView> {
  String _emailOf(AppData data, String customerId) => data.customer(customerId)?.email ?? 'Customer';

  void _openOrder(Order order) {
    ref.read(inboxTabProvider.notifier).state = order.status == 'pending_review' ? 'pending' : 'completed';
    context.push(AppRoutes.chat(order.customerId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final data = ref.watch(dataProvider);
    final text = widget.query.trim();
    final results = searchEverything(data, text);
    final summary = text.isEmpty ? 'Type to search' : '${results.total} result${results.total == 1 ? '' : 's'} for "$text"';

    final small = TextStyle(color: colors.onSurfaceVariant, fontSize: 12);
    final body = TextStyle(color: colors.onSurface, fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5),
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            children: [
              if (text.isNotEmpty && results.total == 0)
                const EmptyState(icon: Icons.search_rounded, title: 'No matches', description: 'Try a code, name, email, order number or any word from a chat.'),
              if (results.messages.isNotEmpty)
                _ResultGroup(
                  title: 'Messages',
                  icon: Icons.chat_bubble_outline_rounded,
                  count: results.messages.length,
                  rows: [
                    for (final message in results.messages.take(shownMessages))
                      _ResultRow(
                        onTap: () => context.push(AppRoutes.chat(message.customerId)),
                        title: Text(
                          '${_emailOf(data, message.customerId)} · ${_senderLabels[message.sender]} · ${formatDateTime(message.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                        detail: HighlightedText(text: message.text, query: text, style: body),
                      ),
                  ],
                ),
              if (results.customers.isNotEmpty)
                _ResultGroup(
                  title: 'Customers',
                  icon: Icons.person_outline_rounded,
                  count: results.customers.length,
                  rows: [
                    for (final customer in results.customers)
                      _ResultRow(
                        onTap: () => context.push(AppRoutes.chat(customer.id)),
                        title: HighlightedText(
                          text: customerTag(customer),
                          query: text,
                          style: TextStyle(color: tones.title, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        detail: HighlightedText(text: customer.email, query: text, style: body),
                      ),
                  ],
                ),
              if (results.orders.isNotEmpty)
                _ResultGroup(
                  title: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  count: results.orders.length,
                  rows: [
                    for (final order in results.orders)
                      _ResultRow(
                        onTap: () => _openOrder(order),
                        title: HighlightedText(
                          text: order.id,
                          query: text,
                          style: body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        detail: Text('${_emailOf(data, order.customerId)} · ${order.planName} · ${formatMoney(order.amount)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: small),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultGroup extends StatelessWidget {
  const _ResultGroup({required this.title, required this.icon, required this.count, required this.rows});

  final String title;
  final IconData icon;
  final int count;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Icon(icon, size: 15, color: colors.onSurface),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text('$count', style: TextStyle(color: context.tones.faint, fontSize: 13)),
              ],
            ),
          ),
          GroupedListCard(children: rows),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.onTap, required this.title, required this.detail});

  final VoidCallback onTap;
  final Widget title;
  final Widget detail;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [title, detail]),
        ),
      ),
    );
  }
}
