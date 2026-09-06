import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/supabase_config.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging integration for native mobile platforms.
///
/// Firebase configuration is intentionally supplied outside source control.
/// If it is not available yet, FCM is disabled without affecting app startup.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();
  bool _enabled = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_enabled) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _enabled = true;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await _requestPermission(messaging);

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
        NotificationService.handleForegroundRemoteMessage,
      );
      _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        NotificationService.handleRemoteMessageTap,
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.handleRemoteMessageTap(initialMessage);
        });
      }

      await _registerToken(messaging);
      _tokenSubscription ??= messaging.onTokenRefresh.listen(_persistToken);
    } catch (error, stackTrace) {
      _enabled = false;
      debugPrint('⚠️ FCM unavailable until Firebase configuration is installed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM authorization status: ${settings.authorizationStatus}');
  }

  Future<void> _registerToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _persistToken(token);
    }
  }

  Future<void> _persistToken(String token) async {
    if (!_enabled || token.trim().isEmpty) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();
      final profileId = profile?['id']?.toString();
      if (profileId == null || profileId.isEmpty) return;

      await SupabaseConfig.client.from('device_push_tokens').upsert(
        {
          'user_id': profileId,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
    } catch (error, stackTrace) {
      debugPrint('⚠️ Unable to persist FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    // Notification payloads are displayed by Android/iOS system UI while the
    // app is backgrounded or terminated. Data-only handling can be extended
    // here later without adding secrets to the client.
    debugPrint('FCM background message received: ${message.messageId}');
  } catch (error, stackTrace) {
    debugPrint('⚠️ FCM background handler unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
