import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  // تمهيد التطبيق (إعداد Supabase وخدمات التخزين)
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LawConnectApp(),
    ),
  );
}
