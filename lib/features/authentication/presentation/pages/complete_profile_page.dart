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

  XFile? _personalPhoto;
  XFile? _idCardPhoto;
  XFile? _whatsappScreenshot;

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
        if (type == 'personal') _personalPhoto = image;
        if (type == 'id') _idCardPhoto = image;
        if (type == 'whatsapp') _whatsappScreenshot = image;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == 'lawyer') {
        if (_personalPhoto == null ||
            _idCardPhoto == null ||
            _whatsappScreenshot == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('يرجى رفع كافة الصور المطلوبة (شخصية، هوية، واتساب)'),
                backgroundColor: AppColors.error),
          );
          return;
        }
      }

      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      // 1. تحديث البروفايل الأساسي
      await ref.read(authControllerProvider.notifier).updateInitialProfile(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      // 2. إذا كان محامي، نقوم بحفظ البيانات المهنية والرفع
      if (_selectedRole == 'lawyer') {
        // يمكننا تطوير الـ provider ليرفع أكثر من صورة، حالياً سنرفع الهوية كبداية
        await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
              profileId: authId,
              licenseNumber: 'NEW_REQUEST',
              bio: 'طلب انضمام جديد - محامي',
              yearsExperience: 0,
              price: 0,
              idDocument: _idCardPhoto,
            );

        if (mounted) {
          _showSuccessDialog();
          return;
        }
      }

      if (mounted) context.go('/');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم إرسال الطلب بنجاح'),
        content: const Text(
            'شكراً لك! ملفك الآن قيد التدقيق. سنقوم بالتواصل معك عبر الواتساب فور الموافقة على الحساب.'),
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
    final state = ref.watch(authControllerProvider);
    final lawyerState = ref.watch(lawyerSetupControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Icon(Icons.person_pin_outlined,
                    size: 60, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text('إكمال البيانات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),

                // الحقول الأساسية
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder()),
                  validator: (val) =>
                      val?.isEmpty ?? true ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder()),
                  validator: (val) => (val == null || !val.contains('@'))
                      ? 'البريد غير صحيح'
                      : null,
                ),

                const SizedBox(height: 24),
                const Text('اختر نوع الحساب:',
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

                // قسم المحامي الديناميكي
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedRole == 'lawyer'
                      ? Column(
                          key: const ValueKey('lawyer_fields'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            const Divider(),
                            const Text('متطلبات توثيق المحامي (إلزامي):',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                            const SizedBox(height: 20),

                            // 1. رقم الواتساب
                            TextFormField(
                              controller: _whatsappController,
                              decoration: const InputDecoration(
                                  labelText: 'رقم الواتساب',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                              validator: (val) => val?.isEmpty ?? true
                                  ? 'رقم الواتساب مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // 2. الصور
                            _buildImagePickerTile('الصورة الشخصية (Portrait)',
                                _personalPhoto, () => _pickImage('personal')),
                            const SizedBox(height: 12),
                            _buildImagePickerTile('صورة هوية النقابة',
                                _idCardPhoto, () => _pickImage('id')),
                            const SizedBox(height: 12),
                            _buildImagePickerTile(
                                'لقطة شاشة للواتساب (تأكيد الرقم)',
                                _whatsappScreenshot,
                                () => _pickImage('whatsapp')),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('user_fields')),
                ),

                const SizedBox(height: 40),
                (state.isLoading || lawyerState.isLoading)
                    ? const LoadingWidget()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('حفظ والانطلاق',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerTile(String title, XFile? image, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(
                    color: image == null
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white),
            child: image == null
                ? const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.grey))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover)
                        : Image.file(File(image.path), fit: BoxFit.cover)),
          ),
        ),
      ],
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
                    isSelected ? AppColors.primary : AppColors.surfaceVariant),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : []),
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
