import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool isAdminLogin;
  const LoginPage({super.key, this.isAdminLogin = false});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      String phone = _phoneController.text.trim().replaceAll(' ', '');

      // معالجة الرقم العراقي بدقة: حذف الصفر الأول ورمز الدولة إذا وجد
      if (phone.startsWith('+964')) phone = phone.substring(4);
      if (phone.startsWith('964')) phone = phone.substring(3);
      if (phone.startsWith('0')) phone = phone.substring(1);

      // الصيغة النهائية التي وضعناها في السيرفر (964 + الرقم)
      final formattedPhone = '964$phone';

      // تأمين دخول الأدمن: السماح فقط برقمك الخاص
      if (widget.isAdminLogin && formattedPhone != '9647744844877') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('هذا الرقم لا يملك صلاحية دخول المسؤولين'),
              backgroundColor: AppColors.error),
        );
        return;
      }

      debugPrint('Submitting phone: $formattedPhone');

      try {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithPhone(formattedPhone);

        if (mounted) {
          context.push('/otp', extra: formattedPhone);
        }
      } catch (e) {
        debugPrint('Error during sign in: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, stack) {
          String errorMessage =
              err is AuthException ? err.message : err.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('فشل: $errorMessage'),
                backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor:
          widget.isAdminLogin ? AppColors.primary : AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p32, vertical: 60),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.isAdminLogin
                      ? Icons.admin_panel_settings
                      : Icons.account_balance,
                  size: 80,
                  color: widget.isAdminLogin ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isAdminLogin ? 'دخول المسؤولين' : 'استشارة',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isAdminLogin ? Colors.white : AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isAdminLogin
                      ? 'نظام الإدارة المركزي'
                      : 'منصتك القانونية الموثوقة في العراق',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isAdminLogin
                        ? Colors.white70
                        : AppColors.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                Text(
                  'يرجى إدخال رقم الهاتف المسجل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isAdminLogin ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(
                      color: widget.isAdminLogin ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    labelStyle: TextStyle(
                        color: widget.isAdminLogin
                            ? Colors.white70
                            : AppColors.outline),
                    hintText: '77xxxxxxxx',
                    hintStyle: TextStyle(
                        color: widget.isAdminLogin
                            ? Colors.white30
                            : AppColors.outline),
                    prefixIcon: Icon(Icons.phone_android,
                        color: widget.isAdminLogin
                            ? Colors.white70
                            : AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: widget.isAdminLogin
                              ? Colors.white30
                              : AppColors.surfaceVariant),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 24),
                state.isLoading
                    ? const LoadingWidget()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isAdminLogin
                              ? Colors.white
                              : AppColors.primary,
                          foregroundColor: widget.isAdminLogin
                              ? AppColors.primary
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          widget.isAdminLogin
                              ? 'تسجيل دخول الأدمن'
                              : 'إرسال رمز التحقق',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                if (!widget.isAdminLogin) ...[
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('أو',
                            style: TextStyle(color: AppColors.outline)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
                    icon: const Icon(Icons.account_circle,
                        size: 24, color: Colors.blue),
                    label: const Text('المتابعة باستخدام Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.surfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
