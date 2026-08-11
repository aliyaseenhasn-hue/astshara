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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(globalLoadingProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancelAndLogout),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.assignment_ind_outlined, size: 70, color: scheme.primary),
              const SizedBox(height: 12),
              Text('خطوة واحدة تفصلك عن البداية', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
              const SizedBox(height: 4),
              Text('أكمل بياناتك لضمان تجربة قانونية آمنة', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              Text('نوع الحساب', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
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
                child: Text(_selectedRole == 'lawyer' ? 'إرسال طلب الانضمام' : 'حفظ والدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerSection() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text('بيانات التوثيق المهنية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary)),
        const SizedBox(height: 20),
        Center(child: Stack(children: [
          CircleAvatar(radius: 50, backgroundColor: scheme.surfaceContainerHighest, backgroundImage: _profilePhotoBytes != null ? MemoryImage(_profilePhotoBytes!) : null, child: _profilePhotoBytes == null ? Icon(Icons.camera_alt_outlined, size: 40, color: scheme.onSurfaceVariant) : null),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: scheme.primary, radius: 18, child: IconButton(icon: Icon(Icons.edit, size: 16, color: scheme.onPrimary), onPressed: () => _pickImage('profile')))),
        ])),
        const SizedBox(height: 8),
        Text('الصورة الشخصية', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Text('التخصصات القانونية (اختر واحدة أو أكثر)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _specializations.map((spec) {
          final selected = _selectedSpecializations.contains(spec);
          return FilterChip(label: Text(spec), selected: selected, onSelected: (value) => setState(() => value ? _selectedSpecializations.add(spec) : _selectedSpecializations.remove(spec)), selectedColor: scheme.primaryContainer, checkmarkColor: scheme.primary, labelStyle: TextStyle(color: selected ? scheme.onPrimaryContainer : scheme.onSurface));
        }).toList()),
        const SizedBox(height: 24),
        Text('صورة هوية النقابة', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickImage('id'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            decoration: BoxDecoration(border: Border.all(color: _idCardBytes == null ? scheme.error.withValues(alpha: 0.55) : scheme.outline), borderRadius: BorderRadius.circular(12), color: scheme.surfaceContainerHighest),
            child: _idCardBytes == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.badge_outlined, size: 40, color: scheme.onSurfaceVariant), const SizedBox(height: 8), Text('اضغط لرفع الهوية', style: TextStyle(fontSize: 12, color: scheme.onSurface))]) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_idCardBytes!, fit: BoxFit.cover)),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: selected ? scheme.primaryContainer : scheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? scheme.primary : scheme.outline, width: selected ? 2 : 1)),
        child: Column(children: [Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 28), const SizedBox(height: 6), Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? scheme.onPrimaryContainer : scheme.onSurface))]),
      ),
    );
  }
}
