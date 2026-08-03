import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/supabase_config.dart';
import '../core/services/notification_service.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تحميل ملف البيئة مع معالجة الخطأ إذا لم يجد الملف
    await dotenv
        .load(fileName: ".env")
        .catchError((e) => debugPrint('Warning: .env file not found'));

    // تهيئة Supabase فقط إذا كانت القيم موجودة
    if (dotenv.env['SUPABASE_URL'] != null &&
        dotenv.env['SUPABASE_ANON_KEY'] != null) {
      await SupabaseConfig.initialize();
    } else {
      debugPrint('Error: Supabase credentials missing in .env');
    }

    // تهيئة خدمة الإشعارات المحلية
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Bootstrap Error: $e');
  }

  final container = ProviderContainer(
    overrides: [],
    observers: [],
  );

  return container;
}
