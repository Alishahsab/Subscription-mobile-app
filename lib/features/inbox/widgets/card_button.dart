import 'package:flutter/material.dart';

class CardButton extends StatelessWidget {
  const CardButton({super.key, required this.label, required this.fill, required this.text, required this.onTap});

  final String label;
  final Color fill;
  final Color text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
        child: Center(
          widthFactor: 1,
          child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
