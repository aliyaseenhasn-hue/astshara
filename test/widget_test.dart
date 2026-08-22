import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/app/router.dart';
import 'package:astshara/core/providers/theme_mode_provider.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';
import 'package:astshara/shared/providers/global_loading_provider.dart';

class _TestThemeModeController extends ThemeModeController {
  _TestThemeModeController() : super();
}

class _TestGlobalLoading extends GlobalLoading {
  @override
  bool build() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});

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

    FlutterErrorDetails? capturedError;
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      capturedError = details;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(
            (ref) => _TestThemeModeController(),
          ),
          globalLoadingProvider.overrideWith(
            () => _TestGlobalLoading(),
          ),
          routerProvider.overrideWithValue(testRouter),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: const LawConnectApp(),
      ),
    );

    await tester.pump();

    final frameworkException = tester.takeException();
    if (frameworkException != null) {
      fail('LawConnectApp smoke test threw: $frameworkException');
    }
    if (capturedError != null) {
      fail(
        'LawConnectApp emitted FlutterError: '
        '${capturedError!.exception}\n${capturedError!.stack}',
      );
    }

    expect(find.byType(LawConnectApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
