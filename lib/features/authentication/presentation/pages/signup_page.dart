import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  @override ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  String _role = 'user';

  @override void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  String _digits(String v) => v
      .replaceAllMapped(RegExp(r'[٠-٩]'), (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m.group(0)!).toString())
      .replaceAllMapped(RegExp(r'[۰-۹]'), (m) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(m.group(0)!).toString());

  String _phoneValue() {
    var p = _digits(_phone.text).trim().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[()\-]'), '');
    if (p.startsWith('+964')) p = p.substring(4);
    if (p.startsWith('00964')) p = p.substring(5);
    if (p.startsWith('964')) p = p.substring(3);
    if (p.startsWith('0')) p = p.substring(1);
    return '964$p';
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''), textDirection: TextDirection.rtl)));
  }

  Future<void> _start() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final data = await ref.read(authControllerProvider.notifier).startTelegramLogin(
        _phoneValue(), registration: true, fullName: _name.text.trim(), role: _role,
      );
      final token = data['request_token'] as String?;
      final link = data['telegram_url'] as String?;
      if (token == null || token.isEmpty || link == null || link.isEmpty) throw Exception('تعذر إنشاء طلب التسجيل.');
      final uri = Uri.parse(link);
      final opened = kIsWeb
          ? await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_self')
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('تعذر فتح Telegram.');
      if (mounted) await _verifyDialog(token);
    } catch (e) { _error(e); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _finish(String token) async {
    await ref.read(authControllerProvider.notifier).verifyTelegramLogin(requestToken: token, code: '');
    ref.invalidate(authStateChangesProvider);
    final user = await ref.read(authStateChangesProvider.future);
    if (user == null) throw Exception('تم التحقق لكن تعذر تثبيت جلسة الحساب.');
    if (mounted) context.go('/home');
  }

  Future<void> _verifyDialog(String token) async {
    final code = TextEditingController();
    Timer? timer;
    var closed = false, verifying = false, showCode = false;
    var message = 'تم فتح Telegram. اضغط «بدء» ثم اختر «مشاركة رقم الهاتف». بعد المطابقة سيتم إنشاء الحساب تلقائياً.';

    Future<void> check(StateSetter setStateDialog) async {
      if (closed || verifying) return;
      try {
        final r = await Supabase.instance.client.functions.invoke('telegram-auth-v2', body: {'action': 'status', 'request_token': token});
        final data = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
        final status = data['status']?.toString();
        if (status == 'telegram_verified') {
          setStateDialog(() { verifying = true; message = 'تم التحقق. جارٍ إنشاء الحساب...'; });
          try { await _finish(token); closed = true; timer?.cancel(); if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop(); }
          catch (e) { if (!closed && mounted) setStateDialog(() { verifying = false; message = e.toString().replaceFirst('Exception: ', ''); }); }
        } else if (status == 'code_sent' && !showCode) {
          setStateDialog(() { showCode = true; message = 'تم إرسال رمز التحقق. أدخل الرمز المكون من 6 أرقام.'; });
        } else if (status == 'expired') {
          closed = true; timer?.cancel(); if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop(); _error(Exception('انتهت صلاحية طلب Telegram. ابدأ التسجيل مرة أخرى.'));
        }
      } catch (_) {}
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (_) => check(setDialogState));
          return AlertDialog(
            title: const Text('تأكيد رقم الهاتف', textAlign: TextAlign.right),
            content: Directionality(textDirection: TextDirection.rtl, child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.telegram, size: 48), const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.right),
              if (!showCode) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
              if (showCode) ...[const SizedBox(height: 16), TextField(
                controller: code, keyboardType: TextInputType.number, textAlign: TextAlign.center, textDirection: TextDirection.ltr,
                maxLength: 6, autofocus: true, decoration: const InputDecoration(labelText: 'رمز التحقق', hintText: '000000', counterText: ''),
                onChanged: (v) { final n = _digits(v); if (n != v) code.value = code.value.copyWith(text: n, selection: TextSelection.collapsed(offset: n.length)); },
              )],
            ])),
            actions: [
              TextButton(onPressed: verifying ? null : () { closed = true; timer?.cancel(); Navigator.of(dialogContext).pop(); }, child: const Text('إلغاء')),
              if (showCode) FilledButton(
                onPressed: verifying ? null : () async {
                  final value = _digits(code.text).trim();
                  if (!RegExp(r'^\d{6}$').hasMatch(value)) { _error(Exception('أدخل رمز Telegram المكون من 6 أرقام.')); return; }
                  setDialogState(() => verifying = true);
                  try {
                    await ref.read(authControllerProvider.notifier).verifyTelegramLogin(requestToken: token, code: value);
                    ref.invalidate(authStateChangesProvider);
                    final user = await ref.read(authStateChangesProvider.future);
                    if (user == null) throw Exception('تم إنشاء الحساب لكن تعذر تثبيت جلسة الدخول.');
                    closed = true; timer?.cancel();
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (mounted) context.go('/home');
                  } catch (e) { if (dialogContext.mounted) setDialogState(() => verifying = false); _error(e); }
                },
                child: Text(verifying ? 'جارٍ الإنشاء...' : 'تأكيد وإنشاء الحساب'),
              ),
            ],
          );
        }),
      );
    } finally { closed = true; timer?.cancel(); code.dispose(); }
  }

  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: s.surface,
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560), child: Directionality(textDirection: TextDirection.rtl, child: Form(
          key: _formKey, child: Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextButton.icon(onPressed: _loading ? null : () => context.canPop() ? context.pop() : context.go('/'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('العودة')),
            const SizedBox(height: 12), Icon(Icons.person_add_alt_1_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 12), const Text('إنشاء حساب', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24), TextFormField(controller: _name, enabled: !_loading, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.trim().length < 3 ? 'أدخل الاسم الكامل' : null),
            const SizedBox(height: 16), const Text('نوع الحساب', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10),
            Row(children: [Expanded(child: _RoleCard(title: 'طالب استشارة', icon: Icons.person_search_outlined, selected: _role == 'user', onTap: _loading ? null : () => setState(() => _role = 'user'))), const SizedBox(width: 10), Expanded(child: _RoleCard(title: 'محامي', icon: Icons.gavel_rounded, selected: _role == 'lawyer', onTap: _loading ? null : () => setState(() => _role = 'lawyer')))]),
            const SizedBox(height: 16), TextFormField(controller: _phone, enabled: !_loading, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رقم الهاتف العراقي', hintText: '07xxxxxxxxx', prefixIcon: Icon(Icons.phone_android_rounded)), onChanged: (v) { final n = _digits(v); if (n != v) _phone.value = _phone.value.copyWith(text: n, selection: TextSelection.collapsed(offset: n.length)); }, validator: (v) { var p = _digits(v ?? '').replaceAll(RegExp(r'\s+'), ''); p = p.replaceFirst(RegExp(r'^\+964|^00964|^964|^0'), ''); return RegExp(r'^7\d{9}$').hasMatch(p) ? null : 'أدخل رقم هاتف عراقي صحيح'; }),
            const SizedBox(height: 18), SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _loading ? null : _start, icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.telegram), label: Text(_loading ? 'جارٍ تجهيز التسجيل...' : 'إنشاء الحساب عبر Telegram'))),
            const SizedBox(height: 14), OutlinedButton.icon(onPressed: _loading ? null : () async { try { await ref.read(authControllerProvider.notifier).signInWithGoogle(); } catch (e) { _error(e); } }, icon: const Icon(Icons.account_circle_outlined), label: const Text('المتابعة باستخدام Google')),
            const SizedBox(height: 12), TextButton(onPressed: _loading ? null : () => context.go('/login'), child: const Text('لديك حساب بالفعل؟ تسجيل الدخول')),
          ])),
        )),
      )))),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title; final IconData icon; final bool selected; final VoidCallback? onTap;
  const _RoleCard({required this.title, required this.icon, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) { final s = Theme.of(context).colorScheme; return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? s.primaryContainer : s.surfaceContainerHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? s.primary : s.outlineVariant, width: selected ? 2 : 1)), child: Row(children: [Icon(icon, color: selected ? s.primary : s.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)))])));
  }
}
