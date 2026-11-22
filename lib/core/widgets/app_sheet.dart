import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';

Future<T?> showAppSheet<T>(BuildContext context, {required String title, String? subtitle, required Widget Function(BuildContext context) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
              ],
              const SizedBox(height: 14),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      );
    },
  );
}

class SheetOption extends StatelessWidget {
  const SheetOption({super.key, required this.title, this.sub, required this.selected, required this.onTap});

  final String title;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final subtitle = sub;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: tones.border))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: selected ? tones.chartPicked : colors.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 20, color: tones.chartPicked),
          ],
        ),
      ),
    );
  }
}

class SheetButtons extends StatelessWidget {
  const SheetButtons({super.key, required this.label, required this.onConfirm, this.fill, this.text, this.cancelLabel = 'Back'});

  final String label;
  final VoidCallback? onConfirm;
  final Color? fill;
  final Color? text;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final back = cancelLabel;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (back != null) ...[
            Expanded(
              child: _SheetButton(label: back, fill: tones.chartTrack, text: colors.onSurface, onTap: () => Navigator.pop(context)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _SheetButton(label: label, fill: fill ?? tones.strongButton, text: text ?? Colors.white, onTap: onConfirm),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.fill, required this.text, required this.onTap});

  final String label;
  final Color fill;
  final Color text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 46,
            child: Center(child: Text(label, style: TextStyle(color: text, fontSize: 14.5, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }
}
