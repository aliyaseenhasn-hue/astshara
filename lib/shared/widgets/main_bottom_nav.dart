import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// الشريط السفلي الرئيسي للتطبيق وفق بنية Stitch.
/// يجب أن يوجد في AppShell فقط حتى لا تتكرر عناصر التنقل داخل الصفحات.
class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'المحامون'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month_rounded), label: 'استشاراتي'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), activeIcon: Icon(Icons.notifications_rounded), label: 'التنبيهات'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.secondaryDark : AppColors.surface;
    final selected = isDark ? AppColors.gold : AppColors.goldDark;
    final unselected = isDark ? AppColors.primaryLight.withValues(alpha: .72) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.outline)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? .18 : .06), blurRadius: 14, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: background,
          selectedItemColor: selected,
          unselectedItemColor: unselected,
          currentIndex: currentIndex.clamp(0, _items.length - 1).toInt(),
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: _items,
          onTap: (index) => _navigate(context, index),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final target = switch (index) {
      0 => '/',
      1 => '/lawyers',
      2 => '/bookings',
      3 => '/notifications',
      4 => '/app-settings',
      _ => '/',
    };
    if (GoRouterState.of(context).uri.path != target) context.go(target);
  }
}
