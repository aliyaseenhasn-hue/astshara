import 'dart:convert';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

import '../config/supabase_config.dart';

class PwaNotificationService {
  static const String _vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  static bool get supported =>
      html.window.navigator.serviceWorker != null &&
      html.Notification.supported;

  static Future<bool> enable() async {
    if (!supported || _vapidPublicKey.isEmpty) return false;

    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod<Object?>(
        html.window,
        'astsharaEnablePush',
        <Object?>[_vapidPublicKey],
      ),
    );

    if (result == null) return false;
    final subscription = jsonDecode(result.toString()) as Map<String, dynamic>;
    final keys = Map<String, dynamic>.from(subscription['keys'] as Map);

    await SupabaseConfig.client.from('pwa_push_subscriptions').upsert(
      <String, dynamic>{
        'user_id': SupabaseConfig.client.auth.currentUser!.id,
        'endpoint': subscription['endpoint'],
        'p256dh': keys['p256dh'],
        'auth': keys['auth'],
        'user_agent': html.window.navigator.userAgent,
      },
      onConflict: 'user_id,endpoint',
    );

    return true;
  }

  static Future<void> disable() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    await SupabaseConfig.client
        .from('pwa_push_subscriptions')
        .delete()
        .eq('user_id', user.id);
  }
}
