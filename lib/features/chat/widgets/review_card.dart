import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/stored_image.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.heading, required this.title, required this.chip, required this.chipFill, required this.chipText, required this.children});

  final String heading;
  final String title;
  final String chip;
  final Color chipFill;
  final Color chipText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: tones.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tones.fieldFill,
              border: Border(bottom: BorderSide(color: tones.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heading.toUpperCase(), style: TextStyle(color: tones.faint, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(title, style: TextStyle(color: colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: chipFill, borderRadius: BorderRadius.circular(6)),
                  child: Text(chip.toUpperCase(), style: TextStyle(color: chipText, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: children),
          ),
        ],
      ),
    );
  }
}

class ReviewButton extends StatelessWidget {
  const ReviewButton({super.key, required this.label, required this.fill, required this.text, required this.onTap, this.border});

  final String label;
  final Color fill;
  final Color text;
  final VoidCallback onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final line = border;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: text,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: line == null ? null : BorderSide(color: line),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class ReviewRow extends StatelessWidget {
  const ReviewRow({super.key, required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: strong ? context.tones.title : colors.onSurface,
              fontSize: 13,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewThumb extends StatelessWidget {
  const ReviewThumb({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.tones.border)),
      child: StoredImage(path: path),
    );
  }
}

class ReviewNote extends StatelessWidget {
  const ReviewNote({super.key, required this.text, required this.fill, required this.ink});

  final String text;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: ink, fontSize: 12.5)),
    );
  }
}
