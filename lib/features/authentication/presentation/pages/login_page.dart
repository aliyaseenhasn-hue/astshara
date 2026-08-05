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

      if (phone.startsWith('+964')) phone = phone.substring(4);
      if (phone.startsWith('964')) phone = phone.substring(3);
      if (phone.startsWith('0')) phone = phone.substring(1);

      final formattedPhone = '964$phone';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandGradient,
            stops: [0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative Circles from Design System
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    width: 30,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    width: 20,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p32, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Brand Mark
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.account_balance,
                                color: AppColors.gold, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'استشارة',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'ISTISHARA',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'مرحباً بك',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'منصتك القانونية الموثوقة\nفي العراق',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Phone Input Styled as per Design System
                      TextFormField(
                        controller: _phoneController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'رقم الهاتف — 07xxxxxxxx',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.phone_android_rounded,
                              color: AppColors.primary),
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'رقم الهاتف مطلوب' : null,
                      ),

                      const SizedBox(height: 24),
                      state.isLoading
                          ? const LoadingWidget()
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'إرسال رمز التحقق',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),

                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white10)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('أو',
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.white10)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata,
                            size: 30, color: Colors.white),
                        label: const Text('المتابعة باستخدام Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
