import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../config/supabase_config.dart';

@JS('astsharaEnablePush')
external JSPromise<JSString?> _enablePush(JSString vapidPublicKey);

@JS('astsharaDisablePush')
external JSPromise<JSBoolean> _disablePush();

@JS('astsharaGetPushState')
external JSPromise<JSString> _getPushState();

class PwaNotificationService {
  static const String _vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  static bool get supported => _vapidPublicKey.isNotEmpty;

  static Future<bool> isEnabled() async {
    if (!supported) return false;
    try {
      final state = jsonDecode((await _getPushState().toDart).toDart) as Map<String, dynamic>;
      return state['permission'] == 'granted' && state['subscribed'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enable() async {
    if (!supported) return false;

    try {
      final result = await _enablePush(_vapidPublicKey.toJS).toDart;
      if (result == null) return false;

      final decoded = jsonDecode(result.toDart) as Map<String, dynamic>;
      final subscription = Map<String, dynamic>.from(decoded);
      final rawKeys = subscription['keys'];
      if (subscription['endpoint'] is! String || rawKeys is! Map) return false;
      final keys = Map<String, dynamic>.from(rawKeys);
      if (keys['p256dh'] is! String || keys['auth'] is! String) return false;

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return false;

      await SupabaseConfig.client.from('pwa_push_subscriptions').upsert(
        <String, dynamic>{
          'user_id': user.id,
          'endpoint': subscription['endpoint'],
          'p256dh': keys['p256dh'],
          'auth': keys['auth'],
          'user_agent': web.window.navigator.userAgent,
        },
        onConflict: 'user_id,endpoint',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> disable() async {
    try {
      await _disablePush().toDart;
    } catch (_) {
      // Continue with database cleanup even if the browser subscription is unavailable.
    }

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return false;

    try {
      await SupabaseConfig.client
          .from('pwa_push_subscriptions')
          .delete()
          .eq('user_id', user.id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
