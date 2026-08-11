import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/core/config/supabase_config.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';

void main() {
  late SupabaseClient testClient;

  setUp(() {
    testClient = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
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
