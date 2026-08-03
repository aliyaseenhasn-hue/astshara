import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/supabase_config.dart';
import '../core/services/notification_service.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تحميل ملف البيئة مع معالجة الخطأ إذا لم يجد الملف
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ Warning: .env file not found - $e');
    }

    // تهيئة Supabase فقط إذا كانت القيم موجودة
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl != null && supabaseAnonKey != null) {
      try {
        await SupabaseConfig.initialize();
        debugPrint('✅ Supabase initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing Supabase: $e');
        rethrow;
      }
    } else {
      debugPrint('❌ Error: Supabase credentials missing in .env');
      throw Exception('Supabase credentials not found');
    }

    // تهيئة خدمة الإشعارات المحلية
    try {
      await NotificationService.initialize();
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Warning: Failed to initialize notification service: $e');
      // لا نوقف التطبيق إذا فشلت خدمة الإشعارات
    }
  } catch (e) {
    debugPrint('🚨 Critical Bootstrap Error: $e');
    rethrow;
  }

  final container = ProviderContainer(
    overrides: [],
    observers: [],
  );

  return container;
}
