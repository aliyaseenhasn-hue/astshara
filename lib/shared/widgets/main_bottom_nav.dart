import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// الشريط السفلي الثابت. الإشعارات تبقى في أعلى التطبيق.
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
    _QuickAction(Icons.account_balance_wallet_rounded, 'المحفظة', '/lawyer-wallet'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .05), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLawyer) ...[
                _QuickActionsRow(actions: _lawyerQuickActions, direction: direction),
                const SizedBox(height: 7),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 4),
              ],
              Row(
                textDirection: direction,
                children: List.generate(items.length, (index) => Expanded(child: _NavDestination(item: items[index], selected: index == selectedIndex, onTap: () => _navigate(context, index)))),
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
    return Row(
      textDirection: direction,
      children: actions.map((action) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go(action.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, size: 18, color: AppColors.secondaryDark),
                    const SizedBox(width: 6),
                    Flexible(child: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2))),
                  ],
                ),
              ),
            ),
          ),
        ),
      )).toList(growable: false),
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
    final iconColor = selected ? AppColors.secondaryDark : AppColors.textSecondary;
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
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 34),
                padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 5),
                decoration: BoxDecoration(color: selected ? AppColors.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                child: Icon(selected ? item.activeIcon : item.icon, color: iconColor, size: 23),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(color: iconColor, fontSize: selected ? 11 : 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, height: 1.2),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
