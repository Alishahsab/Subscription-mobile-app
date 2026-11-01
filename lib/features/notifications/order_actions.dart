import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/code_rules.dart';

const alertsChannel = AndroidNotificationChannel(
  'admin_alerts',
  'Payments and support',
  description: 'New payments, payment problems and support requests',
  importance: Importance.high,
);

const approveAction = 'approve';
const rejectAction = 'reject';
const cancelAction = 'cancel';
const resolveAction = 'resolve';
const replyAction = 'reply';

const serverActions = {approveAction, cancelAction, resolveAction, replyAction};

String? alertKey(Map<String, dynamic> data) => (data['orderId'] ?? data['ticketId']) as String?;

int notificationIdFor(String key) => key.hashCode & 0x7fffffff;

AndroidNotificationDetails alertDetails({List<AndroidNotificationAction>? actions}) {
  return AndroidNotificationDetails(
    alertsChannel.id,
    alertsChannel.name,
    channelDescription: alertsChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    color: AppColors.gold,
    icon: '@drawable/ic_notification',
    actions: actions,
  );
}

const orderActions = [
  AndroidNotificationAction(
    approveAction,
    'Approve',
    inputs: [AndroidNotificationActionInput(label: 'Paste the code message')],
  ),
  AndroidNotificationAction(rejectAction, 'Reject', showsUserInterface: true),
  AndroidNotificationAction(cancelAction, 'Cancel order'),
];

const issueActions = [
  AndroidNotificationAction(resolveAction, 'Resolved'),
  AndroidNotificationAction(
    replyAction,
    'Reply',
    inputs: [AndroidNotificationActionInput(label: 'Type your reply')],
  ),
];

Future<void> showAlert(FlutterLocalNotificationsPlugin local, Map<String, dynamic> data, {String? title, String? body}) async {
  final key = alertKey(data);
  if (key == null) return;
  await local.show(
    id: notificationIdFor(key),
    title: title ?? data['title'] as String?,
    body: body ?? data['body'] as String?,
    notificationDetails: NotificationDetails(android: alertDetails(actions: data['orderId'] != null ? orderActions : issueActions)),
    payload: jsonEncode(data),
  );
}

const _results = {
  'approved': 'Approved. The code was sent to the customer.',
  'cancelled': 'Order cancelled. The customer was told.',
  'resolved': 'Marked as resolved. The customer was told.',
  'sent': 'Reply sent to the customer.',
  'already_done': 'This was already handled.',
  'missing': 'This no longer exists.',
};

const _retry = {
  'no_code': 'No code found in that message. Paste the full code message again.',
  'code_used': 'This code was already sent before. Paste a different code message.',
  'empty': 'The reply was empty. Type your reply again.',
};

@pragma('vm:entry-point')
Future<void> handleOrderActionInBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseKey);
  } catch (_) {}
  await handleOrderAction(FlutterLocalNotificationsPlugin(), response);
}

Future<void> handleOrderAction(FlutterLocalNotificationsPlugin local, NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null) return;
  final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
  final key = alertKey(data);
  if (key == null) return;

  String result;
  try {
    result = await _runOnServer(Supabase.instance.client, response, data);
  } catch (error) {
    debugPrint('Notification action failed: $error');
    await showAlert(local, data, title: 'Could not do that', body: 'Check the internet and try again, or open the app.');
    return;
  }

  final retry = _retry[result];
  if (retry != null) {
    await showAlert(local, data, body: retry);
    return;
  }
  await local.show(
    id: notificationIdFor(key),
    title: data['title'] as String?,
    body: _results[result] ?? 'Done.',
    notificationDetails: NotificationDetails(android: alertDetails()),
    payload: payload,
  );
}

Future<String> _runOnServer(SupabaseClient client, NotificationResponse response, Map<String, dynamic> data) async {
  final text = (response.input ?? '').trim();
  switch (response.actionId) {
    case approveAction:
      final code = findCode(text);
      if (text.isEmpty || code.isEmpty) return 'no_code';
      return await client.rpc('admin_approve_order', params: {'order_id': data['orderId'], 'code_message': text, 'code': code}) as String;
    case cancelAction:
      return await client.rpc('admin_cancel_order', params: {'order_id': data['orderId']}) as String;
    case resolveAction:
      return await client.rpc('admin_resolve_ticket', params: {'ticket_id': data['ticketId']}) as String;
    default:
      if (text.isEmpty) return 'empty';
      return await client.rpc('admin_reply', params: {'customer_id': data['customerId'], 'reply': text}) as String;
  }
}
