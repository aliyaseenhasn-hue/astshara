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
  @override ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  Timer? _timer;
  String? _token;
  bool _busy = false, _checking = false;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); _phone.dispose(); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token != null) Future.delayed(const Duration(milliseconds: 250), _check);
  }

  String _digits(String v) => v
      .replaceAllMapped(RegExp(r'[٠-٩]'), (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m.group(0)!).toString())
      .replaceAllMapped(RegExp(r'[۰-۹]'), (m) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(m.group(0)!).toString());

  String _normalizedPhone() {
    var p = _digits(_phone.text).replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[()\-]'), '');
    if (p.startsWith('+964')) p = p.substring(4);
    if (p.startsWith('00964')) p = p.substring(5);
    if (p.startsWith('964')) p = p.substring(3);
    if (p.startsWith('0')) p = p.substring(1);
    return '964$p';
  }

  void _error(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''), textDirection: TextDirection.rtl)));

  Future<void> _openTelegram(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    if (!ok) throw Exception('تعذر فتح Telegram. اضغط «فتح Telegram» مرة أخرى.');
  }

  Future<void> _start() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final d = await ref.read(authControllerProvider.notifier).startTelegramLogin(_normalizedPhone());
      _token = d['request_token'] as String;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _check());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تسجيل الدخول عبر Telegram', textAlign: TextAlign.right),
          content: const Directionality(textDirection: TextDirection.rtl, child: Text('افتح Telegram واضغط «بدء» ثم اختر «مشاركة رقم الهاتف». بعد نجاح التحقق اضغط «متابعة» هنا.')),
          actions: [
            TextButton(onPressed: _checking ? null : () { _cancelTelegram(); Navigator.of(dialogContext).pop(); }, child: const Text('إلغاء')),
            FilledButton.icon(onPressed: _checking ? null : () async { try { await _openTelegram(d['telegram_url'] as String); } catch (e) { if (mounted) _error(e); } }, icon: const Icon(Icons.telegram), label: const Text('فتح Telegram')),
            FilledButton(onPressed: _checking ? null : _check, child: Text(_checking ? 'جارٍ الدخول...' : 'متابعة')),
          ],
        ),
      );
    } catch (e) { if (mounted) _error(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _check() async {
    final token = _token;
    if (token == null || _checking) return;
    try {
      final r = await Supabase.instance.client.functions.invoke('telegram-auth-v2', body: {'action': 'status', 'request_token': token});
      if (r.data is! Map) return;
      final status = (r.data as Map)['status']?.toString();
      if (status == 'telegram_verified') {
        _checking = true;
        if (mounted) setState(() {});
        try {
          await ref.read(authControllerProvider.notifier).verifyTelegramLogin(requestToken: token, code: '');
          final user = await ref.read(authRepositoryProvider).getCurrentUser();
          if (user == null) throw Exception('تم التحقق لكن لم يتم تثبيت جلسة الدخول.');
          ref.invalidate(authStateChangesProvider);
          final synced = await ref.read(authStateChangesProvider.future);
          if (synced == null) throw Exception('تم التحقق لكن لم تتم مزامنة جلسة التطبيق.');
          _timer?.cancel(); _token = null;
          if (!mounted) return;
          Navigator.of(context).pop();
          context.go('/home');
        } catch (e) {
          _checking = false;
          if (mounted) { setState(() {}); _error(e); }
        }
      } else if (status == 'expired') {
        _cancelTelegram();
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
        if (mounted) _error(Exception('انتهت صلاحية طلب Telegram. حاول مرة أخرى.'));
      }
    } catch (_) {}
  }

  void _cancelTelegram() { _timer?.cancel(); _timer = null; _token = null; _checking = false; }
  Future<void> _google() async { try { await ref.read(authControllerProvider.notifier).signInWithGoogle(); } catch (e) { if (mounted) _error(e); } }

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => context.canPop() ? context.pop() : context.go('/'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('العودة'))),
                          const SizedBox(height: 12),
                          Icon(Icons.balance_rounded, size: 54, color: AppColors.primary),
                          const SizedBox(height: 14),
                          Text(widget.isAdminLogin ? 'دخول الإدارة' : 'تسجيل الدخول', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          const Text('أدخل رقم هاتفك العراقي لإتمام الدخول بأمان عبر Telegram.', textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          TextFormField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رقم الهاتف العراقي', hintText: '07xxxxxxxxx أو ٠٧xxxxxxxxx', prefixIcon: Icon(Icons.phone_android_rounded)), validator: (v) { final p = _digits(v ?? '').replaceAll(RegExp(r'\s+'), ''); final d = p.replaceFirst(RegExp(r'^\+964|^00964|^964|^0'), ''); return RegExp(r'^7\d{9}$').hasMatch(d) ? null : 'أدخل رقم هاتف عراقي صحيح مثل 07701234567'; }),
                          const SizedBox(height: 16),
                          SizedBox(height: 52, child: ElevatedButton.icon(onPressed: (_busy || auth.isLoading) ? null : _start, icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(_busy ? 'جارٍ تجهيز Telegram...' : 'تسجيل الدخول عبر Telegram'))),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(onPressed: auth.isLoading ? null : _google, icon: const Icon(Icons.account_circle_outlined), label: const Text('المتابعة باستخدام Google')),
                          const SizedBox(height: 16),
                          TextButton(onPressed: () => context.go('/signup'), child: const Text('ليس لديك حساب؟ إنشاء حساب جديد')),
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
