import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _nextPublicSupabaseUrl =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL');
  static const _supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _nextPublicSupabasePublishableKey =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
  static const _nextPublicSupabaseAnonKey =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_ANON_KEY');

  static String get url {
    final url = _supabaseUrl.isNotEmpty
        ? _supabaseUrl
        : _nextPublicSupabaseUrl.isNotEmpty
            ? _nextPublicSupabaseUrl
            : dotenv.env['SUPABASE_URL'] ??
                dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ??
                '';

    if (url.isEmpty) {
      debugPrint('❌ Error: SUPABASE_URL is not set');
    }
    return url;
  }

  static String get publishableKey {
    final key = _supabasePublishableKey.isNotEmpty
        ? _supabasePublishableKey
        : _supabaseAnonKey.isNotEmpty
            ? _supabaseAnonKey
            : _nextPublicSupabasePublishableKey.isNotEmpty
                ? _nextPublicSupabasePublishableKey
                : _nextPublicSupabaseAnonKey.isNotEmpty
                    ? _nextPublicSupabaseAnonKey
                    : dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
                        dotenv.env['SUPABASE_ANON_KEY'] ??
                        dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ??
                        dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ??
                        '';

    if (key.isEmpty) {
      debugPrint(
        '❌ Error: SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY is not set',
      );
    }
    return key;
  }

  static bool get hasRequiredConfig =>
      url.isNotEmpty && publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!hasRequiredConfig) {
      throw Exception('Supabase configuration is incomplete');
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: publishableKey,
        authFlowType: AuthFlowType.pkce,
      );
      debugPrint('✅ Supabase initialized successfully (using anonKey)');
    } catch (e) {
      debugPrint('❌ Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('❌ Error getting Supabase client: $e');
      rethrow;
    }
  }
}
