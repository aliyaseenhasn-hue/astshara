import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/core/config/supabase_config.dart';
import 'package:astshara/features/authentication/presentation/providers/auth_provider.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';

const _testSupabaseUrl = 'https://test.supabase.co';
// Syntactically valid, expired-independent JWT used only to construct an
// offline SupabaseClient. No request is made with this credential.
const _testSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjQ3MDAwMDAwMDB9.'
    'dGVzdC1zaWduYXR1cmU';

void main() {
  late SupabaseClient testClient;

  setUp(() {
    testClient = SupabaseClient(
      _testSupabaseUrl,
      _testSupabaseAnonKey,
    );
    SupabaseConfig.setTestClient(testClient);
  });

  tearDown(() {
    SupabaseConfig.clearTestClient();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Keep the smoke test fully offline and deterministic. The router
          // only needs to know that there is no authenticated user.
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: const LawConnectApp(),
      ),
    );

    // Allow the router's initial redirect and first frame to complete without
    // waiting for any real Supabase/network activity.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LawConnectApp), findsOneWidget);
  });
}
