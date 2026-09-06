import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/supabase_config.dart';
import 'notification_service.dart';

/// Handles native FCM registration while preserving the existing Supabase
/// Realtime notification channel and the existing web/PWA push flow.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    await Firebase.initializeApp();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM notification permission denied');
      return;
    }

    _initialized = true;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      unawaited(
        NotificationService.showNotification(
          title: notification.title ?? 'إشعار جديد',
          body: notification.body ?? '',
          payload: _notificationPayload(message),
        ),
      );
    });

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(NotificationService.handleExternalPayload(
        _notificationPayload(message),
      )),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(NotificationService.handleExternalPayload(
        _notificationPayload(initialMessage),
      ));
    }

    await _registerToken(await _messaging.getToken());

    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });
  }

  static String _notificationPayload(RemoteMessage message) {
    final notificationId = message.data['notification_id'] ?? message.data['id'];
    if (notificationId != null) return notificationId.toString();
    return message.data['payload']?.toString() ?? '';
  }

  static Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();
    final profileId = profile?['id']?.toString();
    if (profileId == null) return;

    await SupabaseConfig.client.from('push_device_tokens').upsert(
      {
        'user_id': profileId,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  static Future<void> refreshForCurrentUser() async {
    if (kIsWeb || !_initialized) return;
    await _registerToken(await _messaging.getToken());
  }

  static Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _initialized = false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by the operating system while the
  // app is backgrounded/terminated. Keep this handler lightweight.
}
