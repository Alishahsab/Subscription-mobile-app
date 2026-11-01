import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/text_rules.dart';
import 'settings_ui.dart';
import 'steps_editor.dart';

class QuickRepliesEditor extends StatelessWidget {
  const QuickRepliesEditor({super.key, required this.replies, required this.onChanged});

  final List<String> replies;
  final ValueChanged<List<String>> onChanged;

  void _move(int from, int to) {
    final next = [...replies];
    next.insert(to, next.removeAt(from));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (replies.isEmpty) Text('No quick replies yet.', style: TextStyle(color: context.tones.faint, fontSize: 12.5)),
        for (var index = 0; index < replies.length; index++)
          Row(
            children: [
              NumberBadge(number: index + 1),
              const SizedBox(width: 6),
              Expanded(
                child: SettingsInput(
                  value: replies[index],
                  placeholder: 'Type a quick reply',
                  maxLength: 300,
                  maxLines: 4,
                  onChanged: (value) => onChanged([...replies]..[index] = oneLine(value)),
                ),
              ),
              StepActions(
                onUp: index == 0 ? null : () => _move(index, index - 1),
                onDown: index == replies.length - 1 ? null : () => _move(index, index + 1),
                onDelete: () => onChanged([...replies]..removeAt(index)),
              ),
            ],
          ),
        OutlinedButton(onPressed: () => onChanged([...replies, '']), child: const Text('Add reply', style: TextStyle(fontSize: 12.5))),
      ],
    );
  }
}
