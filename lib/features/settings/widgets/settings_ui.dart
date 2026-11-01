import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, this.actionLabel, this.onAction, required this.children});

  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final heading = title;
    final action = actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(heading.toUpperCase(), style: TextStyle(color: tones.faint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9)),
                ),
                if (action != null) TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) Divider(height: 1, color: tones.border),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, this.sub, this.twoLines = false, this.dot, this.value, this.count, this.end, this.onTap});

  final String title;
  final String? sub;
  final bool twoLines;
  final Color? dot;
  final String? value;
  final int? count;
  final Widget? end;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final subtitle = sub;
    final dotColor = dot;
    final valueText = value;
    final countValue = count;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      maxLines: twoLines ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          if (valueText != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tones.title, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (countValue != null)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(999)),
              child: Text('$countValue', style: TextStyle(color: tones.softText, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
          if (end != null || onTap != null) const SizedBox(width: 10),
          end ?? (onTap == null ? const SizedBox() : Icon(Icons.chevron_right_rounded, size: 16, color: tones.faint)),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.title, this.sub, required this.value, required this.onChanged});

  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(title: title, sub: sub, end: SettingsSwitch(value: value, onChanged: onChanged));
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: FittedBox(child: Switch(value: value, onChanged: onChanged, activeTrackColor: context.tones.strongButton)),
    );
  }
}

class SettingsInput extends StatefulWidget {
  const SettingsInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final int? maxLength;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;

  @override
  State<SettingsInput> createState() => _SettingsInputState();
}

class _SettingsInputState extends State<SettingsInput> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SettingsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return TextField(
      controller: _controller,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: TextStyle(color: tones.faint, fontSize: 14),
        counterText: '',
        filled: true,
        fillColor: tones.fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class InputBlock extends StatelessWidget {
  const InputBlock({super.key, required this.label, this.hint, required this.child});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final note = hint;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          child,
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(note, style: TextStyle(color: context.tones.faint, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}

class NumberChoices extends StatelessWidget {
  const NumberChoices({super.key, required this.values, required this.value, required this.onChanged});

  final List<int> values;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[index]),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: values[index] == value ? tones.strongButton : tones.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${values[index]}',
                  style: TextStyle(
                    color: values[index] == value ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SmallNote extends StatelessWidget {
  const SmallNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
    );
  }
}

class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.tones.strongButton, shape: BoxShape.circle),
      child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
