import 'package:flutter/material.dart';
import 'main_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int get currentIndex {
    if (location == '/app-settings' ||
        location == '/profile' ||
        location == '/notifications' ||
        location == '/notification-settings' ||
        location == '/payment-methods' ||
        location == '/help-center') {
      return 3;
    }
    if (location == '/chats' || location.startsWith('/chat/')) return 2;
    if (location == '/bookings' ||
        location == '/booking-details' ||
        location == '/manual-payment' ||
        location == '/manual-payment-required' ||
        location == '/upload-payment' ||
        location == '/payment-result') {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MainBottomNav(currentIndex: currentIndex),
    );
  }
}
