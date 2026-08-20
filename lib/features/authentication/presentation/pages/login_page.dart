import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _normalizePhone() {
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+964')) phone = phone.substring(4);
    if (phone.startsWith('964')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '964$phone';
  }

  Future<void> _telegramLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final phone = _normalizePhone();
      final data = await ref.read(authControllerProvider.notifier).startTelegramLogin(phone);
      final requestToken = data['request_token'] as String;
      final telegramUrl = data['telegram_url'] as String;
      if (!await launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication)) {
        throw Exception('تعذر فتح Telegram. تأكد من تثبيت التطبيق ثم حاول مرة أخرى.');
      }
      if (!mounted) return;
      await _showTelegramCodeDialog(requestToken);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  Future<void> _showTelegramCodeDialog(String requestToken) async {
    final controller = TextEditingController();
    var verifying = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('رمز Telegram', textAlign: TextAlign.right),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('تم فتح Telegram. اضغط «بدء» إذا ظهرت، وسيصلك رمز تحقق من 6 أرقام داخل المحادثة مع بوت استشارة.', textAlign: TextAlign.right),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'رمز التحقق', hintText: '123456', border: OutlineInputBorder()),
              ),
            ]),
            actions: [
              TextButton(onPressed: verifying ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              FilledButton(
                onPressed: verifying ? null : () async {
                  final code = controller.text.trim();
                  if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رمز التحقق المكون من 6 أرقام')));
                    return;
                  }
                  setDialogState(() => verifying = true);
                  try {
                    await ref.read(authControllerProvider.notifier).verifyTelegramLogin(requestToken: requestToken, code: code);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  } catch (e) {
                    setDialogState(() => verifying = false);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error));
                  }
                },
                child: verifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('تحقق ودخول'),
              ),
            ],
          ),
        ),
      );
    } finally { controller.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);
    final accent = AppColors.primary;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(error: (error, _) {
        final message = error is AuthException ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: scheme.error));
      });
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(children: [
          Positioned(top: -100, right: -90, child: Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryContainer.withValues(alpha: .35)))),
          Positioned(bottom: -120, left: -100, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: .05)))),
          Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 30, 24, 34), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 78, height: 78, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(26), border: Border.all(color: AppColors.secondaryLight.withValues(alpha: .45))), child: const Icon(Icons.balance_rounded, size: 42, color: AppColors.goldLight)),
            const SizedBox(height: 24),
            Text(widget.isAdminLogin ? 'دخول الإدارة' : 'مرحباً بك في استشارة', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.3, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(widget.isAdminLogin ? 'سجل الدخول للوصول إلى لوحة الإدارة.' : 'سجّل الدخول برقم هاتفك واحصل على رمز التحقق داخل Telegram.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5, height: 1.6)),
            const SizedBox(height: 30),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .8))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('رقم الهاتف', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
              const SizedBox(height: 9),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '07xxxxxxxx', prefixIcon: Icon(Icons.phone_android_rounded, color: accent), filled: true, fillColor: scheme.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2))), validator: (value) => value == null || value.trim().isEmpty ? 'رقم الهاتف مطلوب' : null),
              const SizedBox(height: 16),
              if (state.isLoading) const LoadingWidget() else SizedBox(height: 54, child: ElevatedButton.icon(onPressed: _telegramLogin, icon: const Icon(Icons.send_rounded), label: const Text('الحصول على الرمز عبر Telegram', style: TextStyle(fontWeight: FontWeight.w800)))),
              const SizedBox(height: 10),
              Text('سيتم فتح Telegram تلقائياً. اضغط «بدء» أو أرسل رسالة للبوت ليصلك الرمز.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, height: 1.5)),
            ])),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: state.isLoading ? null : () => ref.read(authControllerProvider.notifier).signInWithGoogle(), icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: AppColors.primary), label: const Text('المتابعة باستخدام Google')),
            const SizedBox(height: 22),
            Text('باستمرارك، أنت توافق على شروط الاستخدام وسياسة الخصوصية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant, height: 1.55)),
          ]))))),
        ]),
      ),
    );
  }
}
