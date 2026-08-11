import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    var phone = _phoneController.text.trim().replaceAll(' ', '');
    if (phone.startsWith('+964')) {
      phone = phone.substring(4);
    }
    if (phone.startsWith('964')) {
      phone = phone.substring(3);
    }
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    final formattedPhone = '964$phone';

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPhone(formattedPhone);

      if (mounted) {
        context.push('/otp', extra: formattedPhone);
      }
    } catch (_) {
      // The provider exposes the error through authControllerProvider.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is AuthException
              ? error.message
              : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: scheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          size: 42,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      widget.isAdminLogin
                          ? 'دخول الإدارة'
                          : 'مرحباً بك في استشارة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isAdminLogin
                          ? 'سجل الدخول للوصول إلى لوحة الإدارة.'
                          : 'منصتك القانونية الموثوقة للاستشارات في العراق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رقم الهاتف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 17,
                            ),
                            decoration: InputDecoration(
                              hintText: '07xxxxxxxx',
                              prefixIcon: Icon(
                                Icons.phone_android_rounded,
                                color: scheme.primary,
                              ),
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: scheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'رقم الهاتف مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          if (state.isLoading)
                            const LoadingWidget()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.sms_outlined),
                                label: const Text('إرسال رمز التحقق'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: scheme.outlineVariant),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'أو',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: scheme.outlineVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                      icon: Icon(
                        Icons.g_mobiledata_rounded,
                        size: 30,
                        color: scheme.primary,
                      ),
                      label: const Text('المتابعة باستخدام Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'باستمرارك، أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
