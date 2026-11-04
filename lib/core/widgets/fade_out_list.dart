import 'package:flutter/material.dart';

const _leaveTime = Duration(milliseconds: 280);

class FadeOutList<T> extends StatefulWidget {
  const FadeOutList({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    required this.empty,
    this.storageKey,
    this.padding,
    this.spacing = 10,
  });

  final List<T> items;
  final String Function(T item) keyOf;
  final Widget Function(T item) itemBuilder;
  final Widget empty;
  final Key? storageKey;
  final EdgeInsets? padding;
  final double spacing;

  @override
  State<FadeOutList<T>> createState() => _FadeOutListState<T>();
}

class _FadeOutListState<T> extends State<FadeOutList<T>> {
  final _leaving = <String>{};
  late List<T> _rows = widget.items;

  @override
  void didUpdateWidget(FadeOutList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final kept = widget.items.map(widget.keyOf).toSet();
    final rows = [...widget.items];

    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index];
      final key = widget.keyOf(row);
      if (kept.contains(key)) continue;
      _leaving.add(key);
      rows.insert(index.clamp(0, rows.length), row);
    }
    _leaving.retainWhere((key) => !kept.contains(key));
    _rows = rows;
  }

  void _finish(String key) {
    if (!mounted) return;
    setState(() {
      _leaving.remove(key);
      _rows = _rows.where((row) => widget.keyOf(row) != key).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return ListView(key: widget.storageKey, padding: widget.padding, children: [widget.empty]);

    return ListView.separated(
      key: widget.storageKey,
      padding: widget.padding,
      itemCount: _rows.length,
      separatorBuilder: (context, index) => SizedBox(height: widget.spacing),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final key = widget.keyOf(row);
        final child = widget.itemBuilder(row);
        if (!_leaving.contains(key)) return KeyedSubtree(key: ValueKey(key), child: child);
        return _Leaving(key: ValueKey('leaving $key'), onDone: () => _finish(key), child: child);
      },
    );
  }
}

class _Leaving extends StatefulWidget {
  const _Leaving({super.key, required this.onDone, required this.child});

  final VoidCallback onDone;
  final Widget child;

  @override
  State<_Leaving> createState() => _LeavingState();
}

class _LeavingState extends State<_Leaving> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: _leaveTime)..forward().whenComplete(widget.onDone);
  late final _shown = ReverseAnimation(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizeTransition(
        sizeFactor: _shown,
        axisAlignment: -1,
        child: FadeTransition(opacity: _shown, child: widget.child),
      ),
    );
  }
}
