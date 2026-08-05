import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/providers/global_loading_provider.dart';
import 'router.dart';
import 'theme.dart';

class LawConnectApp extends ConsumerWidget {
  const LawConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isLoading = ref.watch(globalLoadingProvider);

    return MaterialApp.router(
      title: 'LawConnect',
      debugShowCheckedModeBanner: false,

      // إعدادات اللغة والاتجاه (RTL)
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // إعدادات الثيم (Material 3)
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // إعدادات التنقل
      routerConfig: router,

      // إضافة طبقة التحميل العالمية فوق جميع الصفحات
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: LoadingWidget(size: 60),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
