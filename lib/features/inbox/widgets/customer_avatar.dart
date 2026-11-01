import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/sync/app_data.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../controllers/inbox_lists.dart';

const _hues = [210.0, 160.0, 30.0, 280.0, 340.0, 190.0, 100.0];
const _gapDegrees = 3.0;

class StatusColors {
  StatusColors._();

  static const activeOrder = Color(0xFF0A84FF);
  static const appIssue = Color(0xFFFFB02E);
  static const unused = Color(0xFF7F66FF);
  static const pending = Color(0xFF794983);
  static const complete = Color(0xFF00A884);
  static const cancelled = Color(0xFFC38763);
  static const activeChat = Color(0xFF22C55E);
  static const inactiveChat = Color(0xFF9CA3AF);
  static const blocked = Color(0xFFEF4444);
}

Color? _orderColor(AppData data, String customerId, int now) {
  final orders = data.ordersOf(customerId);
  if (orders.any(isPending)) return StatusColors.pending;
  if (orders.any((order) => canStillPay(order, now))) return StatusColors.activeOrder;
  if (orders.isEmpty) return null;

  final latest = orders.reduce((a, b) => b.createdAt > a.createdAt ? b : a);
  final cancelled = latest.status == 'cancelled' || latest.status == 'expired';
  return cancelled ? StatusColors.cancelled : null;
}

Color? _completionColor(AppData data, String customerId) {
  final orders = data.ordersOf(customerId);
  if (orders.any((order) => order.codeUnused)) return StatusColors.unused;
  if (orders.any((order) => order.status == 'completed')) return StatusColors.complete;
  return null;
}

class CustomerAvatar extends ConsumerWidget {
  const CustomerAvatar({super.key, required this.customerId, this.size = 52});

  final String customerId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final now = watchNow(ref);
    final customer = data.customer(customerId);
    final hasIssue = data.tickets.any((item) => item.customerId == customerId && item.kind == 'support' && item.status == 'open');
    final active = isCustomerActive(data, customerId, now);
    final surface = Theme.of(context).colorScheme.surface;

    final ring = (size * 0.17).roundToDouble();
    final dot = (size * 0.22).roundToDouble();
    final cross = (size * 0.36).roundToDouble();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              width: ring,
              empty: context.tones.border,
              quarters: [
                _orderColor(data, customerId, now),
                null,
                hasIssue ? StatusColors.appIssue : null,
                _completionColor(data, customerId),
              ],
            ),
          ),
          _Initials(name: customer?.email ?? '?', size: size - ring * 2 - 2),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: active ? StatusColors.activeChat : StatusColors.inactiveChat,
                shape: BoxShape.circle,
                border: Border.all(color: surface, width: 2),
              ),
            ),
          ),
          if (customer?.blocked ?? false)
            Positioned(
              left: size * 0.12,
              bottom: -size * 0.02,
              child: Container(
                width: cross,
                height: cross,
                decoration: BoxDecoration(color: StatusColors.blocked, shape: BoxShape.circle, border: Border.all(color: surface, width: 2)),
                child: Icon(Icons.close_rounded, color: Colors.white, size: cross * 0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = _hues[name.codeUnits.fold(0, (sum, unit) => sum + unit) % _hues.length];
    final initials = name.split(' ').take(2).map((word) => word.isEmpty ? '' : word[0]).join().toUpperCase();

    final fill = HSLColor.fromAHSL(1, hue, dark ? 0.28 : 0.6, dark ? 0.22 : 0.94).toColor();
    final text = HSLColor.fromAHSL(1, hue, dark ? 0.6 : 0.45, dark ? 0.8 : 0.32).toColor();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: text, fontSize: size * 0.36, fontWeight: FontWeight.w600)),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.width, required this.empty, required this.quarters});

  final double width;
  final Color empty;
  final List<Color?> quarters;

  double _radians(double degrees) => (degrees - 90) * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final box = Rect.fromCircle(center: center, radius: size.width / 2 - width / 2);

    for (var index = 0; index < quarters.length; index++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = quarters[index] ?? empty;
      final start = _radians(index * 90 + _gapDegrees / 2);
      canvas.drawArc(box, start, (90 - _gapDegrees) * pi / 180, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}
