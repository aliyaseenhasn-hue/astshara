import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user';
  bool _telegramStarting = false;

  @override
  void dispose() { _nameController.dispose(); _phoneController.dispose(); super.dispose(); }

  String _normalizePhone() {
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+964')) phone = phone.substring(4);
    if (phone.startsWith('964')) phone = phone.substring(3);
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '964$phone';
  }

  Future<void> _startPhoneSignup() async {
    if (_telegramStarting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _telegramStarting = true);
    try {
      final data = await ref.read(authControllerProvider.notifier).startTelegramLogin(_normalizePhone(), registration: true, fullName: _nameController.text.trim(), role: _selectedRole);
      final token = data['request_token'] as String;
      final telegramUrl = data['telegram_url'] as String;
      if (!await launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication)) throw Exception('تعذر فتح Telegram. تأكد من تثبيت التطبيق ثم حاول مرة أخرى.');
      if (mounted) await _showCodeDialog(token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error));
    } finally { if (mounted) setState(() => _telegramStarting = false); }
  }

  Future<void> _showCodeDialog(String requestToken) async {
    final controller = TextEditingController();
    var verifying = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('تأكيد رقم الهاتف', textAlign: TextAlign.right),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: const [Text('تم فتح Telegram. اضغط «بدء» إذا ظهرت، وسيصلك رمز تحقق من 6 أرقام داخل محادثة بوت استشارة.', textAlign: TextAlign.right), SizedBox(height: 16), Text('أدخل الرمز هنا بعد وصوله.', textAlign: TextAlign.right)]),
            actions: [
              TextButton(onPressed: verifying ? null : () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              FilledButton(onPressed: verifying ? null : () async {
                if (!RegExp(r'^\d{6}$').hasMatch(controller.text.trim())) return;
                setDialogState(() => verifying = true);
                try {
                  await ref.read(authControllerProvider.notifier).verifyTelegramLogin(requestToken: requestToken, code: controller.text.trim());
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (dialogContext.mounted) setDialogState(() => verifying = false);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error));
                }
              }, child: verifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('تأكيد وإنشاء الحساب')),
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
    return Scaffold(backgroundColor: scheme.surface, body: SafeArea(child: Directionality(textDirection: TextDirection.rtl, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120), child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final form = _SignupForm(formKey: _formKey, nameController: _nameController, phoneController: _phoneController, selectedRole: _selectedRole, loading: _telegramStarting || state.isLoading, onRoleChanged: (role) => setState(() => _selectedRole = role), onPhoneSignup: _startPhoneSignup, onGoogle: () => ref.read(authControllerProvider.notifier).signInWithGoogle());
      return wide ? Row(children: [const Expanded(child: _SignupBrand()), const SizedBox(width: 44), SizedBox(width: 480, child: form)]) : form;
    })))))));
  }
}

class _SignupBrand extends StatelessWidget {
  const _SignupBrand();
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(42), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [s.primaryContainer, s.surfaceContainerHighest]), borderRadius: BorderRadius.circular(34), border: Border.all(color: s.outlineVariant)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [Icon(Icons.balance_rounded, size: 58), SizedBox(height: 24), Text('أنشئ حسابك في استشارة', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 10), Text('ابدأ باستخدام رقم هاتفك عبر Telegram أو حساب Google، ثم أكمل بياناتك المهنية عند الحاجة.', style: TextStyle(fontSize: 15, height: 1.8)), SizedBox(height: 28), _SignupBenefit(icon: Icons.phone_android_rounded, title: 'رقم الهاتف', text: 'تحقق سريع وآمن من خلال رمز Telegram.'), SizedBox(height: 14), _SignupBenefit(icon: Icons.account_circle_outlined, title: 'حساب Google', text: 'تسجيل سريع دون الحاجة إلى كلمة مرور جديدة.'), SizedBox(height: 14), _SignupBenefit(icon: Icons.gavel_rounded, title: 'حساب المحامي', text: 'اختر نوع الحساب وأكمل الملف المهني بعد التسجيل.')])));
  }
}

class _SignupBenefit extends StatelessWidget {
  final IconData icon; final String title; final String text;
  const _SignupBenefit({required this.icon, required this.title, required this.text});
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(textDirection: TextDirection.rtl, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: s.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: s.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: s.onSurface)), Text(text, textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: s.onSurfaceVariant))]))]);
  }
}

class _SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey; final TextEditingController nameController; final TextEditingController phoneController; final String selectedRole; final bool loading; final ValueChanged<String> onRoleChanged; final VoidCallback onPhoneSignup; final VoidCallback onGoogle;
  const _SignupForm({required this.formKey, required this.nameController, required this.phoneController, required this.selectedRole, required this.loading, required this.onRoleChanged, required this.onPhoneSignup, required this.onGoogle});
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => context.canPop() ? context.pop() : context.go('/'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('العودة'))),
      const SizedBox(height: 8),
      Container(width: 68, height: 68, alignment: Alignment.center, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(21)), child: Icon(Icons.person_add_alt_1_rounded, size: 34, color: s.primary)),
      const SizedBox(height: 18), Text('إنشاء حساب', textAlign: TextAlign.right, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text('اختر نوع حسابك ثم سجّل باستخدام رقم الهاتف أو Google.', textAlign: TextAlign.right, style: TextStyle(color: s.onSurfaceVariant, height: 1.6, fontSize: 13)), const SizedBox(height: 22),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.trim().length < 3 ? 'أدخل الاسم الكامل' : null), const SizedBox(height: 14),
        Text('نوع الحساب', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: s.onSurface)), const SizedBox(height: 10),
        Row(children: [Expanded(child: _RoleCard(title: 'طالب استشارة', subtitle: 'أبحث عن مساعدة قانونية', icon: Icons.person_search_outlined, selected: selectedRole == 'user', onTap: () => onRoleChanged('user'))), const SizedBox(width: 10), Expanded(child: _RoleCard(title: 'محامي', subtitle: 'أقدم خدمات قانونية', icon: Icons.gavel_rounded, selected: selectedRole == 'lawyer', onTap: () => onRoleChanged('lawyer')))]), const SizedBox(height: 18),
        TextFormField(controller: phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رقم الهاتف العراقي', hintText: '07xxxxxxxxx', prefixIcon: Icon(Icons.phone_android_rounded)), validator: (v) { final value = v?.replaceAll(RegExp(r'\s+'), '') ?? ''; if (!RegExp(r'^(?:\+?964|0)?7\d{9}$').hasMatch(value)) return 'أدخل رقم هاتف عراقي صحيح'; return null; }), const SizedBox(height: 14),
        SizedBox(height: 52, child: ElevatedButton.icon(onPressed: loading ? null : onPhoneSignup, icon: loading ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(loading ? 'جارٍ تجهيز التسجيل...' : 'التسجيل برقم الهاتف عبر Telegram', style: const TextStyle(fontWeight: FontWeight.w800)))), const SizedBox(height: 18),
        Row(children: [Expanded(child: Divider(color: s.outlineVariant)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('أو', style: TextStyle(color: s.onSurfaceVariant))), Expanded(child: Divider(color: s.outlineVariant))]), const SizedBox(height: 18), SizedBox(height: 52, child: OutlinedButton.icon(onPressed: loading ? null : onGoogle, icon: const Icon(Icons.account_circle_outlined), label: const Text('المتابعة باستخدام Google', style: TextStyle(fontWeight: FontWeight.w800)))),
      ]))),
      const SizedBox(height: 12),
      TextButton(onPressed: loading ? null : () => context.push('/login'), child: Text('لديك حساب بالفعل؟ تسجيل الدخول', style: TextStyle(color: s.primary, fontWeight: FontWeight.w700))),
      const SizedBox(height: 8), Text('بالمتابعة، أنت توافق على شروط الاستخدام وسياسة الخصوصية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: s.onSurfaceVariant)),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final String title, subtitle; final IconData icon; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(minHeight: 108), decoration: BoxDecoration(color: selected ? s.primaryContainer : s.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? s.primary : s.outlineVariant, width: selected ? 1.6 : 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Icon(icon, color: selected ? s.primary : s.onSurfaceVariant), const Spacer(), Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: s.onSurface)), const SizedBox(height: 3), Text(subtitle, textAlign: TextAlign.right, style: TextStyle(fontSize: 9.5, color: s.onSurfaceVariant))]))));
  }
}
