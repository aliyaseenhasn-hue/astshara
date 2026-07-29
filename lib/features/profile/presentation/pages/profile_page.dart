import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  Text(
                    user.fullName ?? 'مستخدم تجريبي',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  Text(user.email ?? '',
                      style: const TextStyle(color: AppColors.outline)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role == 'lawyer' ? 'محامي' : 'عميل',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 12)),
                  ),
                  const SizedBox(height: 40),
                  _buildProfileTile(Icons.history, 'سجل الاستشارات', () {}),
                  _buildProfileTile(Icons.payment, 'طرق الدفع', () {}),
                  _buildProfileTile(
                      Icons.settings_outlined, 'إعدادات التطبيق', () {}),
                  _buildProfileTile(Icons.help_outline, 'مركز المساعدة', () {}),
                  const Divider(height: 40),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.logout,
                          color: AppColors.error, size: 20),
                    ),
                    title: const Text('تسجيل الخروج',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold)),
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
