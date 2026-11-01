import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'home_tab.dart';

const _slide = Duration(milliseconds: 300);
const _curve = Curves.easeOutCubic;
const _barColor = Color(0xB83F3A38);

class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({super.key, required this.index, required this.onSelect, this.inboxCount = 0});

  final int index;
  final ValueChanged<int> onSelect;
  final int inboxCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: RepaintBoundary(
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              color: _barColor,
              boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -8)],
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: 1 / homeTabs.length,
                  heightFactor: 1,
                  child: AnimatedSlide(
                    duration: _slide,
                    curve: _curve,
                    offset: Offset(index.toDouble(), 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < homeTabs.length; i++)
                      Expanded(
                        child: _TabButton(
                          tab: homeTabs[i],
                          active: i == index,
                          count: homeTabs[i].section == 'inbox' ? inboxCount : 0,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.active, required this.count, required this.onTap});

  final HomeTab tab;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : Colors.white;

    return Semantics(
      button: true,
      selected: active,
      label: count > 0 ? '${tab.label}, $count waiting' : tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TweenAnimationBuilder<Color?>(
                  duration: _slide,
                  curve: _curve,
                  tween: ColorTween(end: color),
                  builder: (context, value, _) => _TabIcon(tab: tab, active: active, color: value ?? color),
                ),
                if (count > 0 && !active)
                  Positioned(
                    top: -5,
                    right: -9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _slide,
              curve: _curve,
              style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600),
              child: Text(tab.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.tab, required this.active, required this.color});

  final HomeTab tab;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(active ? tab.activeIcon : tab.icon, color: color, size: 23);
    if (!active || tab.section != 'dashboard') return icon;

    return Stack(
      alignment: Alignment.center,
      children: [icon, const CustomPaint(size: Size(23, 23), painter: _SmilePainter())],
    );
  }
}

class _SmilePainter extends CustomPainter {
  const _SmilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final box = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.62), width: 8, height: 5);
    canvas.drawArc(box, 0.3, 2.5, false, paint);
  }

  @override
  bool shouldRepaint(_SmilePainter oldDelegate) => false;
}
