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
          // StateNotifierProvider requires its override factory to return the
          // notifier, not the state value. Keep the production controller so
          // the test uses the same provider type as the application.
          themeModeProvider.overrideWith((ref) => ThemeModeController()),
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
