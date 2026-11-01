enum BadgeTone { green, amber, red, blue, gray }

class InboxItem {
  const InboxItem({
    required this.key,
    required this.customerId,
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.time,
    this.unread = false,
    this.badge,
    this.badgeTone = BadgeTone.gray,
  });

  final String key;
  final String customerId;
  final String title;
  final String tag;
  final String subtitle;
  final int time;
  final bool unread;
  final String? badge;
  final BadgeTone badgeTone;
}
