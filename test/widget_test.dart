import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';

void main() {
  setUpAll(() async {
    // The production app initializes Supabase in main(). A widget test does not
    // run main(), so initialize an isolated client explicitly to keep the smoke
    // test deterministic and independent from production credentials/network.
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
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
