import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';

class CategoryChip {
  const CategoryChip({required this.key, required this.label, required this.count, this.dot, this.urgent = false});

  final String key;
  final String label;
  final int count;
  final Color? dot;
  final bool urgent;
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.chips, required this.selected, required this.onSelect});

  final List<CategoryChip> chips;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _ChipButton(chip: chip, active: chip.key == selected, onTap: () => onSelect(chip.key));
        },
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.chip, required this.active, required this.onTap});

  final CategoryChip chip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final theme = Theme.of(context);
    final dot = chip.dot;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? tones.strongButton : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? tones.strongButton : tones.border),
        ),
        child: Row(
          children: [
            if (dot != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(
              chip.label,
              style: TextStyle(color: active ? Colors.white : theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (chip.count > 0) ...[
              const SizedBox(width: 6),
              _Count(count: chip.count, active: active, urgent: chip.urgent),
            ],
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count, required this.active, required this.urgent});

  final int count;
  final bool active;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final fill = active ? Colors.white24 : (urgent ? const Color(0xFFEF4444) : tones.softFill);
    final text = active || urgent ? Colors.white : tones.softText;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
      child: Text('$count', style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
