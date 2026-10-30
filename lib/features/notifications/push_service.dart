// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_actions.dart';

typedef PushTarget = Map<String, dynamic>;

class PushService {
  PushService._();

  static final instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  ValueChanged<PushTarget>? _onOpen;
  PushTarget? _waiting;
  StreamSubscription<String>? _tokenChanges;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> init() async {
    if (!_supported) return;
    try {
      await Firebase.initializeApp();
      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')),
        onDidReceiveNotificationResponse: _respond,
        onDidReceiveBackgroundNotificationResponse: handleOrderActionInBackground,
      );
      await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(alertsChannel);

      FirebaseMessaging.onBackgroundMessage(showAlertInBackground);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _open(message.data));
      final first = await FirebaseMessaging.instance.getInitialMessage();
      if (first != null) _open(first.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      final launchResponse = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && launchResponse != null) _respond(launchResponse);
      _ready = true;
    } catch (error) {
      debugPrint('Notifications are off: $error');
    }
  }

  void listen(ValueChanged<PushTarget> onOpen) {
    _onOpen = onOpen;
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null) onOpen(waiting);
  }

  void stopListening() => _onOpen = null;

  Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
      _tokenChanges ??= messaging.onTokenRefresh.listen(_saveToken);
    } catch (error) {
      debugPrint('Could not register for notifications: $error');
    }
  }

  Future<void> unregisterDevice() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _client.from('admin_devices').delete().eq('token', token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Could not remove this phone from notifications: $error');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('admin_devices').upsert({
      'token': token,
      'user_id': userId,
      'platform': 'android',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _respond(NotificationResponse response) {
    if (serverActions.contains(response.actionId)) {
      handleOrderAction(_local, response);
      return;
    }
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    if (response.actionId == rejectAction) {
      _open({'section': 'inbox', 'tab': 'pending', 'rejectOrderId': data['orderId']});
      return;
    }
    _open(data);
  }

  void _open(PushTarget data) {
    final onOpen = _onOpen;
    if (onOpen == null) {
      _waiting = data;
    } else {
      onOpen(data);
    }
  }
}

@pragma('vm:entry-point')
Future<void> showAlertInBackground(RemoteMessage message) async {
  if (alertKey(message.data) == null) return;
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')),
    onDidReceiveBackgroundNotificationResponse: handleOrderActionInBackground,
  );
  await showAlert(local, message.data);
}
