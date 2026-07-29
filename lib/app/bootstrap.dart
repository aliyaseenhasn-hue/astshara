import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/supabase_config.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة
  await dotenv.load(fileName: ".env");

  // تهيئة Supabase
  await SupabaseConfig.initialize();

  final container = ProviderContainer(
    overrides: [],
    observers: [],
  );

  return container;
}
