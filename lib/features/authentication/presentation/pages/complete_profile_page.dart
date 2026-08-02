import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
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
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    // محاولة جلب الاسم من بيانات Google إذا كانت متوفرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final googleName =
            user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
        if (googleName != null) {
          _nameController.text = googleName;
        }
        if (user.email != null) {
          _emailController.text = user.email!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // سنقوم بتحديث البروفايل هنا
      // ملاحظة: سنستخدم Controller لتنفيذ عملية التحديث في سوبابيس
      await ref.read(authControllerProvider.notifier).updateInitialProfile(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p32),
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
                    tooltip: 'إلغاء والعودة لتسجيل الدخول',
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.person_add_outlined,
                    size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'إكمال الملف الشخصي',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'يرجى تزويدنا ببياناتك الأساسية للبدء',
                  style: TextStyle(color: AppColors.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'البريد الإلكتروني مطلوب';
                    if (!val.contains('@') || !val.contains('.'))
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
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
                        onTap: () => setState(() => _selectedRole = 'user'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'محامي',
                        icon: Icons.gavel,
                        isSelected: _selectedRole == 'lawyer',
                        onTap: () => setState(() => _selectedRole = 'lawyer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                state.isLoading
                    ? const LoadingWidget()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('حفظ والانطلاق',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
