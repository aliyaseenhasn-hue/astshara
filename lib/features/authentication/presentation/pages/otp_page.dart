import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
    if (_otpController.text.trim().length == 6) {
      await ref.read(authControllerProvider.notifier).verifyOTP(widget.phone, _otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.gold : scheme.primary;
    final state = ref.watch(authControllerProvider);
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(error: (_, __) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح'))));
    });
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(leading: const BackButton(), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Stack(children: [
          Positioned(top: -80, left: -100, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .06)))),
          Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 40), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 80, height: 80, alignment: Alignment.center, decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest : scheme.primaryContainer, borderRadius: BorderRadius.circular(26), border: Border.all(color: accent.withValues(alpha: .35))), child: Icon(Icons.shield_rounded, size: 42, color: accent)),
            const SizedBox(height: 25),
            Text('تحقق من رقم الهاتف', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: scheme.onSurface)),
            const SizedBox(height: 9),
            Text('أدخل رمز التحقق المكون من 6 أرقام\nالمرسل إلى ${widget.phone}', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.65)),
            const SizedBox(height: 28),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .72) : scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant)), child: Column(children: [
              TextField(controller: _otpController, autofocus: true, decoration: InputDecoration(hintText: '000000', filled: true, fillColor: scheme.surfaceContainerHighest, counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: scheme.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: accent, width: 2))), keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: TextStyle(fontSize: 29, letterSpacing: 11, fontWeight: FontWeight.w900, color: scheme.onSurface), onChanged: (v) { if (v.length == 6) _verify(); }),
              const SizedBox(height: 18),
              if (state.isLoading) const LoadingWidget() else SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verify, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: dark ? accent : scheme.primary, foregroundColor: dark ? Colors.black : scheme.onPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('تأكيد ودخول', style: TextStyle(fontWeight: FontWeight.w800)))),
            ])),
            const SizedBox(height: 14),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('تغيير رقم الهاتف', style: TextStyle(color: accent, fontWeight: FontWeight.w700))),
          ]))))
        ]),
      ),
    );
  }
}
