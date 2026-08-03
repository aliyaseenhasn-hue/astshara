import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
            _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // إضافة مستمع للأخطاء لعرضها في SnackBar
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, stack) {
          String message = 'حدث خطأ ما';
          if (err.toString().contains('429')) {
            message =
                'طلبات كثيرة جداً، يرجى الانتظار قليلاً قبل المحاولة مرة أخرى.';
          } else {
            message = err.toString();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'الاسم الكامل', border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'كلمة المرور', border: OutlineInputBorder()),
                obscureText: true,
                validator: (val) => (val?.length ?? 0) < 6
                    ? 'يجب أن تكون 6 أحرف على الأقل'
                    : null,
              ),
              const SizedBox(height: AppSizes.p24),
              const Text('نوع الحساب:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('عميل'),
                      value: 'user',
                      groupValue: _selectedRole,
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? 'user'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('محامي'),
                      value: 'lawyer',
                      groupValue: _selectedRole,
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? 'lawyer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p24),
              state.isLoading
                  ? const LoadingWidget()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSizes.p16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إنشاء الحساب'),
                    ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('لديك حساب بالفعل؟ سجل دخولك'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
