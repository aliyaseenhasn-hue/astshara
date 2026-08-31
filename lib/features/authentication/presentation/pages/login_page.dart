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

  String _normalizePhone() {
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+964')) phone = phone.substring(4);
    if (phone.startsWith('964')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '964$phone';
  }

  Future<void> _telegramLogin() async {
    if (_telegramStarting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _telegramStarting = true);
    try {
      final data = await ref
          .read(authControllerProvider.notifier)
          .startTelegramLogin(_normalizePhone());
      final requestToken = data['request_token'] as String;
      final telegramUrl = data['telegram_url'] as String;

      if (!await launchUrl(
        Uri.parse(telegramUrl),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception(
          'تعذر فتح Telegram. تأكد من تثبيت التطبيق ثم حاول مرة أخرى.',
        );
      }

      if (!mounted) return;
      await _showTelegramCodeDialog(requestToken);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _telegramStarting = false);
    }
  }

  Future<void> _showTelegramCodeDialog(String requestToken) async {
    final controller = TextEditingController();
    var verifying = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('رمز Telegram', textAlign: TextAlign.right),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Text(
                      'تم فتح Telegram. اضغط «بدء» إذا ظهرت، وسيصلك رمز تحقق من 6 أرقام داخل المحادثة مع بوت استشارة.',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: verifying
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: verifying
                        ? null
                        : () async {
                            setDialogState(() => verifying = true);
                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .verifyTelegramLogin(
                                    requestToken: requestToken,
                                    code: controller.text.trim(),
                                  );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (e) {
                              setDialogState(() => verifying = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: verifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تحقق ودخول'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);
    final accent = AppColors.primary;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is AuthException ? error.message : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: scheme.error),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _LoginForm(
              state: state,
              accent: accent,
              formKey: _formKey,
              phoneController: _phoneController,
              telegramStarting: _telegramStarting,
              onTelegram: _telegramLogin,
              onGoogle: () => ref
                  .read(authControllerProvider.notifier)
                  .signInWithGoogle(),
              isAdmin: widget.isAdminLogin,
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 36 : 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: wide ? 1120 : 520,
                    ),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _BrandPanel()),
                              const SizedBox(width: 44),
                              SizedBox(width: 460, child: form),
                            ],
                          )
                        : form,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [s.primaryContainer, s.surfaceContainerHighest],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: s.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _BrandIcon(),
          SizedBox(height: 26),
          _BrandTitle(),
          SizedBox(height: 8),
          _BrandSubtitle(),
          SizedBox(height: 24),
          _BrandDescription(),
          SizedBox(height: 24),
          _Benefit(
            icon: Icons.verified_user_outlined,
            title: 'حساب آمن',
            text: 'مصادقة ورموز تحقق لحماية الوصول.',
          ),
          SizedBox(height: 12),
          _Benefit(
            icon: Icons.track_changes_rounded,
            title: 'متابعة الطلبات',
            text: 'ابقَ على اطلاع بحالة خدماتك من حسابك.',
          ),
          SizedBox(height: 12),
          _Benefit(
            icon: Icons.support_agent_rounded,
            title: 'تجربة موحدة',
            text: 'الوصول إلى خدمات المنصة من مكان واحد.',
          ),
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: s.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(Icons.balance_rounded, color: s.onPrimary, size: 40),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'استشارة',
      style: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _BrandSubtitle extends StatelessWidget {
  const _BrandSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'منصة الاستشارات القانونية',
      style: TextStyle(
        fontSize: 17,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BrandDescription extends StatelessWidget {
  const _BrandDescription();

  @override
  Widget build(BuildContext context) {
    return Text(
      'الوصول إلى حسابك هو بداية رحلة منظمة لإدارة طلباتك ومتابعة خدماتك القانونية.',
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 15,
        height: 1.8,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: s.surface.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: s.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: s.onSurface,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: s.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final AsyncValue<void> state;
  final Color accent;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool telegramStarting;
  final VoidCallback onTelegram;
  final VoidCallback onGoogle;
  final bool isAdmin;

  const _LoginForm({
    required this.state,
    required this.accent,
    required this.formKey,
    required this.phoneController,
    required this.telegramStarting,
    required this.onTelegram,
    required this.onGoogle,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('العودة'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              Icons.lock_person_rounded,
              size: 34,
              color: s.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isAdmin ? 'دخول الإدارة' : 'تسجيل الدخول',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: s.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isAdmin
                ? 'الوصول إلى لوحة الإدارة للمستخدمين المخولين.'
                : 'أدخل رقم هاتفك للبدء والوصول إلى حسابك في استشارة.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: s.onSurfaceVariant,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'رقم الهاتف',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: s.onSurface,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '07xxxxxxxx',
                      prefixIcon: Icon(
                        Icons.phone_android_rounded,
                        color: accent,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'رقم الهاتف مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (telegramStarting || state.isLoading)
                          ? null
                          : onTelegram,
                      icon: telegramStarting
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        telegramStarting
                            ? 'جارٍ فتح Telegram...'
                            : 'الحصول على الرمز عبر Telegram',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'سيتم فتح Telegram تلقائياً لإتمام خطوة التحقق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: s.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: state.isLoading || telegramStarting ? null : onGoogle,
            icon: const Icon(
              Icons.g_mobiledata_rounded,
              size: 30,
              color: AppColors.primary,
            ),
            label: const Text(
              'المتابعة باستخدام Google',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'باستمرارك، أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: s.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => context.push('/terms'),
                child: const Text('الشروط'),
              ),
              Text(
                '•',
                style: TextStyle(color: s.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () => context.push('/privacy'),
                child: const Text('الخصوصية'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
