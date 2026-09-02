import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
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
  bool _telegramStarting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizeDigits(String value) => value
      .replaceAllMapped(RegExp(r'[٠-٩]'), (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m.group(0)!).toString())
      .replaceAllMapped(RegExp(r'[۰-۹]'), (m) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(m.group(0)!).toString());

  String _normalizePhone() {
    var phone = _normalizeDigits(_phoneController.text)
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[()\-]'), '');
    if (phone.startsWith('+964')) phone = phone.substring(4);
    if (phone.startsWith('00964')) phone = phone.substring(5);
    if (phone.startsWith('964')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '964$phone';
  }

  Future<void> _telegramLogin() async {
    if (_telegramStarting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _telegramStarting = true);
    try {
      final data = await ref.read(authControllerProvider.notifier).startTelegramLogin(_normalizePhone());
      final token = data['request_token'] as String;
      final telegramUrl = data['telegram_url'] as String;
      if (!await launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication)) {
        throw Exception('تعذر فتح Telegram. تأكد من تثبيت التطبيق ثم حاول مرة أخرى.');
      }
      if (mounted) await _showTelegramCodeDialog(token);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _telegramStarting = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textDirection: TextDirection.rtl),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
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
            title: const Text('تأكيد تسجيل الدخول عبر Telegram', textAlign: TextAlign.right),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تم فتح Telegram. اضغط «بدء» داخل بوت استشارة، ثم سيصلك رمز من 6 أرقام. أدخل الرمز هنا.',
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    maxLength: 6,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز التحقق',
                      hintText: '000000',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    onChanged: (value) {
                      final normalized = _normalizeDigits(value);
                      if (normalized != value) {
                        controller.value = controller.value.copyWith(
                          text: normalized,
                          selection: TextSelection.collapsed(offset: normalized.length),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: verifying ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                icon: verifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.verified_rounded),
                onPressed: verifying
                    ? null
                    : () async {
                        final code = _normalizeDigits(controller.text).trim();
                        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أدخل رمز Telegram المكون من 6 أرقام.')),
                          );
                          return;
                        }
                        setDialogState(() => verifying = true);
                        try {
                          await ref.read(authControllerProvider.notifier).verifyTelegramLogin(
                            requestToken: requestToken,
                            code: code,
                          );
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        } catch (e) {
                          if (dialogContext.mounted) setDialogState(() => verifying = false);
                          if (context.mounted) _showError(e);
                        }
                      },
                label: Text(verifying ? 'جارٍ التحقق...' : 'تحقق ودخول'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('العودة'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Icon(Icons.balance_rounded, size: 54, color: AppColors.primary),
                          const SizedBox(height: 14),
                          Text(widget.isAdminLogin ? 'دخول الإدارة' : 'تسجيل الدخول', textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('أدخل رقم هاتفك العراقي لإتمام الدخول بأمان عبر Telegram.',
                              textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف العراقي',
                              hintText: '07xxxxxxxxx أو ٠٧xxxxxxxxx',
                              prefixIcon: Icon(Icons.phone_android_rounded),
                            ),
                            validator: (value) {
                              final phone = _normalizeDigits(value ?? '').replaceAll(RegExp(r'\s+'), '');
                              final digits = phone.replaceFirst(RegExp(r'^\+964|^00964|^964|^0'), '');
                              return RegExp(r'^7\d{9}$').hasMatch(digits)
                                  ? null
                                  : 'أدخل رقم هاتف عراقي صحيح مثل 07701234567';
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: (_telegramStarting || state.isLoading) ? null : _telegramLogin,
                              icon: _telegramStarting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send_rounded),
                              label: Text(_telegramStarting ? 'جارٍ فتح Telegram...' : 'تسجيل الدخول عبر Telegram'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: state.isLoading ? null : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('المتابعة باستخدام Google'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: const Text('ليس لديك حساب؟ إنشاء حساب جديد'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
