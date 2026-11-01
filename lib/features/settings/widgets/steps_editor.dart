import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/text_rules.dart';
import 'settings_ui.dart';

class StepsEditor extends StatefulWidget {
  const StepsEditor({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<StepsEditor> createState() => _StepsEditorState();
}

class _StepsEditorState extends State<StepsEditor> {
  bool _firstStepAdded = false;

  List<String> get _steps {
    final saved = widget.value.isEmpty ? <String>[] : widget.value.split('\n').map((line) => line.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '')).toList();
    return saved.isEmpty && _firstStepAdded ? [''] : saved;
  }

  void _save(List<String> steps) {
    setState(() => _firstStepAdded = steps.isNotEmpty);
    widget.onChanged(steps.join('\n'));
  }

  void _move(int from, int to) {
    final steps = _steps;
    steps.insert(to, steps.removeAt(from));
    _save(steps);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final steps = _steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (steps.isEmpty) Text('No steps yet. Customers will not see a Steps button for this method.', style: TextStyle(color: tones.faint, fontSize: 12.5)),
        for (var index = 0; index < steps.length; index++)
          Row(
            children: [
              NumberBadge(number: index + 1),
              const SizedBox(width: 6),
              Expanded(
                child: SettingsInput(
                  value: steps[index],
                  placeholder: 'Describe this step',
                  maxLength: 150,
                  maxLines: 4,
                  onChanged: (value) {
                    final next = _steps;
                    next[index] = oneLine(value);
                    _save(next);
                  },
                ),
              ),
              StepActions(
                onUp: index == 0 ? null : () => _move(index, index - 1),
                onDown: index == steps.length - 1 ? null : () => _move(index, index + 1),
                onDelete: () => _save(_steps..removeAt(index)),
              ),
            ],
          ),
        OutlinedButton(onPressed: () => _save([...steps, '']), child: const Text('Add step', style: TextStyle(fontSize: 12.5))),
      ],
    );
  }
}

class StepActions extends StatelessWidget {
  const StepActions({super.key, required this.onUp, required this.onDown, required this.onDelete});

  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: Icons.keyboard_arrow_up_rounded, onTap: onUp),
        _ActionIcon(icon: Icons.keyboard_arrow_down_rounded, onTap: onDown),
        _ActionIcon(icon: Icons.delete_outline_rounded, onTap: onDelete),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1,
        child: SizedBox(width: 28, height: 32, child: Icon(icon, size: 16, color: context.tones.faint)),
      ),
    );
  }
}
