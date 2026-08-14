import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// الشريط السفلي الرئيسي للتطبيق.
/// الإشعارات في أعلى التطبيق عبر زر الجرس، بينما تبقى الإجراءات السريعة للمحامي ثابتة هنا.
class MainBottomNav extends ConsumerWidget {
  final int currentIndex;
  final bool isLawyer;

  const MainBottomNav({super.key, required this.currentIndex, this.isLawyer = false});

  static const _clientItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    _NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'المحامون'),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'استشاراتي'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'الإعدادات'),
  ];

  static const _lawyerItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'استشاراتي'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'الإعدادات'),
  ];

  static const _lawyerQuickActions = <_QuickAction>[
    _QuickAction(Icons.calendar_month_rounded, 'المواعيد', '/bookings'),
    _QuickAction(Icons.person_rounded, 'ملفي', '/lawyer-profile-edit'),
    _QuickAction(Icons.schedule_rounded, 'أوقات التوفر', '/lawyer-availability'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = isLawyer ? _lawyerItems : _clientItems;
    final selectedIndex = currentIndex.clamp(0, items.length - 1).toInt();
    final direction = Directionality.of(context);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? .6 : .9)),
            boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: isDark ? .25 : .06), blurRadius: 22, offset: const Offset(0, 7))],
          ),
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLawyer) ...[
                _QuickActionsRow(actions: _lawyerQuickActions, direction: direction),
                const SizedBox(height: 6),
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: .45)),
                const SizedBox(height: 3),
              ],
              Row(
                textDirection: direction,
                children: List.generate(items.length, (index) {
                  return Expanded(
                    child: _NavDestination(
                      item: items[index],
                      selected: index == selectedIndex,
                      onTap: () => _navigate(context, index),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final target = isLawyer
        ? switch (index) {
            0 => '/lawyer-home',
            1 => '/bookings',
            2 => '/app-settings',
            _ => '/lawyer-home',
          }
        : switch (index) {
            0 => '/',
            1 => '/lawyers',
            2 => '/bookings',
            3 => '/app-settings',
            _ => '/',
          };

    if (GoRouterState.of(context).uri.path != target) context.go(target);
  }
}

class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> actions;
  final TextDirection direction;

  const _QuickActionsRow({required this.actions, required this.direction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      textDirection: direction,
      children: actions
          .map(
            (action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(action.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.icon, size: 19, color: scheme.primary),
                          const SizedBox(height: 3),
                          Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction(this.icon, this.label, this.route);
}

class _NavDestination extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavDestination({required this.item, required this.selected, required this.onTap});

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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 34),
                padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .18 : .16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(selected ? item.activeIcon : item.icon, color: iconColor, size: 23),
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
