import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/stored_image.dart';
import '../../../data/models/order.dart';
import '../../../data/models/ticket.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../controllers/inbox_lists.dart';
import '../models/inbox_item.dart';
import 'approve_dialog.dart';
import 'card_button.dart';
import 'customer_avatar.dart';
import 'reject_dialog.dart';
import 'reply_dialog.dart';

const inboxColors = {
  'pending': Color(0xFF794983),
  'issues': Color(0xFFFFB02E),
  'completed': Color(0xFF00A884),
  'unused': Color(0xFF7F66FF),
  'blocked': Color(0xFFEF4444),
};

void showDone(BuildContext context, String message, {VoidCallback? undo}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: undo == null ? null : SnackBarAction(label: 'Undo', onPressed: undo),
    ),
  );
}

class InboxCard extends ConsumerWidget {
  const InboxCard({super.key, required this.tab, required this.item, required this.now});

  final String tab;
  final InboxItem item;
  final int now;

  void _openChat(BuildContext context) => context.push(AppRoutes.chat(item.customerId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final order = ref.watch(dataProvider.select((data) => data.order(item.key)));
    final ticket = ref.watch(dataProvider.select((data) => tab == 'issues' ? data.ticket(item.key) : null));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openChat(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(item: item, now: now),
            if (tab != 'blocked') ...[
              const SizedBox(height: 10),
              _DetailRow(tab: tab, item: item, order: order, ticket: ticket),
            ],
            _NoteRow(tab: tab, item: item, order: order),
            const SizedBox(height: 12),
            _Actions(tab: tab, item: item, order: order, ticket: ticket, onOpenChat: () => _openChat(context)),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.item, required this.now});

  final InboxItem item;
  final int now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return Row(
      children: [
        CustomerAvatar(customerId: item.customerId, size: 38),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(6)),
          child: Text(
            item.tag,
            style: TextStyle(color: tones.softText, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: item.unread ? FontWeight.w700 : FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          chatListTime(item.time, now),
          style: TextStyle(color: item.unread ? tones.title : tones.faint, fontSize: 12, fontWeight: item.unread ? FontWeight.w700 : FontWeight.w500),
        ),
        if (item.unread) ...[
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tones.title, shape: BoxShape.circle),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.tab, required this.item, required this.order, required this.ticket});

  final String tab;
  final InboxItem item;
  final Order? order;
  final Ticket? ticket;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = order;
    final issue = ticket;
    final code = (tab == 'completed' || tab == 'unused') ? current?.code : null;
    final screenshot = (tab == 'pending' || tab == 'issues') ? (current?.screenshot ?? issue?.screenshot) : null;
    final muted = TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5);

    return Row(
      children: [
        if (issue != null)
          Expanded(
            child: Text(
              issue.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurface, fontSize: 13.5, height: 1.3),
            ),
          )
        else if (current != null && tab == 'pending')
          Expanded(
            child: Text(
              '${current.planName} · ${formatMoney(current.amount)} · ${current.methodName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          )
        else if (current != null) ...[
          Text(current.planName, style: muted),
          if (code != null) ...[const SizedBox(width: 8), _CodeChip(code: code)],
          if (tab == 'completed' && code == null) ...[const SizedBox(width: 8), Text('Code not sent yet', style: muted)],
          const Spacer(),
        ] else
          Expanded(
            child: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
          ),
        if (screenshot != null) ...[const SizedBox(width: 8), _ScreenshotButton(path: screenshot, title: 'Screenshot · ${current?.id ?? issue?.id ?? ''}')],
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.tab, required this.item, required this.order});

  final String tab;
  final InboxItem item;
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final current = order;

    Widget? note;
    if (tab == 'blocked') {
      note = _Pill(text: item.subtitle, fill: tones.redFill, color: tones.redText);
    } else if (current?.status == 'rejected') {
      note = Text('Rejected: ${current?.rejectReason}', style: TextStyle(color: tones.amberText, fontSize: 12.5, height: 1.3));
    } else if (tab == 'pending' && current != null) {
      final sender = current.senderName;
      if (sender != null && sender.isNotEmpty) note = Text('Sender: $sender', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5, height: 1.3));
    }

    if (note == null) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(top: tab == 'blocked' ? 10 : 2),
      child: Align(alignment: Alignment.centerLeft, child: note),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.tab, required this.item, required this.order, required this.ticket, required this.onOpenChat});

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
    final customer = ref.watch(dataProvider.select((data) => data.customer(item.customerId)));
    final customerName = customer == null ? 'this customer' : customerTitle(customer);

    void markUnused(bool unused) {
      final target = current;
      if (target == null) return;
      actions.setCodeUnused(target, unused);
      showDone(
        context,
        unused ? 'Code ${target.code} moved to Unused codes' : 'Code ${target.code} marked as used',
        undo: () => actions.setCodeUnused(target, !unused),
      );
    }

    final buttons = <Widget>[
      if (tab == 'pending' && current != null) ...[
        CardButton(large: true, label: 'Approve', fill: tones.greenFill, text: tones.greenText, onTap: () => showApproveDialog(context, current, customerName)),
        CardButton(large: true, label: 'Reject', fill: tones.redFill, text: tones.redText, onTap: () => showRejectDialog(context, ref, current)),
        CardButton(
          large: true,
          label: 'Cancel',
          fill: tones.neutralFill,
          text: tones.neutralText,
          onTap: () => showConfirmDialog(
            context,
            title: 'Cancel ${current.id}?',
            description: 'The order moves to Cancelled and $customerName can create a new order.',
            confirmLabel: 'Yes, cancel order',
            danger: true,
            onConfirm: () {
              actions.cancelOrder(current);
              showDone(context, '${current.id} cancelled');
            },
          ),
        ),
      ],
      if (issue != null) ...[
        CardButton(large: true, label: 'Reply', fill: tones.softFill, text: tones.softText, onTap: () => showReplyDialog(context, item.customerId)),
        CardButton(
          large: true,
          label: 'Resolved',
          fill: tones.greenFill,
          text: tones.greenText,
          onTap: () => showConfirmDialog(
            context,
            title: 'Resolve ${issue.id}?',
            description: 'The request closes and the customer is told it is resolved.',
            confirmLabel: 'Yes, resolve',
            onConfirm: () {
              actions.resolveTicket(issue);
              showDone(context, '${issue.id} resolved');
            },
          ),
        ),
      ],
      if (tab == 'completed' && current != null)
        current.code == null
            ? CardButton(large: true, label: 'Open chat to send code', fill: tones.softFill, text: tones.softText, onTap: onOpenChat)
            : CardButton(
                large: true,
                label: 'Mark as unused',
                fill: tones.neutralFill,
                text: tones.neutralText,
                onTap: () => showConfirmDialog(
                  context,
                  title: 'Mark ${current.code} as unused?',
                  description: 'The code moves to Unused codes.',
                  confirmLabel: 'Yes, mark as unused',
                  onConfirm: () => markUnused(true),
                ),
              ),
      if (tab == 'unused' && current != null)
        CardButton(
          large: true,
          label: 'Mark as used',
          fill: tones.greenFill,
          text: tones.greenText,
          onTap: () => showConfirmDialog(
            context,
            title: 'Mark ${current.code} as used?',
            description: 'The code moves back to Completed.',
            confirmLabel: 'Yes, mark as used',
            onConfirm: () => markUnused(false),
          ),
        ),
      if (tab == 'blocked')
        CardButton(
          large: true,
          label: 'Unblock',
          fill: tones.softFill,
          text: tones.softText,
          onTap: () => showConfirmDialog(
            context,
            title: 'Unblock $customerName?',
            description: 'They will be able to use the chat again.',
            confirmLabel: 'Yes, unblock',
            onConfirm: () {
              actions.unblockCustomer(item.customerId);
              showDone(context, '$customerName unblocked');
            },
          ),
        ),
    ];

    return Row(
      children: [
        for (var index = 0; index < buttons.length; index++) ...[if (index > 0) const SizedBox(width: 8), Expanded(child: buttons[index])],
      ],
    );
  }
}

class _ScreenshotButton extends StatelessWidget {
  const _ScreenshotButton({required this.path, required this.title});

  final String path;
  final String title;

  void _open(BuildContext context) {
    showAppSheet<void>(
      context,
      title: title,
      subtitle: 'Tap the picture to zoom',
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: StoredImage(path: path, fit: BoxFit.contain),
            ),
          ),
          SheetButtons(label: 'Close', cancelLabel: null, onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;

    return Material(
      color: tones.neutralFill,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 15, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Screenshot',
                style: TextStyle(color: colors.onSurface, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        showDone(context, 'Copied $code');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: tones.amberFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold),
        ),
        child: Text(
          code,
          style: TextStyle(color: tones.amberText, fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.8),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fill, required this.color});

  final String text;
  final Color fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 12.5),
      ),
    );
  }
}
