import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/data_notifier.dart';
import 'reason_dialog.dart';

Future<void> showRejectDialog(BuildContext context, WidgetRef ref, Order order) {
  return showReasonDialog(
    context,
    title: 'Reject payment',
    description: '${order.id} · the customer will see this reason',
    reasons: ref.read(dataProvider).config?.rejectReasons ?? const [],
    confirmLabel: 'Reject',
    onConfirm: (reason) => ref.read(adminActionsProvider).rejectOrder(order, reason),
  );
}
