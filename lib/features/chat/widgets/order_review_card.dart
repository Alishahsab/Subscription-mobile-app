import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/approve_dialog.dart';
import '../../inbox/widgets/reject_dialog.dart';
import 'review_card.dart';

const _approveColor = Color(0xFF059669);
const _rejectColor = Color(0xFFB84A45);

const _statusLabels = {
  'awaiting_payment': 'Awaiting payment',
  'pending_review': 'Pending order',
  'completed': 'Completed',
  'rejected': 'Rejected',
  'issue_reported': 'Payment issue',
  'expired': 'Expired',
  'cancelled': 'Cancelled',
};

class OrderReviewCard extends ConsumerWidget {
  const OrderReviewCard({super.key, required this.order, required this.customerName});

  final Order order;
  final String customerName;

  (Color, Color) _chipColors(AppTones tones) {
    switch (order.status) {
      case 'completed':
        return (tones.greenChip, tones.greenChipText);
      case 'pending_review':
        return (tones.amberChip, tones.amberChipText);
      case 'rejected':
      case 'issue_reported':
        return (tones.redChip, tones.redChipText);
      default:
        return (tones.softFill, tones.softText);
    }
  }

  void _confirmUnused(BuildContext context, WidgetRef ref) {
    final unused = order.codeUnused;
    showConfirmDialog(
      context,
      description: 'Code ${order.code} will be marked as ${unused ? 'used' : 'unused'}.',
      confirmLabel: unused ? 'Yes, mark as used' : 'Yes, mark as unused',
      onConfirm: () => ref.read(adminActionsProvider).setCodeUnused(order, !unused),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showConfirmDialog(
      context,
      description: '${order.id} will move to Cancelled and $customerName can create a new order.',
      confirmLabel: 'Yes, cancel order',
      danger: true,
      onConfirm: () => ref.read(adminActionsProvider).cancelOrder(order),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final messages = ref.watch(dataProvider.select((data) => data.messagesOf(order.customerId)));
    final pending = isPending(order);
    final completed = order.status == 'completed';
    final (chipFill, chipText) = _chipColors(tones);

    final codeMessage = messages.where((item) => item.orderId == order.id && item.kind == 'code').firstOrNull;
    final codeSentAt = order.code == null ? null : (codeMessage?.createdAt ?? order.reviewedAt);
    final screenshot = order.screenshot;
    final submittedAt = order.submittedAt;
    final code = order.code;

    return ReviewCard(
      heading: pending ? 'Pending order' : 'Completed order',
      title: order.id,
      chip: _statusLabels[order.status] ?? order.status,
      chipFill: chipFill,
      chipText: chipText,
      children: [
        ReviewRow(label: 'Plan', value: order.planName),
        ReviewRow(label: 'Sender name', value: order.senderName ?? 'Not sent yet'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screenshot', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            if (screenshot == null)
              Text('None', style: TextStyle(color: tones.faint, fontSize: 13, fontWeight: FontWeight.w500))
            else
              ReviewThumb(path: screenshot),
          ],
        ),
        if (completed)
          ReviewRow(label: 'Code sent', value: codeSentAt == null ? 'Not sent yet' : formatDateTime(codeSentAt))
        else
          ReviewRow(label: 'Submitted', value: submittedAt == null ? 'Not sent yet' : formatDateTime(submittedAt)),
        if (code != null) ReviewRow(label: 'Code', value: code, strong: true),
        if (order.status == 'rejected')
          ReviewNote(
            text: 'Rejected: ${order.rejectReason}. The customer can reply once and can’t place a new order until you approve or cancel this one.',
            fill: tones.redFill,
            ink: tones.redText,
          ),
        if (pending) ...[
          ReviewButton(label: 'Approve', fill: _approveColor, text: Colors.white, onTap: () => showApproveDialog(context, order, customerName)),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: ReviewButton(label: 'Reject', fill: _rejectColor, text: Colors.white, onTap: () => showRejectDialog(context, ref, order)),
              ),
              Expanded(
                child: ReviewButton(
                  label: 'Cancel',
                  fill: tones.amberFill,
                  text: tones.amberText,
                  border: tones.amberLine,
                  onTap: () => _confirmCancel(context, ref),
                ),
              ),
            ],
          ),
        ],
        if (completed && code == null)
          ReviewNote(
            text: 'Approved ${formatDateTime(order.reviewedAt ?? order.createdAt)}. Type the premium code in the chat to send it.',
            fill: tones.greenFill,
            ink: tones.greenText,
          ),
        if (completed && code != null)
          ReviewButton(
            label: order.codeUnused ? 'Mark as used' : 'Mark as unused',
            fill: order.codeUnused ? tones.violetFill : tones.softFill,
            text: order.codeUnused ? tones.violetText : tones.softText,
            onTap: () => _confirmUnused(context, ref),
          ),
      ],
    );
  }
}
