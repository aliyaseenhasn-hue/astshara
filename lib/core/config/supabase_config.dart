import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url =>
      dotenv.env['SUPABASE_URL'] ??
      dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ??
      '';

  static String get anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ??
      dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ??
      '';

  static String get hfToken => dotenv.env['HUGGING_FACE_TOKEN'] ?? '';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
