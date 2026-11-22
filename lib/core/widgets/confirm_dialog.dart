import 'package:flutter/material.dart';

import 'app_sheet.dart';

Future<void> showConfirmDialog(
  BuildContext context, {
  required String description,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String title = 'Are you sure?',
  bool danger = false,
}) async {
  final confirmed = await showAppSheet<bool>(
    context,
    title: title,
    subtitle: description,
    builder: (context) => SheetButtons(
      label: confirmLabel,
      cancelLabel: 'No, go back',
      fill: danger ? Colors.red.shade600 : null,
      onConfirm: () => Navigator.pop(context, true),
    ),
  );
  if (confirmed == true) onConfirm();
}
