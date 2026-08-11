import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/core/config/supabase_config.dart';
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
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: const LawConnectApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(LawConnectApp), findsOneWidget);
  });
}
