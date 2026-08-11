import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/supabase_config.dart';
import '../core/services/notification_service.dart';
import '../core/services/realtime_notification_service.dart';

const _buildSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _buildSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      debugPrint('⚠️ Warning: .env file not available - using build-time configuration');
    }

    final supabaseUrl = _buildSupabaseUrl.isNotEmpty
        ? _buildSupabaseUrl
        : dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = _buildSupabaseAnonKey.isNotEmpty
        ? _buildSupabaseAnonKey
        : dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty ||
        supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase credentials not found');
    }

    await SupabaseConfig.initializeWithCredentials(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

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
