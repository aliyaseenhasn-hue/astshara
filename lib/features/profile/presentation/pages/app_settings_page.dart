import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/theme_mode_provider.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p20),
        children: [
          _buildSettingTile(
            context,
            Icons.language_rounded,
            'لغة التطبيق',
            'العربية',
            null,
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? AppColors.gold : AppColors.primary,
              ),
              title: const Text('مظهر التطبيق'),
              subtitle: Text(
                isDark
                    ? 'الوضع الداكن — هوية سمائية وذهبية واضحة'
                    : 'الوضع الفاتح — هوية سمائية وذهبية واضحة',
              ),
              value: isDark,
              activeColor: AppColors.gold,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
              },
            ),
          ),
          _buildSettingTile(
            context,
            Icons.notifications_rounded,
            'الإشعارات',
            'عرض الإشعارات الواردة',
            () => context.push('/notifications'),
          ),
          _buildSettingTile(
            context,
            Icons.notifications_none_rounded,
            'إعدادات التنبيهات',
            'النغمة والتنبيهات المحلية',
            () => context.push('/notification-settings'),
          ),
          const Divider(height: 40),
          _buildSettingTile(
            context,
            Icons.info_outline_rounded,
            'إصدار التطبيق',
            '2.0.0 (Unified)',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(value),
        trailing: onTap == null
            ? null
            : const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.outline,
              ),
        onTap: onTap,
      ),
    );
  }
}
