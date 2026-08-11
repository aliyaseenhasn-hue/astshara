import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/presentation/providers/notifications_provider.dart';

/// الشريط السفلي الرئيسي للتطبيق وفق بنية Stitch.
class MainBottomNav extends ConsumerWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    _NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'المحامون'),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'استشاراتي'),
    _NavItem(Icons.notifications_none_rounded, Icons.notifications_rounded, 'التنبيهات'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final selectedIndex = currentIndex.clamp(0, _items.length - 1).toInt();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: isDark ? .38 : .62))),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: isDark ? .24 : .08), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 7, 8, 6),
        child: Row(
          textDirection: TextDirection.rtl,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            return Expanded(
              child: _NavDestination(
                item: item,
                selected: index == selectedIndex,
                unreadCount: index == 3 ? unread : 0,
                onTap: () => _navigate(context, index),
              ),
            );
          }),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _NavDestination extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  const _NavDestination({required this.item, required this.selected, required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary.withValues(alpha: .12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _BadgeIcon(icon: selected ? item.activeIcon : item.icon, color: iconColor, count: unreadCount),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(color: iconColor, fontSize: selected ? 10.5 : 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, height: 1.1),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  const _BadgeIcon({required this.icon, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 23),
        if (count > 0)
          Positioned(
            top: -8,
            right: -11,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: scheme.error, borderRadius: BorderRadius.circular(99), border: Border.all(color: scheme.surface, width: 1.5)),
              child: Text(count > 99 ? '99+' : '$count', style: TextStyle(color: scheme.onError, fontSize: 8, fontWeight: FontWeight.w900, height: 1)),
            ),
          ),
      ],
    );
  }
}
