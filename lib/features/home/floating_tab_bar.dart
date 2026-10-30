import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'home_tab.dart';

const _slide = Duration(milliseconds: 300);
const _curve = Curves.easeOutCubic;
const _orange = Color(0xFFF5871F);

class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({super.key, required this.index, required this.onSelect, this.inboxCount = 0});

  final int index;
  final ValueChanged<int> onSelect;
  final int inboxCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: RepaintBoundary(
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF02A3550), Color(0xF5141A28)],
              ),
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
    final color = active ? _orange : Colors.white;

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
                  builder: (context, value, _) => Icon(active ? tab.activeIcon : tab.icon, color: value ?? color, size: 23),
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
