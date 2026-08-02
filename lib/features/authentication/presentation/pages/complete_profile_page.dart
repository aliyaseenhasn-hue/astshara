import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../../lawyers/presentation/providers/lawyer_setup_provider.dart';
import '../providers/auth_provider.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();

  String _selectedRole = 'user';

  XFile? _profilePhoto;
  XFile? _idCardPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final googleName =
            user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
        if (googleName != null) _nameController.text = googleName;
        if (user.email != null) _emailController.text = user.email!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        if (type == 'profile') _profilePhoto = image;
        if (type == 'id') _idCardPhoto = image;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == 'lawyer' &&
          (_profilePhoto == null || _idCardPhoto == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى رفع الصورة الشخصية وصورة الهوية'),
              backgroundColor: AppColors.error),
        );
        return;
      }

      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      ref.read(globalLoadingProvider.notifier).setLoading(true);

      try {
        // 1. تحديث البروفايل الأساسي
        await ref.read(authControllerProvider.notifier).updateInitialProfile(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              role: _selectedRole,
            );

        // 2. إذا كان محامي، نقوم بحفظ البيانات المهنية
        if (_selectedRole == 'lawyer') {
          await ref
              .read(lawyerSetupControllerProvider.notifier)
              .completeProfile(
                profileId: authId,
                licenseNumber: 'NEW_REQUEST',
                bio: 'طلب انضمام جديد',
                yearsExperience: 0,
                price: 0,
                idDocument: _idCardPhoto,
              );

          if (mounted) _showSuccessDialog();
        } else {
          if (mounted) context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('فشل الحفظ: $e'),
                backgroundColor: AppColors.error),
          );
        }
      } finally {
        ref.read(globalLoadingProvider.notifier).setLoading(false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم إرسال الطلب بنجاح'),
        content: const Text(
            'شكراً لانضمامك! ملفك الآن قيد المراجعة. سنتواصل معك عبر الواتساب فور التفعيل.'),
        actions: [
          ElevatedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout()),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- القسم الأول: المعلومات الأساسية ---
                    const Icon(Icons.person_add_outlined,
                        size: 70, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('يرجى تزويدنا ببياناتك الأساسية للبدء',
                        style: TextStyle(color: AppColors.outline),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder()),
                      validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder()),
                      validator: (val) => (val == null || !val.contains('@'))
                          ? 'بريد غير صحيح'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('نوع الحساب:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _RoleCard(
                                title: 'عميل',
                                icon: Icons.person,
                                isSelected: _selectedRole == 'user',
                                onTap: () =>
                                    setState(() => _selectedRole = 'user'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _RoleCard(
                                title: 'محامي',
                                icon: Icons.gavel,
                                isSelected: _selectedRole == 'lawyer',
                                onTap: () =>
                                    setState(() => _selectedRole = 'lawyer'))),
                      ],
                    ),

                    // --- القسم الثاني: يظهر فقط إذا اختار محامي ---
                    if (_selectedRole == 'lawyer') ...[
                      const SizedBox(height: 32),
                      const Divider(
                          thickness: 1, color: AppColors.surfaceVariant),
                      const SizedBox(height: 16),
                      const Text('بيانات التوثيق المهنية (إلزامي)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 24),

                      // الصورة الشخصية (Avatar)
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage: _profilePhoto != null
                                  ? (kIsWeb
                                      ? NetworkImage(_profilePhoto!.path)
                                      : FileImage(File(_profilePhoto!.path))
                                          as ImageProvider)
                                  : null,
                              child: _profilePhoto == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: AppColors.outline)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 18,
                                child: IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        size: 18, color: Colors.white),
                                    onPressed: () => _pickImage('profile')),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                          child: Text('صورة الملف الشخصي',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.outline))),

                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(
                            labelText: 'رقم الواتساب',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            hintText: '9647XXXXXXXX'),
                        keyboardType: TextInputType.phone,
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'مطلوب للتواصل' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text('صورة هوية النقابة:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _pickImage('id'),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: _idCardPhoto == null
                                      ? AppColors.error.withValues(alpha: 0.3)
                                      : AppColors.outline),
                              borderRadius: BorderRadius.circular(12)),
                          child: _idCardPhoto == null
                              ? const Center(
                                  child: Icon(Icons.badge_outlined,
                                      size: 40, color: Colors.grey))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(_idCardPhoto!.path,
                                          fit: BoxFit.cover)
                                      : Image.file(File(_idCardPhoto!.path),
                                          fit: BoxFit.cover)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // زر الحفظ الثابت في الأسفل
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('حفظ وإرسال المعلومات',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.title,
      required this.icon,
      required this.isSelected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.surfaceVariant)),
        child: Column(children: [
          Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }
}
