import 'package:flutter/material.dart';

const _duration = Duration(milliseconds: 280);

class TabContainer extends StatelessWidget {
  const TabContainer({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var tab = 0; tab < children.length; tab++)
            IgnorePointer(
              ignoring: tab != index,
              child: AnimatedSlide(
                duration: _duration,
                curve: Curves.easeOutCubic,
                offset: Offset((tab - index).clamp(-1, 1).toDouble(), 0),
                child: TickerMode(
                  enabled: tab == index,
                  child: RepaintBoundary(child: children[tab]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
