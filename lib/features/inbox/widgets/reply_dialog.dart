import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/picked_image.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/repositories/image_repository.dart';

const _maxAttachments = 3;
const _maxLength = 1000;

Future<void> showReplyDialog(BuildContext context, String customerId) {
  return showDialog<void>(context: context, builder: (context) => _ReplyDialog(customerId: customerId));
}

class _ReplyDialog extends ConsumerStatefulWidget {
  const _ReplyDialog({required this.customerId});

  final String customerId;

  @override
  ConsumerState<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends ConsumerState<_ReplyDialog> {
  final _attachments = <PickedImage>[];
  String _text = '';
  String _error = '';
  bool _busy = false;

  Future<void> _addImage() async {
    try {
      final image = await pickImageFromGallery();
      if (image != null) setState(() => _attachments.add(image));
    } catch (_) {
      setState(() => _error = "This picture couldn't be opened.");
    }
  }

  Future<void> _send() async {
    final text = _text.trim();
    setState(() {
      _busy = true;
      _error = '';
    });

    final actions = ref.read(adminActionsProvider);
    final images = ref.read(imageRepositoryProvider);
    if (text.isNotEmpty) actions.sendMessage(widget.customerId, text, ticketReply: true);

    try {
      for (final attachment in _attachments) {
        final path = await images.upload(widget.customerId, attachment.bytes, png: attachment.png);
        actions.sendImage(widget.customerId, path, ticketReply: true);
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Could not upload the image. Please try again.';
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final canSend = !_busy && (_text.trim().isNotEmpty || _attachments.isNotEmpty);

    return AlertDialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      title: const Text('Reply'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a message, attach images, or both.'),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxLength,
            onChanged: (value) => setState(() => _text = value),
            decoration: const InputDecoration(hintText: 'Type your reply', border: OutlineInputBorder()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attachment in _attachments)
                _AttachmentThumb(bytes: attachment.bytes, onRemove: () => setState(() => _attachments.remove(attachment))),
              if (_attachments.length < _maxAttachments)
                GestureDetector(
                  onTap: _addImage,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: tones.border)),
                    child: Icon(Icons.add_photo_alternate_outlined, color: tones.faint, size: 20),
                  ),
                ),
            ],
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error, style: TextStyle(color: tones.redText, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: canSend ? _send : null, child: Text(_busy ? 'Sending…' : 'Send reply')),
      ],
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover)),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(radius: 10, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
