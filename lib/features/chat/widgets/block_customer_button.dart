import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/data_notifier.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/reason_dialog.dart';
import 'review_card.dart';

void openBlockDialog(BuildContext context, WidgetRef ref, Customer customer) {
  final actions = ref.read(adminActionsProvider);
  final name = customerTitle(customer);

  if (customer.blocked) {
    showConfirmDialog(
      context,
      description: '$name will be able to use the chat again.',
      confirmLabel: 'Yes, unblock',
      onConfirm: () => actions.unblockCustomer(customer.id),
    );
    return;
  }

  showReasonDialog(
    context,
    title: 'Block customer',
    description: '$name will see this reason',
    reasons: ref.read(dataProvider).config?.blockReasons ?? const [],
    confirmLabel: 'Block',
    onConfirm: (reason) => actions.blockCustomer(customer.id, reason),
  );
}

class BlockCustomerButton extends ConsumerWidget {
  const BlockCustomerButton({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;

    return ReviewButton(
      label: customer.blocked ? 'Unblock' : 'Block',
      fill: tones.redFill,
      text: tones.redText,
      border: tones.redLine,
      onTap: () => openBlockDialog(context, ref, customer),
    );
  }
}
