import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/ticket.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../inbox/widgets/reply_dialog.dart';
import 'review_card.dart';

class TicketCard extends ConsumerWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  void _confirmResolve(BuildContext context, WidgetRef ref) {
    showConfirmDialog(
      context,
      description: '${ticket.id} will be closed and the customer will be told it is resolved.',
      confirmLabel: 'Yes, resolve',
      onConfirm: () => ref.read(adminActionsProvider).resolveTicket(ticket),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;
    final payment = ticket.kind == 'payment';
    final screenshot = ticket.screenshot;
    final orderId = ticket.orderId;

    final resolveButton = ReviewButton(
      label: 'Resolved',
      fill: tones.strongButton,
      text: Colors.white,
      onTap: () => _confirmResolve(context, ref),
    );

    return ReviewCard(
      heading: payment ? 'Payment issue' : 'App issue',
      title: ticket.id,
      chip: payment ? 'Payment issue' : 'App issues',
      chipFill: tones.amberFill,
      chipText: tones.amberText,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(ticket.message, style: TextStyle(color: colors.onSurface, fontSize: 13, height: 1.5))),
            if (screenshot != null) ...[const SizedBox(width: 12), ReviewThumb(path: screenshot)],
          ],
        ),
        if (orderId != null) ReviewRow(label: 'Order', value: orderId),
        ReviewRow(label: 'Submitted', value: formatDateTime(ticket.createdAt)),
        if (ticket.status == 'open' && payment) resolveButton,
        if (ticket.status == 'open' && !payment)
          Row(
            children: [
              Expanded(
                child: ReviewButton(
                  label: 'Reply',
                  fill: tones.softFill,
                  text: tones.softText,
                  onTap: () => showReplyDialog(context, ticket.customerId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: resolveButton),
            ],
          ),
      ],
    );
  }
}
