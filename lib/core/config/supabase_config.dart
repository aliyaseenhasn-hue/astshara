import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url {
    final url = dotenv.env['SUPABASE_URL'] ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ??
        '';

    if (url.isEmpty) {
      debugPrint('❌ Error: SUPABASE_URL is not set');
    }
    return url;
  }

  static String get anonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ??
        '';

    if (key.isEmpty) {
      debugPrint('❌ Error: SUPABASE_ANON_KEY is not set');
    }
    return key;
  }

  static String get hfToken {
    final token = dotenv.env['HUGGING_FACE_TOKEN'] ?? '';
    if (token.isEmpty) {
      debugPrint('⚠️ Warning: HUGGING_FACE_TOKEN is not set');
    }
    return token;
  }

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('Supabase configuration is incomplete');
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      debugPrint('✅ Supabase initialized successfully');
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
