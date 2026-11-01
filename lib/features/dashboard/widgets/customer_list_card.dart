import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';

const _letters = [
  ('K', Color(0xFFE9EEFB), Color(0xFF0C2660)),
  ('A', Color(0xFFF6EEDC), Color(0xFF8A6420)),
  ('T', Color(0xFFE3F5EF), Color(0xFF047857)),
];

class CustomerListCard extends StatelessWidget {
  const CustomerListCard({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 34,
              child: Stack(
                children: [
                  for (var index = 0; index < _letters.length; index++)
                    Positioned(left: index * 20, child: _Letter(letter: _letters[index], border: colors.surface)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer list', style: TextStyle(color: colors.onSurface, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  Text('$count customers · tap to see all', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: context.tones.softFill, shape: BoxShape.circle),
              child: Icon(Icons.chevron_right_rounded, size: 19, color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.border});

  final (String, Color, Color) letter;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final (text, fill, ink) = letter;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: Border.all(color: border, width: 2)),
      child: Text(text, style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
