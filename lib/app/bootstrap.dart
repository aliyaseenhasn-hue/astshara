import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/supabase_config.dart';
import '../core/services/notification_service.dart';
import '../core/services/realtime_notification_service.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('⚠️ Warning: .env file not found - $e');
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl != null && supabaseAnonKey != null) {
      await SupabaseConfig.initialize();
    } else {
      throw Exception('Supabase credentials not found');
    }

    try {
      await NotificationService.initialize();
      await RealtimeNotificationService().start();
    } catch (e) {
      debugPrint('⚠️ Warning: notification services unavailable: $e');
    }
  } catch (e) {
    debugPrint('🚨 Critical Bootstrap Error: $e');
    rethrow;
  }

  return ProviderContainer();
}
