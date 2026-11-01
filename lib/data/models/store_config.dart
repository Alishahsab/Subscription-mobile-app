import '../../core/utils/format.dart';
import 'db_row.dart';
import 'default_settings.dart';

class StoreConfig {
  const StoreConfig({required this.settings, required this.plans, required this.methods, required this.faqs});

  final DbRow settings;
  final List<dynamic> plans;
  final List<dynamic> methods;
  final List<dynamic> faqs;

  factory StoreConfig.fromRow(DbRow row) {
    return StoreConfig(
      settings: mergeSettings(row['settings'] as DbRow),
      plans: row['plans'] as List<dynamic>,
      methods: row['methods'] as List<dynamic>,
      faqs: row['faqs'] as List<dynamic>,
    );
  }

  DbRow toRow() => {'id': 1, 'settings': settings, 'plans': plans, 'methods': methods, 'faqs': faqs};

  DbRow _group(String name) => settings[name] as DbRow? ?? const {};

  int get inactiveMinutes => _group('timers')['inactiveMinutes'] as int? ?? 20;

  List<String> get rejectReasons => (settings['rejectReasons'] as List<dynamic>? ?? const []).cast<String>();

  List<String> get quickReplies {
    final replies = (settings['quickReplies'] as List<dynamic>? ?? const []).cast<String>();
    return replies.where((reply) => reply.trim().isNotEmpty).toList();
  }

  List<String> get blockReasons => (_group('blocking')['reasons'] as List<dynamic>? ?? const []).cast<String>();

  String get rejectionMessage {
    return settings['rejectionMessage'] as String? ??
        "We couldn't verify the payment for order {order_id}. Reason: {reason}.\nIf you think this is a mistake, describe your side below and attach a screenshot.";
  }

  String get blockMessage => _group('blocking')['message'] as String? ?? 'Your access has been restricted. Please contact us by email.';

  String get unblockMessage => _group('blocking')['unblockMessage'] as String? ?? 'Your access has been restored. You can use the chat again.';

  String botMessage(String key, String fallback) => _group('messages')[key] as String? ?? fallback;

  List<Map<String, String>> get inboxTabs {
    return mergeInboxTabs(settings['inboxTabs'] as List<dynamic>?);
  }

  String effectiveStatus(int now) {
    final status = settings['status'] as String? ?? 'active';
    if (status == 'offline') return 'offline';

    final hours = _group('hours');
    if (hours['enforce'] == true && !_withinHours(hours, now)) return 'offline';
    return status;
  }

  bool _withinHours(DbRow hours, int now) {
    final current = pakistanMinutesIntoDay(now);
    final start = _minutes(hours['start'] as String);
    final end = _minutes(hours['end'] as String);
    if (start <= end) return current >= start && current < end;
    return current >= start || current < end;
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }
}
