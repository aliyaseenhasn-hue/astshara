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
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'user';
  Uint8List? _profilePhotoBytes;
  Uint8List? _idCardBytes;
  final List<String> _selectedSpecializations = [];
  bool _initialized = false;

  final _specializations = const ['جنائي','أحوال شخصية','مدني','تجاري','عمل','عقارات','إداري','عسكري'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '';
      _emailController.text = user.email ?? '';
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        if (type == 'profile') _profilePhotoBytes = bytes;
        if (type == 'id') _idCardBytes = bytes;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر اختيار الصورة: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (authId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الحصول على معرف المستخدم'), backgroundColor: AppColors.error));
      return;
    }

    if (_selectedRole == 'lawyer') {
      if (_profilePhotoBytes == null || _idCardBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى رفع الصورة الشخصية وصورة الهوية'), backgroundColor: AppColors.error));
        return;
      }
      if (_selectedSpecializations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار تخصص واحد على الأقل'), backgroundColor: AppColors.error));
        return;
      }
      await ref.read(lawyerSetupControllerProvider.notifier).completeProfile(
        authUid: authId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        specializations: _selectedSpecializations,
        profilePhotoBytes: _profilePhotoBytes,
        idCardBytes: _idCardBytes,
      );
      if (!mounted) return;
      final state = ref.read(lawyerSetupControllerProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: ${state.error}'), backgroundColor: AppColors.error));
      } else {
        _showSuccessDialog();
      }
      return;
    }

    await ref.read(authControllerProvider.notifier).updateInitialProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
    );
    if (mounted) context.go('/');
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('تم إرسال الطلب'),
        content: const Text('تم إرسال ملفك للمراجعة. ستظهر حالة الحساب في التطبيق فور الانتهاء من التدقيق.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
      ),
    );
  }

  void _cancelAndLogout() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء العملية؟'),
        content: const Text('سيتم تسجيل خروجك ولن يتم حفظ البيانات المدخلة. هل تريد الاستمرار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.error), onPressed: _cancelAndLogout),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.assignment_ind_outlined, size: 70, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('خطوة واحدة تفصلك عن البداية', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('أكمل بياناتك لضمان تجربة قانونية آمنة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.outline, fontSize: 13)),
              const SizedBox(height: 32),
              const Text('نوع الحساب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _RoleCard(title: 'عميل', icon: Icons.person_search, selected: _selectedRole == 'user', onTap: () => setState(() => _selectedRole = 'user'))),
                const SizedBox(width: 16),
                Expanded(child: _RoleCard(title: 'محامي', icon: Icons.gavel, selected: _selectedRole == 'lawyer', onTap: () => setState(() => _selectedRole = 'lawyer'))),
              ]),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني (اختياري)', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()), validator: (v) => v != null && v.isNotEmpty && !v.contains('@') ? 'بريد غير صحيح' : null),
              AnimatedSize(duration: const Duration(milliseconds: 250), child: _selectedRole == 'lawyer' ? _buildLawyerSection() : const SizedBox.shrink()),
              const SizedBox(height: 32),
              isLoading ? const Center(child: LoadingWidget()) : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(_selectedRole == 'lawyer' ? 'إرسال طلب الانضمام' : 'حفظ والدخول', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        const Text('بيانات التوثيق المهنية', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 20),
        Center(child: Stack(children: [
          CircleAvatar(radius: 50, backgroundColor: AppColors.surfaceVariant, backgroundImage: _profilePhotoBytes != null ? MemoryImage(_profilePhotoBytes!) : null, child: _profilePhotoBytes == null ? const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.outline) : null),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: AppColors.primary, radius: 18, child: IconButton(icon: const Icon(Icons.edit, size: 16, color: Colors.white), onPressed: () => _pickImage('profile')))),
        ])),
        const SizedBox(height: 8),
        const Center(child: Text('الصورة الشخصية', style: TextStyle(fontSize: 12, color: AppColors.outline))),
        const SizedBox(height: 24),
        const Text('التخصصات القانونية (اختر واحدة أو أكثر):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _specializations.map((spec) {
          final selected = _selectedSpecializations.contains(spec);
          return FilterChip(label: Text(spec), selected: selected, onSelected: (value) => setState(() => value ? _selectedSpecializations.add(spec) : _selectedSpecializations.remove(spec)), selectedColor: AppColors.primary.withValues(alpha: 0.2), checkmarkColor: AppColors.primary);
        }).toList()),
        const SizedBox(height: 24),
        const Text('صورة هوية النقابة:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickImage('id'),
          child: Container(
            height: 160,
            decoration: BoxDecoration(border: Border.all(color: _idCardBytes == null ? AppColors.error.withValues(alpha: 0.3) : AppColors.outline), borderRadius: BorderRadius.circular(12), color: Colors.white),
            child: _idCardBytes == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.badge_outlined, size: 40, color: Colors.grey), Text('اضغط لرفع الهوية', style: TextStyle(fontSize: 12))]) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_idCardBytes!, fit: BoxFit.cover)),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.title, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceVariant, width: selected ? 2 : 1)),
      child: Column(children: [Icon(icon, color: selected ? AppColors.primary : AppColors.outline, size: 28), const SizedBox(height: 6), Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? AppColors.primary : AppColors.textPrimary))]),
    ),
  );
}
