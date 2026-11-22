import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/app_sheet.dart';

const _other = 'other';

Future<void> showReasonDialog(
  BuildContext context, {
  required String title,
  required String description,
  required List<String> reasons,
  required String confirmLabel,
  required ValueChanged<String> onConfirm,
}) {
  return showAppSheet<void>(
    context,
    title: title,
    subtitle: description,
    builder: (context) => _ReasonPicker(reasons: reasons, confirmLabel: confirmLabel, onConfirm: onConfirm),
  );
}

class _ReasonPicker extends StatefulWidget {
  const _ReasonPicker({required this.reasons, required this.confirmLabel, required this.onConfirm});

  final List<String> reasons;
  final String confirmLabel;
  final ValueChanged<String> onConfirm;

  @override
  State<_ReasonPicker> createState() => _ReasonPickerState();
}

class _ReasonPickerState extends State<_ReasonPicker> {
  late String _choice = widget.reasons.firstOrNull ?? _other;
  String _customReason = '';

  void _confirm(String reason) {
    Navigator.pop(context);
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    final reason = _choice == _other ? _customReason.trim() : _choice;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [...widget.reasons, _other])
                _ReasonChip(
                  label: item == _other ? 'Write a reason' : item,
                  selected: _choice == item,
                  onTap: () => setState(() => _choice = item),
                ),
            ],
          ),
          if (_choice == _other) ...[
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              maxLength: 150,
              onChanged: (value) => setState(() => _customReason = value),
              decoration: const InputDecoration(hintText: 'Type the reason', border: OutlineInputBorder(), isDense: true),
            ),
          ],
          SheetButtons(label: widget.confirmLabel, fill: Colors.red.shade600, onConfirm: reason.isEmpty ? null : () => _confirm(reason)),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tones.redFill : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tones.redText : tones.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? tones.redText : colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
