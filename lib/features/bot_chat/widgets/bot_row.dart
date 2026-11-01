import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/order.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/models/inbox_item.dart';
import '../../inbox/widgets/customer_avatar.dart';

class BotRow extends StatelessWidget {
  const BotRow({super.key, required this.item, required this.filter, required this.order, required this.unreadCount, required this.now});

  final InboxItem item;
  final String filter;
  final Order? order;
  final int unreadCount;
  final int now;

  (Color, Color) _badgeColors(AppTones tones) {
    return item.badgeTone == BadgeTone.blue ? (tones.blueFill, tones.blueText) : (tones.softFill, tones.softText);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final current = order;
    final activeOrders = filter == BotFilter.activeOrders;
    final badge = item.badge;
    final (badgeFill, badgeText) = _badgeColors(tones);

    return InkWell(
      onTap: () => context.push(AppRoutes.chat(item.customerId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CustomerAvatar(customerId: item.customerId, size: 44),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(5)),
                        child: Text(item.tag, style: TextStyle(color: tones.softText, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chatListTime(item.time, now),
                        style: TextStyle(color: item.unread ? tones.title : tones.faint, fontSize: 10.5, fontWeight: item.unread ? FontWeight.w700 : FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          current == null ? item.subtitle : _orderLine(current),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: item.unread ? FontWeight.w600 : FontWeight.w400),
                        ),
                      ),
                      if (unreadCount > 0) _UnreadBubble(count: unreadCount),
                    ],
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: badgeFill, borderRadius: BorderRadius.circular(999)),
                      child: Text(badge, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  if (activeOrders && current != null) _TimeLeftBar(order: current, now: now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _orderLine(Order order) {
    final line = '${order.planName} · ${formatMoney(order.amount)}';
    return filter == BotFilter.activeOrders ? '$line · ${order.methodName}' : line;
  }
}

class _UnreadBubble extends StatelessWidget {
  const _UnreadBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.tones.strongButton, borderRadius: BorderRadius.circular(999)),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _TimeLeftBar extends StatelessWidget {
  const _TimeLeftBar({required this.order, required this.now});

  final Order order;
  final int now;

  @override
  Widget build(BuildContext context) {
    final left = max(0, (order.expiresAt - now) / (order.expiresAt - order.createdAt)).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: left.clamp(0, 1),
        minHeight: 4,
        color: const Color(0xFF0A84FF),
        backgroundColor: context.tones.softFill,
      ),
    );
  }
}
