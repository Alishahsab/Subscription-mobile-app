import 'package:flutter/material.dart';

class CardButton extends StatelessWidget {
  const CardButton({super.key, required this.label, required this.fill, required this.text, required this.onTap, this.large = false});

  final String label;
  final Color fill;
  final Color text;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(large ? 12 : 999);

    return Material(
      color: fill,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: large ? 40 : 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: text, fontSize: large ? 13.5 : 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
