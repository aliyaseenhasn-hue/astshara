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
          // StateNotifierProvider exposes ThemeMode as its state. Override the
          // state directly so the test never constructs ThemeModeController,
          // which initializes SharedPreferences through a platform plugin.
          themeModeProvider.overrideWithValue(ThemeMode.light),
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
