import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/app/router.dart';
import 'package:astshara/core/providers/theme_mode_provider.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';

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
          // The production controller initializes SharedPreferences asynchronously.
          // Override it in the widget test so the smoke test remains a pure Flutter
          // widget test and does not depend on platform plugins.
          themeModeProvider.overrideWith((ref) => ThemeMode.light),
          routerProvider.overrideWithValue(testRouter),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: const LawConnectApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(LawConnectApp), findsOneWidget);
  });
}
