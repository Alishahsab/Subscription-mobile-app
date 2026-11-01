import 'package:flutter/material.dart';

import '../controllers/search_results.dart';

const _highlight = Color(0xB3FDE68A);

class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key, required this.text, required this.query, required this.style});

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final snippet = snippetOf(text, query.trim());

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: snippet.before),
          TextSpan(text: snippet.match, style: const TextStyle(backgroundColor: _highlight, color: Colors.black)),
          TextSpan(text: snippet.after),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
