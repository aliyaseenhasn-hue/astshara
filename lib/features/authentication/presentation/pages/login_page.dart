import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
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
  void dispose() { _phoneController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+964')) phone = phone.substring(4);
    if (phone.startsWith('964')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    final formattedPhone = '964$phone';
    try {
      await ref.read(authControllerProvider.notifier).signInWithPhone(formattedPhone);
      if (mounted) context.push('/otp', extra: formattedPhone);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(authControllerProvider);
    final accent = dark ? AppColors.gold : scheme.primary;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(error: (error, _) {
        final message = error is AuthException ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: scheme.error));
      });
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: -100, right: -90, child: Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .07)))),
            Positioned(bottom: -120, left: -100, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: .05)))),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(
                        width: 78,
                        height: 78,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest : scheme.primaryContainer, borderRadius: BorderRadius.circular(26), border: Border.all(color: accent.withValues(alpha: .35))),
                        child: Icon(Icons.balance_rounded, size: 42, color: accent),
                      ),
                      const SizedBox(height: 24),
                      Text(widget.isAdminLogin ? 'دخول الإدارة' : 'مرحباً بك في استشارة', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.3, color: scheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(widget.isAdminLogin ? 'سجل الدخول للوصول إلى لوحة الإدارة.' : 'استشارتك القانونية تبدأ من المكان الصحيح.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5, height: 1.6)),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .72) : scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .8)), boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 26, offset: const Offset(0, 10))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('رقم الهاتف', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(hintText: '07xxxxxxxx', prefixIcon: Icon(Icons.phone_android_rounded, color: accent), filled: true, fillColor: scheme.surfaceContainerHighest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent, width: 2))),
                            validator: (value) => value == null || value.trim().isEmpty ? 'رقم الهاتف مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          if (state.isLoading) const LoadingWidget() else SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.sms_outlined), label: const Text('إرسال رمز التحقق'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: dark ? accent : scheme.primary, foregroundColor: dark ? Colors.black : scheme.onPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [Expanded(child: Divider(color: scheme.outlineVariant)), Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('أو', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))), Expanded(child: Divider(color: scheme.outlineVariant))]),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(onPressed: state.isLoading ? null : () => ref.read(authControllerProvider.notifier).signInWithGoogle(), icon: Icon(Icons.g_mobiledata_rounded, size: 30, color: accent), label: const Text('المتابعة باستخدام Google'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: scheme.onSurface, side: BorderSide(color: scheme.outlineVariant), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      const SizedBox(height: 22),
                      Text('باستمرارك، أنت توافق على شروط الاستخدام وسياسة الخصوصية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant, height: 1.55)),
                    ]),
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
