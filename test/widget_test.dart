import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:astshara/app/app.dart';
import 'package:astshara/features/profile/presentation/providers/notifications_provider.dart';

String _testSupabaseAnonKey() {
  // Supabase validates the anon key format during initialization. Keep the
  // smoke test completely offline by supplying a syntactically valid JWT; no
  // request is ever made with this key.
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'role': 'anon',
    'iss': 'supabase',
    'exp': DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/
        1000,
  });

  return '$header.$payload.test-signature';
}

void main() {
  setUpAll(() async {
    // The production app initializes Supabase in main(). A widget test does not
    // run main(), so initialize an isolated client explicitly. The credentials
    // are deliberately fake and the test never performs network requests.
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: _testSupabaseAnonKey(),
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
