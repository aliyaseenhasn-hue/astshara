import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/lawyer_setup_provider.dart';

class LawyerSetupPage extends ConsumerStatefulWidget {
  const LawyerSetupPage({super.key});

  @override
  ConsumerState<LawyerSetupPage> createState() => _LawyerSetupPageState();
}

class _LawyerSetupPageState extends ConsumerState<LawyerSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _whatsappController = TextEditingController();

  Uint8List? _idCardBytes;
  Uint8List? _profilePhotoBytes;

  @override
  void dispose() {
    _licenseController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (type == 'id') _idCardBytes = bytes;
        if (type == 'profile') _profilePhotoBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;

      await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
            profileId: user.id,
            fullName: user.fullName ?? '',
            email: user.email,
            whatsapp: _whatsappController.text.trim(),
            profilePhotoBytes: _profilePhotoBytes,
            idCardBytes: _idCardBytes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lawyerSetupControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد ملف المحامي'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أكمل بياناتك المهنية للبدء في استقبال الاستشارات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.p24),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                    labelText: 'رقم هوية النقابة',
                    border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                    labelText: 'رقم الواتساب', border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'نبذة تعريفية (Bio)',
                    border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                          labelText: 'سنوات الخبرة',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: 'سعر الاستشارة (IQD)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p24),
              const Text('هوية النقابة (صورة): * إلزامي',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.p8),
              InkWell(
                onTap: () => _pickImage('id'),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _idCardBytes == null
                            ? AppColors.error.withValues(alpha: 0.5)
                            : Colors.grey,
                        width: 2),
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                  ),
                  child: _idCardBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.red),
                              Text('اضغط لرفع هوية النقابة',
                                  style: TextStyle(color: Colors.red))
                            ])
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                          child:
                              Image.memory(_idCardBytes!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              state.isLoading
                  ? const LoadingWidget()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.p16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white),
                      child: const Text('حفظ وإرسال للمراجعة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
