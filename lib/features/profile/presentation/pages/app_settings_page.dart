import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            () {},
          ),
          _buildSettingTile(
            context,
            Icons.dark_mode_outlined,
            'المظهر (Theme)',
            'الوضع الفاتح',
            () {},
          ),
          _buildSettingTile(
            context,
            Icons.notifications_none_rounded,
            'تنبيهات النظام',
            'مفعلة',
            () {},
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

  Widget _buildSettingTile(BuildContext context, IconData icon, String title,
      String value, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.outline),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
