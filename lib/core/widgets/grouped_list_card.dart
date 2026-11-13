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

class GroupedListItem extends StatelessWidget {
  const GroupedListItem({super.key, required this.first, required this.last, required this.child});

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const corner = Radius.circular(24);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: first ? corner : Radius.zero, bottom: last ? corner : Radius.zero),
      ),
      child: Column(
        children: [
          if (!first) Divider(height: 1, color: context.tones.border),
          child,
        ],
      ),
    );
  }
}
