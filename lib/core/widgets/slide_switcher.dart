import 'package:flutter/material.dart';

const _duration = Duration(milliseconds: 200);
const _shift = 0.06;

class SlideSwitcher extends StatefulWidget {
  const SlideSwitcher({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<SlideSwitcher> createState() => _SlideSwitcherState();
}

class _SlideSwitcherState extends State<SlideSwitcher> {
  double _side = 1;

  @override
  void didUpdateWidget(SlideSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) _side = widget.index > oldWidget.index ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(widget.index);

    return ClipRect(
      child: AnimatedSwitcher(
        duration: _duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previous) => Stack(fit: StackFit.expand, children: [...previous, ?currentChild]),
        transitionBuilder: (child, animation) {
          final start = child.key == current ? _side : -_side;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: Offset(start * _shift, 0), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: current, child: widget.child),
      ),
    );
  }
}
