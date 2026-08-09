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
      try {
        await ref.read(authControllerProvider.notifier).signInWithPhone(formattedPhone);
        if (mounted) context.push('/otp', extra: formattedPhone);
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
          final errorMessage = err is AuthException ? err.message : err.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل: $errorMessage'), backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.secondaryDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.secondaryDark, AppColors.primaryDark, AppColors.goldDark],
            stops: [0.0, 0.58, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -55,
              left: -55,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 28),
                ),
              ),
            ),
            Positioned(
              top: 110,
              right: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -45,
              right: -25,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.22), width: 20),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: AppColors.goldGradient),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.28), blurRadius: 18)],
                            ),
                            child: const Icon(Icons.account_balance, color: AppColors.secondaryDark, size: 29),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('استشارة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                              Text('ISTISHARA', style: TextStyle(fontSize: 10, color: AppColors.goldLight, letterSpacing: 2.0)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text('مرحباً بك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('منصتك القانونية الموثوقة\nفي العراق', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
                      const SizedBox(height: 50),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'رقم الهاتف — 07xxxxxxxx',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.gold),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.42)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.goldLight, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) => val?.isEmpty ?? true ? 'رقم الهاتف مطلوب' : null,
                      ),
                      const SizedBox(height: 24),
                      state.isLoading
                          ? const LoadingWidget()
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.secondaryDark,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 6,
                              ),
                              child: const Text('إرسال رمز التحقق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('أو', style: TextStyle(color: Colors.white70, fontSize: 12))),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.white),
                        label: const Text('المتابعة باستخدام Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primaryLight),
                          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
