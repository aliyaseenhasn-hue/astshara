import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/services/fcm_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/realtime_notification_service.dart';

const _buildSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _buildSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// Supabase publishable/anon keys are safe to embed in a client application.
// Build-time values always take precedence; these defaults keep direct web
// deployments (for example Cloudflare Pages) from failing before runApp().
const _publicSupabaseUrl = 'https://iidxqrnrazkyfgzelzhb.supabase.co';
const _publicSupabaseAnonKey = 'sb_publishable_LX3dMTuEV3WKxXVEjdaDNw_O3BK-gCa';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Only critical local/bootstrap work is awaited here. Optional services
    // must never block runApp(), otherwise a slow network request can leave
    // Flutter Web showing only the HTML background indefinitely.
    await Hive.initFlutter();
    await Hive.openBox('app_cache');

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      debugPrint('⚠️ .env not available; using build-time/public client configuration');
    }

    final supabaseUrl = _buildSupabaseUrl.isNotEmpty
        ? _buildSupabaseUrl
        : (dotenv.env['SUPABASE_URL']?.isNotEmpty == true
            ? dotenv.env['SUPABASE_URL']!
            : _publicSupabaseUrl);
    final supabaseAnonKey = _buildSupabaseAnonKey.isNotEmpty
        ? _buildSupabaseAnonKey
        : (dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true
            ? dotenv.env['SUPABASE_ANON_KEY']!
            : _publicSupabaseAnonKey);

    await SupabaseConfig.initializeWithCredentials(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // These services are intentionally started after bootstrap has completed.
    // Realtime/FCM startup must never block the Flutter tree on network or
    // platform configuration that may not have been supplied yet.
    unawaited(
      NotificationService.initialize().catchError((error, stackTrace) {
        debugPrint('⚠️ Notification services unavailable: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );

    unawaited(
      FcmService.instance.initialize().catchError((error, stackTrace) {
        debugPrint('⚠️ FCM unavailable: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );

    final realtimeService = RealtimeNotificationService();
    unawaited(
      realtimeService.start().catchError((error, stackTrace) {
        debugPrint('⚠️ Realtime notifications unavailable: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
  } catch (e, stackTrace) {
    debugPrint('🚨 Critical Bootstrap Error: $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  return ProviderContainer();
}
