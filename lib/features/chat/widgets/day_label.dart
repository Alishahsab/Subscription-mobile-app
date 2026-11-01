import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';

class DayLabel extends StatelessWidget {
  const DayLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.tones.border),
      ),
      child: Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}
