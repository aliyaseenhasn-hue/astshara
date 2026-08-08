import 'dart:typed_data';
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

  Uint8List? _profilePhotoBytes;
  Uint8List? _idCardBytes;

  @override
  Future<void> _pickImage(String type) async {
    try {
      final picker = ImagePicker();
      final image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (type == 'profile') _profilePhotoBytes = bytes;
          if (type == 'id') _idCardBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_profilePhotoBytes == null || _idCardBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع الصورة الشخصية وصورة هوية النقابة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
            authUid: authId,
            fullName: widget.fullName,
            email: widget.email,
            profilePhotoBytes: _profilePhotoBytes,
            idCardBytes: _idCardBytes,
          );

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
          'شكراً لانضمامك! ملفك الآن قيد المراجعة والتدقيق. ستظهر حالة الحساب في التطبيق بعد إرسال الطلب.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'حسناً',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyerState = ref.watch(lawyerSetupControllerProvider);
    final isLoading = lawyerState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بيانات المحامي المهنية'),
        centerTitle: true,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 40),
                    _buildSectionTitle('وثائق التحقق'),
                    const SizedBox(height: 16),
                    const Text(
                      'صورة هوية النقابة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIdCardPicker(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomSection(isLoading),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: _profilePhotoBytes != null
                    ? MemoryImage(_profilePhotoBytes!)
                    : null,
                child: _profilePhotoBytes == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.outline,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () => _pickImage('profile'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'الصورة الشخصية',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Text(
            'سوف تظهر للعملاء في نتائج البحث',
            style: TextStyle(fontSize: 11, color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildIdCardPicker() {
    return InkWell(
      onTap: () => _pickImage('id'),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: _idCardBytes == null
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: _idCardBytes == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 48, color: AppColors.outline),
                  SizedBox(height: 8),
                  Text(
                    'اضغط لرفع صورة هوية النقابة',
                    style: TextStyle(color: AppColors.outline),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_idCardBytes!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildBottomSection(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إرسال طلب الانضمام',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}
