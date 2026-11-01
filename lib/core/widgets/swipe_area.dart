import 'package:flutter/material.dart';

const _minDistance = 60.0;

class SwipeArea extends StatefulWidget {
  const SwipeArea({super.key, required this.child, this.onNext, this.onPrevious});

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  State<SwipeArea> createState() => _SwipeAreaState();
}

class _SwipeAreaState extends State<SwipeArea> {
  double _distance = 0;

  void _finish() {
    if (_distance <= -_minDistance) widget.onNext?.call();
    if (_distance >= _minDistance) widget.onPrevious?.call();
    _distance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _distance = 0,
      onHorizontalDragUpdate: (details) => _distance += details.primaryDelta ?? 0,
      onHorizontalDragEnd: (_) => _finish(),
      child: widget.child,
    );
  }
}
