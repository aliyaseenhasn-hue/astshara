import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                        ),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(height: 40),
                        Stack(children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null,
                              child: user.avatarUrl == null || user.avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50, color: AppColors.primary) : null,
                            ),
                          ),
                          Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: AppColors.gold, child: IconButton(icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white), onPressed: () => _updateAvatar(ref)))),
                        ]),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showEditNameDialog(context, ref, user.fullName),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(user.fullName ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.edit, size: 14, color: AppColors.gold)]),
                        ),
                      ]),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileSectionTitle('المعاملات'),
                      _buildProfileTile(Icons.history, 'سجل الاستشارات', () => context.push('/bookings')),
                      _buildProfileTile(Icons.payment_rounded, 'طرق الدفع', () => context.push('/payment-methods')),
                      const SizedBox(height: AppSizes.p20),
                      _buildProfileSectionTitle('الإعدادات'),
                      _buildProfileTile(Icons.notifications_active_outlined, 'إعدادات الإشعارات', () => context.push('/notification-settings')),
                      _buildProfileTile(Icons.settings_outlined, 'إعدادات التطبيق', () => context.push('/app-settings')),
                      const SizedBox(height: AppSizes.p20),
                      _buildProfileSectionTitle('الدعم'),
                      _buildProfileTile(Icons.help_outline_rounded, 'مركز المساعدة', () => context.push('/help-center')),
                      _buildProfileTile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () {}),
                      const Padding(padding: EdgeInsets.symmetric(vertical: AppSizes.p24), child: Divider()),
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22)),
                        title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        onTap: () => ref.read(authControllerProvider.notifier).logout(),
                      ),
                      const SizedBox(height: 12),
                      Center(child: TextButton.icon(onPressed: () => _showDeleteConfirmation(context, ref), icon: const Icon(Icons.delete_forever_outlined, color: AppColors.textSecondary, size: 18), label: const Text('حذف الحساب نهائياً', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))),
                      const SizedBox(height: AppSizes.p48),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _updateAvatar(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      await image.readAsBytes();
    }
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextFormField(controller: controller, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).updateInitialProfile(fullName: controller.text.trim(), role: ref.read(authStateChangesProvider).value?.role ?? 'user');
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('حفظ التغييرات'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text('هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء وسيتم حذف كافة بياناتك وحجوزاتك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () { Navigator.pop(context); ref.read(authControllerProvider.notifier).deleteAccount(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0), child: const Text('نعم، احذف الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildProfileSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
    child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
  );

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
      onTap: onTap,
    ),
  );
}
