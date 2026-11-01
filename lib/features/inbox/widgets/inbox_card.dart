import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/stored_image.dart';
import '../../../data/models/order.dart';
import '../../../data/models/ticket.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../controllers/inbox_lists.dart';
import '../models/inbox_item.dart';
import 'card_button.dart';
import 'customer_avatar.dart';
import 'order_buttons.dart';
import 'reply_dialog.dart';

const inboxColors = {
  'pending': Color(0xFF794983),
  'issues': Color(0xFFFFB02E),
  'completed': Color(0xFF00A884),
  'unused': Color(0xFF7F66FF),
  'blocked': Color(0xFFEF4444),
};

class InboxCard extends ConsumerWidget {
  const InboxCard({super.key, required this.tab, required this.item, required this.now});

  final String tab;
  final InboxItem item;
  final int now;

  void _openChat(BuildContext context) => context.push(AppRoutes.chat(item.customerId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    final order = data.orders.where((entry) => entry.id == item.key).firstOrNull;
    final ticket = tab == 'issues' ? data.tickets.where((entry) => entry.id == item.key).firstOrNull : null;
    final showsCode = (tab == 'completed' || tab == 'unused') && order?.code != null;
    final screenshot = showsCode ? null : (order?.screenshot ?? ticket?.screenshot);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 14,
            bottom: 14,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: inboxColors[tab],
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(onTap: () => _openChat(context), child: CustomerAvatar(customerId: item.customerId, size: 44)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openChat(context),
                        child: _NameRow(item: item, now: now),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openChat(context),
                              child: _CardDetails(tab: tab, item: item, order: order, ticket: ticket),
                            ),
                          ),
                          if (screenshot != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(top: 4),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: tones.border)),
                              child: StoredImage(path: screenshot),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CardButtons(tab: tab, item: item, order: order, ticket: ticket, onOpenChat: () => _openChat(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.item, required this.now});

  final InboxItem item;
  final int now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    final title = Text(
      item.title,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: colors.onSurface, fontSize: 13.5, fontWeight: item.unread ? FontWeight.w700 : FontWeight.w600),
    );

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(5)),
          child: Text(item.tag, style: TextStyle(color: tones.softText, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Expanded(child: title),
        const SizedBox(width: 6),
        Text(
          chatListTime(item.time, now),
          style: TextStyle(
            color: item.unread ? tones.title : tones.faint,
            fontSize: 10.5,
            fontWeight: item.unread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        if (item.unread) ...[
          const SizedBox(width: 4),
          Container(width: 7, height: 7, decoration: BoxDecoration(color: tones.title, shape: BoxShape.circle)),
        ],
      ],
    );
  }
}

class _CardDetails extends StatelessWidget {
  const _CardDetails({required this.tab, required this.item, required this.order, required this.ticket});

  final String tab;
  final InboxItem item;
  final Order? order;
  final Ticket? ticket;

  String _line() {
    final current = order;
    if (current == null) return '';
    if (tab == 'pending') {
      return [current.planName, formatMoney(current.amount), current.methodName].join(' · ');
    }
    if (tab == 'completed' || tab == 'unused') {
      return current.code != null ? current.planName : '${current.planName} · Code not sent yet';
    }
    return '';
  }

  (Color, Color) _badgeColors(AppTones tones) {
    if (tab == 'unused') return (tones.violetFill, tones.violetText);
    switch (item.badgeTone) {
      case BadgeTone.amber:
        return (tones.amberFill, tones.amberText);
      case BadgeTone.red:
        return (tones.redFill, tones.redText);
      default:
        return (tones.softFill, tones.softText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final line = _line();
    final sender = tab == 'pending' ? order?.senderName : null;
    final code = (tab == 'completed' || tab == 'unused') ? order?.code : null;
    final badge = item.badge;
    final showsBadge = (tab == 'pending' && order?.status != 'rejected') || tab == 'issues';
    final (badgeFill, badgeText) = _badgeColors(tones);

    String? note;
    var noteColor = tones.redText;
    var noteLines = 3;
    if (order?.status == 'rejected') note = 'Rejected: ${order?.rejectReason}';
    if (ticket != null) {
      note = ticket?.message;
      noteColor = colors.onSurfaceVariant;
      noteLines = 2;
    }
    if (tab == 'blocked') {
      note = item.subtitle;
      noteLines = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sender != null && sender.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              sender,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        if (line.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                ),
                if (code != null) ...[const SizedBox(width: 8), _CodeChip(code: code)],
              ],
            ),
          ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(note, maxLines: noteLines, overflow: TextOverflow.ellipsis, style: TextStyle(color: noteColor, fontSize: 12, height: 1.3)),
          ),
        if (showsBadge && badge != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: badgeFill, borderRadius: BorderRadius.circular(999)),
            child: Text(badge, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tones.amberFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold),
      ),
      child: Text(
        code,
        style: TextStyle(color: tones.title, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
    );
  }
}

class _CardButtons extends ConsumerWidget {
  const _CardButtons({required this.tab, required this.item, required this.order, required this.ticket, required this.onOpenChat});

  final String tab;
  final InboxItem item;
  final Order? order;
  final Ticket? ticket;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final actions = ref.read(adminActionsProvider);
    final current = order;
    final issue = ticket;
    final data = ref.watch(dataProvider);
    final customer = data.customer(item.customerId);
    final customerName = customer == null ? 'this customer' : customerTitle(customer);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (tab == 'pending' && current != null) OrderButtons(order: current, customerName: customerName),
        if (issue != null) ...[
          CardButton(
            label: 'Resolved',
            fill: tones.strongButton,
            text: Colors.white,
            onTap: () => showConfirmDialog(
              context,
              description: '${issue.id} will be closed and the customer will be told it is resolved.',
              confirmLabel: 'Yes, resolve',
              onConfirm: () => actions.resolveTicket(issue),
            ),
          ),
          CardButton(label: 'Reply', fill: tones.softFill, text: tones.softText, onTap: () => showReplyDialog(context, item.customerId)),
        ],
        if (tab == 'completed' && current != null)
          current.code == null
              ? CardButton(label: 'Open chat to send code', fill: tones.softFill, text: tones.softText, onTap: onOpenChat)
              : CardButton(
                  label: 'Mark as unused',
                  fill: tones.softFill,
                  text: tones.softText,
                  onTap: () => showConfirmDialog(
                    context,
                    description: 'Code ${current.code} will be marked as unused.',
                    confirmLabel: 'Yes, mark as unused',
                    onConfirm: () => actions.setCodeUnused(current, true),
                  ),
                ),
        if (tab == 'unused' && current != null)
          CardButton(
            label: 'Mark as used',
            fill: tones.violetFill,
            text: tones.violetText,
            onTap: () => showConfirmDialog(
              context,
              description: 'Code ${current.code} will be marked as used.',
              confirmLabel: 'Yes, mark as used',
              onConfirm: () => actions.setCodeUnused(current, false),
            ),
          ),
        if (tab == 'blocked')
          CardButton(
            label: 'Unblock',
            fill: tones.redFill,
            text: tones.redText,
            onTap: () => showConfirmDialog(
              context,
              description: '$customerName will be able to use the chat again.',
              confirmLabel: 'Yes, unblock',
              onConfirm: () => actions.unblockCustomer(item.customerId),
            ),
          ),
      ],
    );
  }
}
