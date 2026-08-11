import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storage_client/storage_client.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: user == null
          ? Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: scheme.onSurface)))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark]),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            children: [
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
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.gold,
                                  child: IconButton(icon: const Icon(Icons.camera_alt, size: 14, color: AppColors.secondaryDark), onPressed: () => _updateAvatar(context, ref)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showEditProfileDialog(context, ref),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(user.fullName ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, size: 14, color: AppColors.gold),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileSectionTitle(context, 'المعاملات'),
                      _buildProfileTile(context, Icons.history, 'سجل الاستشارات', () => context.push('/bookings')),
                      _buildProfileTile(context, Icons.payment_rounded, 'طرق الدفع', () => context.push('/payment-methods')),
                      const SizedBox(height: AppSizes.p20),
                      _buildProfileSectionTitle(context, 'الملف الشخصي'),
                      _buildProfileTile(context, Icons.person_outline, 'المعلومات الشخصية والتواصل', () => _showEditProfileDialog(context, ref)),
                      const SizedBox(height: AppSizes.p20),
                      _buildProfileSectionTitle(context, 'الإعدادات'),
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: SwitchListTile(
                          secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: isDark ? AppColors.gold : AppColors.primary),
                          title: const Text('مظهر التطبيق'),
                          subtitle: Text(isDark ? 'الوضع الداكن' : 'الوضع الفاتح'),
                          value: isDark,
                          activeColor: AppColors.gold,
                          onChanged: (value) => ref.read(themeModeProvider.notifier).setMode(value ? ThemeMode.dark : ThemeMode.light),
                        ),
                      ),
                      _buildProfileTile(context, Icons.notifications_active_outlined, 'إعدادات الإشعارات', () => context.push('/notification-settings')),
                      _buildProfileTile(context, Icons.help_outline_rounded, 'مركز المساعدة', () => context.push('/help-center')),
                      const SizedBox(height: AppSizes.p20),
                      _buildProfileSectionTitle(context, 'الدعم'),
                      _buildProfileTile(context, Icons.privacy_tip_outlined, 'سياسة الخصوصية', () {}),
                      const Padding(padding: EdgeInsets.symmetric(vertical: AppSizes.p24), child: Divider()),
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22)),
                        title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        onTap: () => _logout(context, ref),
                      ),
                      const SizedBox(height: 12),
                      Center(child: TextButton.icon(onPressed: () => _showDeleteConfirmation(context, ref), icon: Icon(Icons.delete_forever_outlined, color: scheme.onSurfaceVariant, size: 18), label: Text('حذف الحساب نهائياً', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)))),
                      const SizedBox(height: AppSizes.p48),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _updateAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;
      final ext = image.name.split('.').last.toLowerCase();
      final contentType = switch (ext) {'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg'};
      final path = '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await SupabaseConfig.client.storage.from('avatars').uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: contentType));
      final url = SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);
      await SupabaseConfig.client.from('profiles').update({'avatar_url': url}).eq('auth_id', user.id);
      await ref.read(authRepositoryProvider).refreshUser();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة الشخصية')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الصورة: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    try {
      final row = await SupabaseConfig.client.from('profiles').select('full_name,phone,whatsapp_number,city').eq('auth_id', user.id).maybeSingle();
      if (!context.mounted) return;
      final nameController = TextEditingController(text: row?['full_name']?.toString() ?? user.fullName ?? '');
      final whatsappController = TextEditingController(text: row?['whatsapp_number']?.toString() ?? row?['phone']?.toString() ?? user.phone ?? '');
      final governorateController = TextEditingController(text: row?['city']?.toString() ?? '');
      var saving = false;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('المعلومات الشخصية والتواصل'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 10),
              TextField(controller: whatsappController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم واتساب للتواصل *', hintText: '+9647xxxxxxxxx', prefixIcon: Icon(Icons.chat_outlined))),
              const SizedBox(height: 10),
              TextField(controller: governorateController, decoration: const InputDecoration(labelText: 'المحافظة', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerRight, child: Text('رقم واتساب مطلوب لطلب الاستشارات عن بُعد.', style: TextStyle(fontSize: 12))),
            ])),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  final name = nameController.text.trim();
                  final whatsapp = whatsappController.text.trim();
                  if (name.isEmpty || whatsapp.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم الكامل ورقم واتساب مطلوبان')));
                    return;
                  }
                  setState(() => saving = true);
                  try {
                    await SupabaseConfig.client.rpc('update_own_profile_contact', params: {'p_full_name': name, 'p_phone': whatsapp, 'p_whatsapp_number': whatsapp, 'p_city': governorateController.text.trim().isEmpty ? null : governorateController.text.trim()});
                    await ref.read(authRepositoryProvider).refreshUser();
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المعلومات بنجاح')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ المعلومات: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: AppColors.error));
                    setState(() => saving = false);
                  }
                },
                child: Text(saving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
              ),
            ],
          ),
        ),
      );
      nameController.dispose();
      whatsappController.dispose();
      governorateController.dispose();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل المعلومات: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('حذف الحساب؟'), content: const Text('هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء وسيتم حذف كافة بياناتك وحجوزاتك.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () { Navigator.pop(context); ref.read(authControllerProvider.notifier).deleteAccount(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0), child: const Text('نعم، احذف الحساب', style: TextStyle(fontWeight: FontWeight.bold)))],));
  }

  Widget _buildProfileSectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8), child: Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)));
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: scheme.primary, size: 20)),
        title: Text(title, style: TextStyle(color: scheme.onSurface)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
