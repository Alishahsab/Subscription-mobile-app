import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';

class GroupedListCard extends StatelessWidget {
  const GroupedListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: context.tones.border);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) divider,
            children[index],
          ],
        ],
      ),
    );
  }
}
