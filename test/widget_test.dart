import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/app/router.dart';
import 'package:astshara/core/providers/theme_mode_provider.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';
import 'package:astshara/shared/providers/global_loading_provider.dart';

class _TestThemeModeController extends StateNotifier<ThemeMode> {
  _TestThemeModeController() : super(ThemeMode.light);
}

class _TestGlobalLoading extends GlobalLoading {
  @override
  bool build() => false;
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final testRouter = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    addTearDown(testRouter.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Keep the smoke test completely independent from platform storage.
          themeModeProvider.overrideWith(
            (ref) => _TestThemeModeController(),
          ),
          // Prevent any real application loading state from entering the test.
          globalLoadingProvider.overrideWith(
            () => _TestGlobalLoading(),
          ),
          // Keep authentication/navigation and notifications out of the test.
          routerProvider.overrideWithValue(testRouter),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: const LawConnectApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(LawConnectApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
