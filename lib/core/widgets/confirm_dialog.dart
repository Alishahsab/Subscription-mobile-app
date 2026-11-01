import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';

Future<void> showConfirmDialog(
  BuildContext context, {
  required String description,
  required String confirmLabel,
  required VoidCallback onConfirm,
  bool danger = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmDialog(description: description, confirmLabel: confirmLabel, danger: danger),
  );
  if (confirmed == true) onConfirm();
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.description, required this.confirmLabel, required this.danger});

  final String description;
  final String confirmLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Are you sure?', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant, size: 20),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(description, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5, height: 1.4)),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: tones.border),
                        shape: shape,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No, go back', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: danger ? Colors.red.shade600 : tones.strongButton,
                        foregroundColor: Colors.white,
                        shape: shape,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
