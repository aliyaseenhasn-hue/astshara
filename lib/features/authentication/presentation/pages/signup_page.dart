import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
  bool _obscurePassword = true;
  String _selectedRole = 'user';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signUp(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
          _nameController.text.trim(),
          _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
              backgroundColor: scheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text('إنشاء حساب'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 38,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'أنشئ حسابك في استشارة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر نوع الحساب المناسب لك ثم أكمل بيانات التسجيل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.55),
                    ),
                    const SizedBox(height: 28),
                    _FieldCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) => value == null || value.trim().length < 3
                                ? 'أدخل الاسم الكامل'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'البريد الإلكتروني مطلوب';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                return 'أدخل بريداً إلكترونياً صحيحاً';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => value == null || value.length < 6
                                ? 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'نوع الحساب',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            title: 'طالب استشارة',
                            subtitle: 'أبحث عن مساعدة قانونية',
                            icon: Icons.person_search_outlined,
                            selected: _selectedRole == 'user',
                            onTap: () => setState(() => _selectedRole = 'user'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            title: 'محامي',
                            subtitle: 'أقدم خدمات قانونية',
                            icon: Icons.gavel_rounded,
                            selected: _selectedRole == 'lawyer',
                            onTap: () => setState(() => _selectedRole = 'lawyer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    state.isLoading
                        ? const LoadingWidget()
                        : SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('إنشاء الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: state.isLoading ? null : () => context.pop(),
                      child: Text(
                        'لديك حساب بالفعل؟ تسجيل الدخول',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'حساب الإدارة لا يتم إنشاؤه من التسجيل العام.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
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

class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 122),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 27),
              const Spacer(),
              Text(title, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
