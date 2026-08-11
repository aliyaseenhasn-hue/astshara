import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});
  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();
  @override
  void dispose() { _otpController.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_otpController.text.length == 6) await ref.read(authControllerProvider.notifier).verifyOTP(widget.phone, _otpController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(authControllerProvider);
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(error: (_, __) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح'))));
    });
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 72, height: 72, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(22)), child: Icon(Icons.verified_user_outlined, size: 38, color: scheme.primary)),
        const SizedBox(height: 28),
        Text('تحقق من رقم الهاتف', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 10),
        Text('أدخل رمز التحقق المكون من 6 أرقام المرسل إلى\n${widget.phone}', style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6)),
        const SizedBox(height: 36),
        TextField(controller: _otpController, decoration: InputDecoration(hintText: '000000', filled: true, fillColor: scheme.surfaceContainerHighest, counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2))), keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.bold, color: scheme.onSurface), onChanged: (v) { if (v.length == 6) _verify(); }),
        const SizedBox(height: 24),
        state.isLoading ? const LoadingWidget() : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verify, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: const Text('تأكيد ودخول', style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('تغيير رقم الهاتف', style: TextStyle(color: scheme.primary))),
      ])),
    );
  }
}
