import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../config/supabase_config.dart';

@JS('astsharaEnablePush')
external JSPromise<JSString?> _enablePush(JSString vapidPublicKey);

@JS('astsharaDisablePush')
external JSAny? _disablePush();

class PwaNotificationService {
  static const String _vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  static bool get supported => _vapidPublicKey.isNotEmpty;

  static Future<bool> enable() async {
    if (!supported) return false;

    final result = await _enablePush(_vapidPublicKey.toJS).toDart;
    if (result == null) return false;

    final decoded = jsonDecode(result.toDart) as Map<String, dynamic>;
    final subscription = Map<String, dynamic>.from(decoded);
    final keys = Map<String, dynamic>.from(subscription['keys'] as Map);
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
  }

  static Future<bool> disable() async {
    try {
      _disablePush();
    } catch (_) {
      // The browser subscription can still be removed from Supabase below.
    }

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return false;

    await SupabaseConfig.client
        .from('pwa_push_subscriptions')
        .delete()
        .eq('user_id', user.id);
    return true;
  }
}
