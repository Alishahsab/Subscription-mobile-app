import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';

const _other = 'other';

Future<void> showReasonDialog(
  BuildContext context, {
  required String title,
  required String description,
  required List<String> reasons,
  required String confirmLabel,
  required ValueChanged<String> onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ReasonDialog(title: title, description: description, reasons: reasons, confirmLabel: confirmLabel, onConfirm: onConfirm),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.description, required this.reasons, required this.confirmLabel, required this.onConfirm});

  final String title;
  final String description;
  final List<String> reasons;
  final String confirmLabel;
  final ValueChanged<String> onConfirm;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  late String _choice = widget.reasons.firstOrNull ?? _other;
  String _customReason = '';

  void _confirm(String reason) {
    Navigator.pop(context);
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    final reason = _choice == _other ? _customReason.trim() : _choice;

    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.description),
          const SizedBox(height: 16),
          for (final item in [...widget.reasons, _other])
            _ReasonOption(
              label: item == _other ? 'Write a reason' : item,
              selected: _choice == item,
              onTap: () => setState(() => _choice = item),
            ),
          if (_choice == _other)
            TextField(
              autofocus: true,
              maxLength: 150,
              onChanged: (value) => setState(() => _customReason = value),
              decoration: const InputDecoration(hintText: 'Type the reason', border: OutlineInputBorder(), isDense: true),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          onPressed: reason.isEmpty ? null : () => _confirm(reason),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tones.redFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? tones.redText : tones.border),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 16, color: selected ? tones.redText : tones.faint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: selected ? tones.redText : colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
