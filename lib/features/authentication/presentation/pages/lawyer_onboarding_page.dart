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

class LawyerOnboardingPage extends ConsumerStatefulWidget {
  final String fullName;
  final String email;

  const LawyerOnboardingPage({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  ConsumerState<LawyerOnboardingPage> createState() =>
      _LawyerOnboardingPageState();
}

class _LawyerOnboardingPageState extends ConsumerState<LawyerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();

  XFile? _profilePhoto;
  XFile? _idCardPhoto;

  @override
  void dispose() {
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
    if (_profilePhoto == null || _idCardPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى رفع الصورة الشخصية وصورة الهوية'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      // 1. تحديث البروفايل الأساسي
      await ref.read(authControllerProvider.notifier).updateInitialProfile(
            fullName: widget.fullName,
            email: widget.email,
            role: 'lawyer',
          );

      // 2. إكمال بيانات المحامي
      await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
            profileId: authId,
            licenseNumber: 'NEW_REQUEST',
            bio: 'طلب انضمام جديد - محامي',
            yearsExperience: 0,
            price: 0,
            idDocument: _idCardPhoto,
          );

      // ملاحظة: يمكن هنا إضافة منطق لرفع الصورة الشخصية كـ Avatar في المستقبل

      if (mounted) {
        _showSuccessDialog();
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
    final state = ref.watch(authControllerProvider);
    final lawyerState = ref.watch(lawyerSetupControllerProvider);
    final isLoading = state.isLoading || lawyerState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بيانات المحامي المهنية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. الصورة الشخصية (Avatar) في الأعلى
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage: _profilePhoto != null
                                ? (kIsWeb
                                    ? NetworkImage(_profilePhoto!.path)
                                    : FileImage(File(_profilePhoto!.path))
                                        as ImageProvider)
                                : null,
                            child: _profilePhoto == null
                                ? const Icon(Icons.person,
                                    size: 60, color: AppColors.outline)
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
                                onPressed: () => _pickImage('profile'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('الصورة الشخصية (تظهر للعملاء)',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.outline)),

                    const SizedBox(height: 40),

                    // 2. حقل الواتساب
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الواتساب',
                        hintText: '9647XXXXXXXX',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val?.isEmpty ?? true ? 'مطلوب للتواصل' : null,
                    ),

                    const SizedBox(height: 32),

                    // 3. صورة هوية النقابة
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('هوية النقابة (للتوثيق فقط):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickImage('id'),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: _idCardPhoto == null
                                  ? AppColors.error.withValues(alpha: 0.5)
                                  : AppColors.outline),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: _idCardPhoto == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 40, color: AppColors.outline),
                                  Text('اضغط لرفع صورة هوية النقابة',
                                      style:
                                          TextStyle(color: AppColors.outline)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(_idCardPhoto!.path,
                                        fit: BoxFit.cover)
                                    : Image.file(File(_idCardPhoto!.path),
                                        fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. الأزرار في أسفل الصفحة
          Container(
            padding: const EdgeInsets.all(AppSizes.p24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: isLoading
                ? const LoadingWidget()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إرسال طلب الانضمام',
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
