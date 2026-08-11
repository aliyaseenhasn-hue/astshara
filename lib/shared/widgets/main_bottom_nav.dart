import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/presentation/providers/notifications_provider.dart';

/// الشريط السفلي الرئيسي للتطبيق وفق بنية Stitch.
/// يجب أن يوجد في AppShell فقط حتى لا تتكرر عناصر التنقل داخل الصفحات.
class MainBottomNav extends ConsumerWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'الرئيسية',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline_rounded),
      activeIcon: Icon(Icons.people_rounded),
      label: 'المحامون',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      activeIcon: Icon(Icons.calendar_month_rounded),
      label: 'استشاراتي',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications_none_rounded),
      activeIcon: Icon(Icons.notifications_rounded),
      label: 'التنبيهات',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings_rounded),
      label: 'الإعدادات',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final background = scheme.surface;
    final selected = scheme.primary;
    final unselected = scheme.onSurfaceVariant.withValues(alpha: .78);
    final items = [
      _items[0],
      _items[1],
      _items[2],
      BottomNavigationBarItem(
        icon: _NotificationIcon(count: unread),
        activeIcon: _NotificationIcon(count: unread, active: true),
        label: 'التنبيهات',
      ),
      _items[4],
    ];

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? .45 : .7),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? .22 : .07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: background,
          selectedItemColor: selected,
          unselectedItemColor: unselected,
          currentIndex: currentIndex.clamp(0, items.length - 1).toInt(),
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: items,
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
    if (GoRouterState.of(context).uri.path != target) {
      context.go(target);
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  final int count;
  final bool active;

  const _NotificationIcon({required this.count, this.active = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.notifications_rounded : Icons.notifications_none_rounded,
        ),
        if (count > 0)
          Positioned(
            top: -7,
            right: -9,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
