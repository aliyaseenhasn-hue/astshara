import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/providers/global_loading_provider.dart';
import '../features/profile/presentation/providers/notifications_provider.dart';
import 'router.dart';
import 'theme.dart';

class LawConnectApp extends ConsumerWidget {
  const LawConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isLoading = ref.watch(globalLoadingProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Keep the notification provider alive for the existing badge/realtime flow.
    ref.watch(unreadNotificationsCountProvider);

    return MaterialApp.router(
      title: 'LawConnect',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
      ),
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final location = router.routerDelegate.currentConfiguration.uri.path;
        final authUser = SupabaseConfig.client.auth.currentUser;
        final isAuthRoute = location == '/login' ||
            location == '/admin-login' ||
            location == '/signup' ||
            location == '/otp' ||
            location == '/complete-profile' ||
            location == '/lawyer-onboarding';
        final isAdminRoute = location.startsWith('/admin');
        final isRestrictedRoute = location == '/lawyer-pending' ||
            location == '/manual-payment-required' ||
            location == '/manual-payment';
        final canShowGlobalChrome = authUser != null && !isAuthRoute && !isAdminRoute && !isRestrictedRoute;

        // التنبيهات وشريط التنقل ملك للصفحات/AppShell وفق Stitch.
        // لا نضيف جرساً عاماً فوق الصفحة حتى لا يتكرر مع رؤوس الصفحات.
        final content = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            content,
            if (isRestrictedRoute && canShowGlobalChrome)
              const SizedBox.shrink(),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: LoadingWidget(size: 60)),
                ),
              ),
          ],
        );
      },
    );
  }
}
