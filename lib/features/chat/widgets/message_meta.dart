import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/message.dart';

const _seenColor = Color(0xFF0EA5E9);

class MessageTime extends StatefulWidget {
  const MessageTime({super.key, required this.time});

  final int time;

  @override
  State<MessageTime> createState() => _MessageTimeState();
}

class _MessageTimeState extends State<MessageTime> {
  bool _showDate = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showDate = !_showDate),
      child: Text(
        _showDate ? formatDateTime(widget.time) : formatTime(widget.time),
        style: TextStyle(color: context.tones.faint, fontSize: 11),
      ),
    );
  }
}

class MessageTicks extends StatelessWidget {
  const MessageTicks({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final delivered = message.deliveredAt != null;
    final seen = message.seenAt != null;

    return Icon(
      seen || delivered ? Icons.done_all_rounded : Icons.check_rounded,
      size: 14,
      color: seen ? _seenColor : context.tones.faint,
    );
  }
}
