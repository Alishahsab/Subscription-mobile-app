const _pakistanOffset = 5 * Duration.millisecondsPerHour;
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _longWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

DateTime _pakistan(int time) => DateTime.fromMillisecondsSinceEpoch(time + _pakistanOffset, isUtc: true);

int pakistanDay(int time) => (time + _pakistanOffset) ~/ Duration.millisecondsPerDay;

int pakistanMinutesIntoDay(int time) {
  final date = _pakistan(time);
  return date.hour * 60 + date.minute;
}

String formatMoney(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return 'Rs $buffer';
}

String formatTime(int time) {
  final date = _pakistan(time);
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

String formatDate(int time) {
  final date = _pakistan(time);
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatDateTime(int time) => '${formatDate(time)}, ${formatTime(time)}';

String chatDayLabel(int time, int now) {
  final daysAgo = pakistanDay(now) - pakistanDay(time);
  if (daysAgo <= 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return _longWeekdays[_pakistan(time).weekday - 1];
  return formatDate(time);
}

String chatListTime(int time, int now) {
  final daysAgo = pakistanDay(now) - pakistanDay(time);
  if (daysAgo <= 0) return formatTime(time);
  if (daysAgo == 1) return 'Yesterday';

  final date = _pakistan(time);
  if (date.year == _pakistan(now).year) return '${date.day} ${_months[date.month - 1]}';
  return formatDate(time);
}

String timeAgo(int time, int now) {
  final seconds = (now - time) ~/ 1000;
  if (seconds < 45) return 'just now';

  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes < 1 ? 1 : minutes}m ago';

  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';

  final days = hours ~/ 24;
  if (days < 7) return '${days}d ago';

  return formatDate(time);
}

String shortWeekday(DateTime date) => _weekdays[date.weekday - 1];
