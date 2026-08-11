import 'package:flutter/material.dart';
import 'main_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int get currentIndex {
    if (location == '/app-settings' ||
        location == '/profile' ||
        location == '/notification-settings' ||
        location == '/payment-methods' ||
        location == '/help-center') {
      return 4;
    }
    if (location == '/notifications') return 3;
    if (location == '/bookings' ||
        location == '/booking-details' ||
        location == '/manual-payment' ||
        location == '/manual-payment-required' ||
        location == '/upload-payment' ||
        location == '/payment-result' ||
        location == '/chats' ||
        location.startsWith('/chat/')) {
      return 2;
    }
    if (location == '/lawyers' || location.startsWith('/lawyer-details/')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: ColoredBox(
        color: scheme.surface,
        child: child,
      ),
      bottomNavigationBar: MainBottomNav(currentIndex: currentIndex),
    );
  }
}
