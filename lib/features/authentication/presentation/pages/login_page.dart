import 'dart:async';
import 'package:flutter/foundation.dart';
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

  Future<void> _openTelegram(String telegramUrl) async {
    final uri = Uri.parse(telegramUrl);
    final bot = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    final start = uri.queryParameters['start'] ?? '';

    if (kIsWeb) {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      )) {
        throw Exception('تعذر فتح Telegram. اضغط «فتح Telegram» وحاول مرة أخرى.');
      }
      return;
    }

    if (bot.isNotEmpty && start.isNotEmpty) {
      final deepLink = Uri.parse(
        'tg://resolve?domain=${Uri.encodeComponent(bot)}&start=${Uri.encodeComponent(start)}',
      );
      try {
        if (await launchUrl(deepLink, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('تعذر فتح Telegram. اضغط «فتح Telegram» وحاول مرة أخرى.');
    }
  }

  Future<void> _telegramLogin() async {
    if (_telegramStarting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _telegramStarting = true);
    try {
      final data = await ref.read(authControllerProvider.notifier).startTelegramLogin(_normalizePhone());
      final token = data['request_token'] as String;
      final telegramUrl = data['telegram_url'] as String;
      await _openTelegram(telegramUrl);
      if (mounted) await _showTelegramDialog(token);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _telegramStarting = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _finishTelegramLogin(String requestToken) async {
    await ref.read(authControllerProvider.notifier).verifyTelegramLogin(
          requestToken: requestToken,
          code: '',
        );

    // Do not rely only on GoRouter's auth stream here. Explicitly refresh the
    // auth model and navigate after the Supabase session has been installed.
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.getCurrentUser();
    if (user == null) {
      throw Exception('تم التحقق من Telegram لكن لم يتم تثبيت جلسة الدخول.');
    }
    if (!mounted) return;

    // /home is intentional: the router will redirect a verified lawyer to
    // /lawyer-home and a normal user to their authenticated home.
    context.go('/home');
  }

  Future<void> _showTelegramDialog(String requestToken) async {
    final codeController = TextEditingController();
    var verifying = false;
    var showCode = false;
    var message = 'تم فتح Telegram. اضغط «بدء» ثم اختر «مشاركة رقم الهاتف». بعد مطابقة الرقم سيتم الدخول تلقائياً.';
    Timer? poller;
    var closed = false;

    Future<void> checkStatus(StateSetter setDialogState) async {
      try {
        final result = await Supabase.instance.client.functions.invoke(
          'telegram-auth-v2',
          body: {'action': 'status', 'request_token': requestToken},
        );
        final data = Map<String, dynamic>.from(result.data as Map);
        final status = data['status']?.toString();

        if (status == 'telegram_verified' && !verifying && !closed) {
          setDialogState(() {
            verifying = true;
            message = 'تم التحقق من Telegram. جارٍ تسجيل الدخول...';
          });
          try {
            await _finishTelegramLogin(requestToken);
            poller?.cancel();
            closed = true;
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (mounted) {
              setDialogState(() {
                verifying = false;
                message = 'تم التحقق من Telegram لكن تعذر فتح الحساب. سيتم إعادة المحاولة تلقائياً.';
              });
            }
            rethrow;
          }
        } else if (status == 'code_sent' && !showCode && !closed) {
          setDialogState(() {
            showCode = true;
            message = 'تم إرسال رمز التحقق. أدخل الرمز هنا لإكمال الدخول.';
          });
        } else if (status == 'expired' && !closed) {
          poller?.cancel();
          closed = true;
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          if (mounted) _showError(Exception('انتهت صلاحية طلب Telegram. حاول مرة أخرى.'));
        }
      } catch (_) {}
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            poller ??= Timer.periodic(
              const Duration(seconds: 1),
              (_) => checkStatus(setDialogState),
            );

            return AlertDialog(
              title: const Text('تسجيل الدخول عبر Telegram', textAlign: TextAlign.right),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.telegram, size: 48),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.right),
                    if (!showCode) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                    if (showCode) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
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
                            codeController.value = codeController.value.copyWith(
                              text: normalized,
                              selection: TextSelection.collapsed(offset: normalized.length),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () {
                          closed = true;
                          poller?.cancel();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('إلغاء'),
                ),
                if (showCode)
                  FilledButton.icon(
                    icon: verifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_rounded),
                    label: Text(verifying ? 'جارٍ التحقق...' : 'تحقق ودخول'),
                    onPressed: verifying
                        ? null
                        : () async {
                            final code = _normalizeDigits(codeController.text).trim();
                            if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                              _showError(Exception('أدخل رمز Telegram المكون من 6 أرقام.'));
                              return;
                            }
                            setDialogState(() => verifying = true);
                            try {
                              await _finishTelegramLogin(requestToken);
                              poller?.cancel();
                              closed = true;
                              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            } catch (e) {
                              if (dialogContext.mounted) setDialogState(() => verifying = false);
                              if (mounted) _showError(e);
                            }
                          },
                  ),
              ],
            );
          },
        ),
      );
    } finally {
      closed = true;
      poller?.cancel();
      codeController.dispose();
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
                          Text(
                            widget.isAdminLogin ? 'دخول الإدارة' : 'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أدخل رقم هاتفك العراقي لإتمام الدخول بأمان عبر Telegram.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
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
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                _telegramStarting ? 'جارٍ فتح Telegram...' : 'تسجيل الدخول عبر Telegram',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
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
