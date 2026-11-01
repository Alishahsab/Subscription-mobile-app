import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/picked_image.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/repositories/image_repository.dart';
import '../../../data/sync/data_notifier.dart';

const _maxLength = 1000;

class ReplyBox extends ConsumerStatefulWidget {
  const ReplyBox({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<ReplyBox> createState() => _ReplyBoxState();
}

class _ReplyBoxState extends ConsumerState<ReplyBox> {
  final _controller = TextEditingController();
  bool _showQuickReplies = false;
  bool _uploading = false;
  String _imageError = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    final content = text.trim();
    if (content.isEmpty) return;

    ref.read(adminActionsProvider).sendMessage(widget.customerId, content);
    _controller.clear();
    setState(() => _showQuickReplies = false);
  }

  Future<void> _sendImage() async {
    PickedImage? image;
    try {
      image = await pickImageFromGallery();
    } catch (_) {
      setState(() => _imageError = "This picture couldn't be opened.");
      return;
    }
    if (image == null) return;

    setState(() {
      _uploading = true;
      _imageError = '';
    });

    try {
      final path = await ref.read(imageRepositoryProvider).upload(widget.customerId, image.bytes, png: image.png);
      ref.read(adminActionsProvider).sendImage(widget.customerId, path);
    } catch (_) {
      if (mounted) setState(() => _imageError = 'Could not upload the image. Please try again.');
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final quickReplies = ref.watch(dataProvider).config?.quickReplies ?? const <String>[];
    final canSend = _controller.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: tones.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showQuickReplies)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final reply in quickReplies) _QuickReply(text: reply, onTap: () => _send(reply))],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: tones.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tones.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 8,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _uploading ? 'Sending image…' : 'Type a message or code…',
                    hintStyle: TextStyle(color: tones.faint, fontSize: 14),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  child: Row(
                    children: [
                      _ToolButton(
                        icon: Icons.chat_outlined,
                        active: _showQuickReplies,
                        onTap: () => setState(() => _showQuickReplies = !_showQuickReplies),
                      ),
                      _ToolButton(icon: Icons.add_photo_alternate_outlined, onTap: _uploading ? null : _sendImage),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: tones.strongButton,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: canSend ? () => _send(_controller.text) : null,
                        child: const Text('Send', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_imageError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_imageError, style: TextStyle(color: tones.redText, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: active ? tones.strongButton : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 17, color: active ? Colors.white : tones.faint),
      ),
    );
  }
}

class _QuickReply extends StatelessWidget {
  const _QuickReply({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: context.tones.border)),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12.5)),
      ),
    );
  }
}
