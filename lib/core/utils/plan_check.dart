import '../../data/models/order.dart';

final _durationPattern = RegExp(r'(\d+)\s*-?\s*(months?|mon|years?|yr)\b', caseSensitive: false);

Set<int> _mentionedMonths(String text) {
  return _durationPattern.allMatches(text).map((match) {
    final count = int.parse(match.group(1)!);
    return match.group(2)!.toLowerCase().startsWith('y') ? count * 12 : count;
  }).toSet();
}

int? planMonths(String planName) {
  final months = _mentionedMonths(planName);
  return months.length == 1 ? months.first : null;
}

String _monthsLabel(int months) => '$months Month${months == 1 ? '' : 's'}';

String? planMismatch(String text, String planName) {
  final plan = _mentionedMonths(planName);
  if (plan.length != 1) return null;

  final wrong = _mentionedMonths(text).where((months) => months != plan.first);
  if (wrong.isEmpty) return null;
  return 'This order is for $planName, but your message says ${_monthsLabel(wrong.first)}. Please check the code before sending.';
}

Order? orderWaitingForCode(List<Order> orders, String customerId) {
  final waiting = orders.where((order) => order.customerId == customerId && (order.status == 'pending_review' || order.status == 'rejected')).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return waiting.isEmpty ? null : waiting.first;
}
