import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/stored_image.dart';
import '../../../data/models/message.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import 'message_meta.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.message, required this.order, required this.showMeta});

  final Message message;
  final Order? order;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final current = order;

    switch (message.kind) {
      case 'payment':
        if (current == null) break;
        return _SystemNote(text: 'Order ${current.id} created · ${current.planName} · ${formatMoney(current.amount)} · ${current.methodName}');
      case 'steps':
        return const _SystemNote(text: 'Payment steps shown to customer');
      case 'instructions':
        return const _SystemNote(text: 'Code activation instructions sent');
      case 'code':
        return _CodeBubble(message: message, code: current?.code);
      case 'proof':
        return _ImageCard(
          image: current?.screenshot,
          title: 'Payment proof',
          detail: [Text('From ${current?.senderName ?? 'N/A'} · ', style: _detailStyle(context)), MessageTime(time: message.createdAt)],
        );
      case 'deleted':
        return _DeletedBubble(message: message);
      case 'image':
        final fromAdmin = message.sender == 'admin';
        return _ImageCard(
          image: message.image,
          title: fromAdmin ? 'You sent an image' : 'Screenshot',
          alignRight: fromAdmin,
          action: canDeleteMessage(message) ? _DeleteButton(message: message) : null,
          detail: [MessageTime(time: message.createdAt), if (fromAdmin) ...[const SizedBox(width: 4), MessageTicks(message: message)]],
        );
    }
    return _TextBubble(message: message, showMeta: showMeta);
  }
}

TextStyle _detailStyle(BuildContext context) => TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12);

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: context.tones.border, height: 1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          line,
          const SizedBox(width: 12),
          Flexible(
            flex: 6,
            child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11.5)),
          ),
          const SizedBox(width: 12),
          line,
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fill, required this.child, required this.left, this.border});

  final Color fill;
  final Widget child;
  final bool left;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(left ? 6 : 16),
          bottomRight: Radius.circular(left ? 16 : 6),
        ),
      ),
      child: child,
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, required this.showMeta});

  final Message message;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final fromCustomer = message.sender == 'customer';
    final fromBot = message.sender == 'bot';
    final fromAdmin = message.sender == 'admin';

    final fill = fromCustomer ? colors.surface : (fromBot ? tones.botBubble : tones.strongButton);
    final ink = fromCustomer ? colors.onSurface : (fromBot ? tones.botText : Colors.white);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Align(
      alignment: fromCustomer ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: fromCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canDeleteMessage(message)) _DeleteButton(message: message),
                Flexible(
                  child: _Bubble(
                    fill: fill,
                    left: fromCustomer,
                    child: Text(message.text, style: TextStyle(color: ink, fontSize: fromBot ? 13.5 : 14, height: 1.5)),
                  ),
                ),
              ],
            ),
            if (showMeta)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (fromBot) ...[
                      Icon(Icons.smart_toy_outlined, size: 12, color: tones.faint),
                      Text(' Auto-reply · ', style: TextStyle(color: tones.faint, fontSize: 11)),
                    ],
                    MessageTime(time: message.createdAt),
                    if (message.emailedTo != null) ...[
                      Text(' · ', style: TextStyle(color: tones.faint, fontSize: 11)),
                      Icon(Icons.mail_outline_rounded, size: 11, color: tones.faint),
                      Text(' emailed', style: TextStyle(color: tones.faint, fontSize: 11)),
                    ],
                    if (fromAdmin) ...[const SizedBox(width: 4), MessageTicks(message: message)],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeBubble extends StatelessWidget {
  const _CodeBubble({required this.message, required this.code});

  final Message message;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final header = code == null ? 'Code sent' : 'Code sent · $code';

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bubble(
              fill: context.tones.strongButton,
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(header, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                  Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [MessageTime(time: message.createdAt), const SizedBox(width: 4), MessageTicks(message: message)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return Align(
      alignment: Alignment.centerRight,
      child: _Bubble(
        fill: Colors.transparent,
        left: false,
        border: Border.all(color: tones.border),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 13, color: tones.faint),
            Flexible(
              child: Text(' You deleted this message · ', style: TextStyle(color: tones.faint, fontSize: 13, fontStyle: FontStyle.italic)),
            ),
            MessageTime(time: message.createdAt),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image, required this.title, required this.detail, this.alignRight = false, this.action});

  final String? image;
  final String title;
  final List<Widget> detail;
  final bool alignRight;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final path = image;
    final button = action;

    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ?button,
        Container(
          width: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (path != null)
                SizedBox(width: 220, height: 144, child: StoredImage(path: path))
              else
                SizedBox(
                  width: 220,
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 13, color: tones.faint),
                      Text(' Removed', style: TextStyle(color: tones.faint, fontSize: 12)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: detail),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showConfirmDialog(
        context,
        description: 'The customer will see “This message has been deleted”.',
        confirmLabel: 'Yes, delete',
        danger: true,
        onConfirm: () => ref.read(adminActionsProvider).deleteMessage(message),
      ),
      child: SizedBox(width: 32, height: 32, child: Icon(Icons.delete_outline_rounded, size: 16, color: context.tones.faint)),
    );
  }
}
