import '../../../core/utils/format.dart';
import '../../../data/models/message.dart';

const _groupGap = 5 * Duration.millisecondsPerMinute;

bool endsGroup(Message message, Message? next) {
  if (next == null) return true;
  final longGap = next.createdAt - message.createdAt > _groupGap;
  return next.sender != message.sender || longGap || pakistanDay(next.createdAt) != pakistanDay(message.createdAt);
}

bool startsDay(Message message, Message? previous) {
  return previous == null || pakistanDay(previous.createdAt) != pakistanDay(message.createdAt);
}
