import 'dart:typed_data';
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
  Uint8List? _profilePhotoBytes;
  Uint8List? _idCardBytes;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final googleName =
            user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
        if (googleName != null) _nameController.text = googleName;
        if (user.email != null) _emailController.text = user.email!;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

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
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      if (_selectedRole == 'lawyer') {
        if (_profilePhotoBytes == null || _idCardBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('يرجى رفع الصورة الشخصية وصورة الهوية'),
                backgroundColor: AppColors.error),
          );
          return;
        }

        await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
              profileId: authId,
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              whatsapp: _whatsappController.text.trim(),
              profilePhotoBytes: _profilePhotoBytes,
              idCardBytes: _idCardBytes,
            );
        if (mounted) _showSuccessDialog();
      } else {
        await ref.read(authControllerProvider.notifier).updateInitialProfile(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              role: _selectedRole,
            );
        if (mounted) context.go('/');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم إرسال الطلب'),
        content: const Text(
            'شكراً لانضمامك! ملفك قيد المراجعة الآن. سنتواصل معك فور التفعيل.'),
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
    final isLoading = ref.watch(globalLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: const Text('إكمال الملف الشخصي'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),

              // 1. اختيار نوع الحساب في الأعلى
              const Text('نوع الحساب:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _RoleCard(
                          title: 'عميل',
                          icon: Icons.person_search,
                          isSelected: _selectedRole == 'user',
                          onTap: () => setState(() => _selectedRole = 'user'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _RoleCard(
                          title: 'محامي',
                          icon: Icons.gavel,
                          isSelected: _selectedRole == 'lawyer',
                          onTap: () =>
                              setState(() => _selectedRole = 'lawyer'))),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              // 2. المعلومات الأساسية
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder()),
                validator: (val) =>
                    val?.trim().isEmpty ?? true ? 'مطلوب' : null,
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

              // 3. قسم المحامي (يظهر بانسيابية أسفل البيانات)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _selectedRole == 'lawyer'
                    ? _buildLawyerSection()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 40),

              // 4. زر الحفظ في نهاية النموذج
              isLoading
                  ? const Center(child: LoadingWidget())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          _selectedRole == 'lawyer'
                              ? 'إرسال طلب الانضمام'
                              : 'حفظ والدخول',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.assignment_ind_outlined, size: 70, color: AppColors.primary),
        SizedBox(height: 12),
        Text('خطوة واحدة تفصلك عن البداية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('أكمل بياناتك لضمان تجربة قانونية آمنة',
            style: TextStyle(color: AppColors.outline, fontSize: 13)),
      ],
    );
  }

  Widget _buildLawyerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Text('بيانات التوثيق المهنية:',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),

        // الصورة الشخصية
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: _profilePhotoBytes != null
                    ? MemoryImage(_profilePhotoBytes!)
                    : null,
                child: _profilePhotoBytes == null
                    ? const Icon(Icons.camera_alt_outlined,
                        size: 40, color: AppColors.outline)
                    : null,
              ),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: IconButton(
                          icon: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                          onPressed: () => _pickImage('profile')))),
            ],
          ),
        ),
        const Center(
            child: Text('الصورة الشخصية (Portrait)',
                style: TextStyle(fontSize: 12, color: AppColors.outline))),

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
              val?.trim().isEmpty ?? true ? 'مطلوب للتواصل' : null,
        ),

        const SizedBox(height: 24),
        const Text('صورة هوية النقابة:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickImage('id'),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
                border: Border.all(
                    color: _idCardBytes == null
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.outline),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white),
            child: _idCardBytes == null
                ? const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.badge_outlined,
                            size: 40, color: Colors.grey),
                        Text('اضغط لرفع الهوية', style: TextStyle(fontSize: 12))
                      ]))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_idCardBytes!, fit: BoxFit.cover)),
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(children: [
          Icon(icon,
              color: isSelected ? Colors.white : AppColors.primary, size: 30),
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
