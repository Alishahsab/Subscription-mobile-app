import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import 'approve_dialog.dart';
import 'card_button.dart';
import 'reject_dialog.dart';

class OrderButtons extends ConsumerWidget {
  const OrderButtons({super.key, required this.order, required this.customerName});

  final Order order;
  final String customerName;

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

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        CardButton(label: 'Approve', fill: tones.strongButton, text: Colors.white, onTap: () => showApproveDialog(context, order, customerName)),
        CardButton(label: 'Reject', fill: tones.redFill, text: tones.redText, onTap: () => showRejectDialog(context, ref, order)),
        CardButton(label: 'Cancel', fill: tones.neutralFill, text: tones.neutralText, onTap: () => _confirmCancel(context, ref)),
      ],
    );
  }
}
