import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات التطبيق'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p20),
        children: [
          _buildSectionTitle('الحساب والبيانات الشخصية'),
          _buildSettingTile(
            context,
            Icons.person_outline_rounded,
            'المعلومات الشخصية والتواصل',
            'الاسم، الهاتف، واتساب، المحافظة والصورة الشخصية',
            () => context.push('/profile'),
          ),
          _buildSectionTitle('التطبيق'),
          _buildSettingTile(context, Icons.language_rounded, 'لغة التطبيق', 'العربية', null),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? AppColors.gold : AppColors.primary,
              ),
              title: const Text('مظهر التطبيق'),
              subtitle: Text(isDark ? 'الوضع الداكن' : 'الوضع الفاتح'),
              value: isDark,
              activeColor: AppColors.gold,
              onChanged: (value) => ref.read(themeModeProvider.notifier).setMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  ),
            ),
          ),
          _buildSectionTitle('الإشعارات'),
          _buildSettingTile(
            context,
            Icons.tune_rounded,
            'إعدادات التنبيهات',
            'النغمة والتنبيهات المحلية',
            () => context.push('/notification-settings'),
          ),
          _buildSectionTitle('المدفوعات والدعم'),
          _buildSettingTile(
            context,
            Icons.payment_rounded,
            'طرق الدفع',
            'إدارة طرق الدفع المحفوظة',
            () => context.push('/payment-methods'),
          ),
          _buildSettingTile(
            context,
            Icons.help_outline_rounded,
            'مركز المساعدة',
            'المساعدة والدعم',
            () => context.push('/help-center'),
          ),
          _buildSectionTitle('الحساب'),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.error),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logout(context, ref),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
              ),
              title: const Text(
                'حذف الحساب نهائياً',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('لا يمكن التراجع عن هذا الإجراء'),
              onTap: () => _showDeleteConfirmation(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('إصدار التطبيق 2.0.0', style: TextStyle(color: AppColors.outline))),
          const SizedBox(height: AppSizes.p48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );

  Widget _buildSettingTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title),
          subtitle: Text(value),
          trailing: onTap == null
              ? null
              : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
          onTap: onTap,
        ),
      );

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text('هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء وسيتم حذف بيانات حسابك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('نعم، احذف الحساب'),
          ),
        ],
      ),
    );
  }
}
