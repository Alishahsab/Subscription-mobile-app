import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/whatsapp.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/customer_avatar.dart';
import '../widgets/block_customer_button.dart';
import '../widgets/order_review_card.dart';
import '../widgets/ticket_card.dart';

const _whatsappGreen = Color(0xFF25D366);

class CustomerDetailsScreen extends ConsumerWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final customer = data.customer(customerId);
    final tones = context.tones;

    if (customer == null) return const Scaffold(body: SizedBox());

    List<Order> sorted(bool Function(Order) test) {
      return data.ordersOf(customerId).where(test).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final completed = sorted((order) => order.status == 'completed');
    final pending = sorted(isPending);
    final tickets = data.tickets.where((item) => item.customerId == customerId).toList();
    final open = tickets.where((item) => item.status == 'open');
    final resolved = tickets.where((item) => item.status == 'resolved').length;

    final safeArea = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, safeArea.top + 64, 20, 20 + safeArea.bottom),
            children: [
              _DetailsHeader(customer: customer),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Stat(label: 'Completed orders', value: completed.length)),
                  const SizedBox(width: 8),
                  Expanded(child: _Stat(label: 'Issues resolved', value: resolved)),
                ],
              ),
              for (final order in [...pending, ...completed]) ...[
                const SizedBox(height: 16),
                OrderReviewCard(key: ValueKey(order.id + order.status), order: order, customerName: customerTitle(customer)),
              ],
              for (final ticket in open) ...[
                const SizedBox(height: 16),
                TicketCard(key: ValueKey(ticket.id), ticket: ticket),
              ],
              if (customer.blocked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: tones.redFill, borderRadius: BorderRadius.circular(12)),
                  child: Text.rich(
                    TextSpan(
                      text: 'Blocked: ',
                      style: TextStyle(color: tones.redText, fontSize: 12.5, fontWeight: FontWeight.w600),
                      children: [
                        TextSpan(text: customer.blockReason ?? 'No reason given', style: const TextStyle(fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              BlockCustomerButton(customer: customer),
            ],
          ),
          Positioned(top: safeArea.top + 10, right: 14, child: _CloseButton(onTap: () => context.pop())),
        ],
      ),
    );
  }
}

class _WhatsAppMark extends StatelessWidget {
  const _WhatsAppMark();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.mode_comment, color: _whatsappGreen, size: 18),
        Icon(Icons.call, color: Colors.white, size: 10),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.close_rounded, color: colors.onSurface, size: 26),
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final whatsapp = customer.whatsapp;

    return Row(
      children: [
        CustomerAvatar(customerId: customer.id, size: 72),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(5)),
                child: Text(customerTag(customer), style: TextStyle(color: tones.softText, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              if (whatsapp != null && whatsapp.isNotEmpty)
                GestureDetector(
                  onTap: () => openWhatsApp(whatsapp),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      spacing: 6,
                      children: [
                        const _WhatsAppMark(),
                        Text(whatsapp, style: TextStyle(color: tones.greenText, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              Text(customer.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface, fontSize: 13)),
              Text('Customer since ${formatDate(customer.createdAt)}', style: TextStyle(color: tones.faint, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: context.tones.fieldFill, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TextStyle(color: colors.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5)),
        ],
      ),
    );
  }
}
