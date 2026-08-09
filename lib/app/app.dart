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
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return MaterialApp.router(
      title: 'LawConnect',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
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
        final canShowGlobalChrome = authUser != null &&
            !isAuthRoute && !isAdminRoute && !isRestrictedRoute;
        final showGlobalBell = canShowGlobalChrome && location != '/';

        // شريط التنقل السفلي موجود حصراً داخل AppShell عبر ShellRoute.
        // لا نضيفه هنا مرة ثانية حتى لا يظهر مرتين في الواجهة.
        final content = child ?? const SizedBox.shrink();

        return Stack(
          children: [
            content,
            if (showGlobalBell)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 12,
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: Badge.count(
                    count: unread > 99 ? 99 : unread,
                    isLabelVisible: unread > 0,
                    backgroundColor: AppThemeNotificationColors.badge,
                    textColor: Colors.white,
                    child: IconButton(
                      tooltip: 'الإشعارات',
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: AppThemeNotificationColors.icon,
                      onPressed: () => router.push('/notifications'),
                    ),
                  ),
                ),
              ),
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

class AppThemeNotificationColors {
  static const badge = Color(0xFFD9A441);
  static const icon = Color(0xFF176B87);
}
