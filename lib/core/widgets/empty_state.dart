import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.description});

  final IconData icon;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: context.tones.softFill, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          if (text != null) ...[
            const SizedBox(height: 4),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}
