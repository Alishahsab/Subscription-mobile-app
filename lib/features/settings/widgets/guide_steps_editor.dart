import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/utils/text_rules.dart';
import '../../../data/models/db_row.dart';
import '../../../data/repositories/image_repository.dart';
import 'settings_ui.dart';
import 'steps_editor.dart';

class GuideStepsEditor extends StatelessWidget {
  const GuideStepsEditor({super.key, required this.steps, required this.onChanged});

  final List<DbRow> steps;
  final ValueChanged<List<DbRow>> onChanged;

  void _change(int index, DbRow Function(DbRow step) update) {
    onChanged([...steps]..[index] = update(steps[index]));
  }

  void _move(int from, int to) {
    final next = [...steps];
    next.insert(to, next.removeAt(from));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (var index = 0; index < steps.length; index++)
          _GuideStep(
            key: ValueKey(steps[index]['id']),
            step: steps[index],
            number: index + 1,
            onText: (value) => _change(index, (step) => {...step, 'text': oneLine(value)}),
            onImage: (url) => _change(index, (step) => {...step, 'image': url}),
            onRemoveImage: () => _change(index, (step) => {...step}..remove('image')),
            onUp: index == 0 ? null : () => _move(index, index - 1),
            onDown: index == steps.length - 1 ? null : () => _move(index, index + 1),
            onDelete: () => onChanged([...steps]..removeAt(index)),
          ),
        OutlinedButton(
          onPressed: () => onChanged([...steps, {'id': createId(), 'text': ''}]),
          child: const Text('Add step', style: TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}

class _GuideStep extends ConsumerStatefulWidget {
  const _GuideStep({
    super.key,
    required this.step,
    required this.number,
    required this.onText,
    required this.onImage,
    required this.onRemoveImage,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });

  final DbRow step;
  final int number;
  final ValueChanged<String> onText;
  final ValueChanged<String> onImage;
  final VoidCallback onRemoveImage;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onDelete;

  @override
  ConsumerState<_GuideStep> createState() => _GuideStepState();
}

class _GuideStepState extends ConsumerState<_GuideStep> {
  bool _uploading = false;
  bool _failed = false;

  Future<void> _attach() async {
    setState(() {
      _uploading = true;
      _failed = false;
    });

    try {
      final image = await pickImageFromGallery();
      if (image != null) widget.onImage(await ref.read(imageRepositoryProvider).uploadGuide(image.bytes));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final image = widget.step['image'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NumberBadge(number: widget.number),
            const SizedBox(width: 6),
            Expanded(
              child: SettingsInput(
                value: widget.step['text'] as String,
                placeholder: 'Describe this step',
                maxLength: 150,
                maxLines: 4,
                onChanged: widget.onText,
              ),
            ),
            GestureDetector(
              onTap: _uploading ? null : _attach,
              child: SizedBox(
                width: 28,
                height: 32,
                child: Icon(Icons.add_photo_alternate_outlined, size: 15, color: _failed ? tones.redText : tones.faint),
              ),
            ),
            StepActions(onUp: widget.onUp, onDown: widget.onDown, onDelete: widget.onDelete),
          ],
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 8, 0, 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(image, height: 80)),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: widget.onRemoveImage,
                    child: const CircleAvatar(radius: 10, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 12, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
