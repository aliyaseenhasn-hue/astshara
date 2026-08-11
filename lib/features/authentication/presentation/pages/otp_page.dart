import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
    if (_otpController.text.length == 6) {
      await ref.read(authControllerProvider.notifier).verifyOTP(widget.phone, _otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(error: (_, __) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح'), backgroundColor: AppColors.error)));
    });

    return Scaffold(
      backgroundColor: AppColors.secondaryDark,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.secondaryDark, AppColors.primaryDark, AppColors.goldDark], stops: [0, .58, 1])),
        child: SafeArea(
          child: Stack(children: [
            Positioned(top: -50, right: -55, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withValues(alpha: .25), width: 24)))),
            Positioned(bottom: -55, left: -35, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.goldLight.withValues(alpha: .18), width: 18)))),
            Column(children: [
              Align(alignment: AlignmentDirectional.topStart, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(AppSizes.p32, 20, AppSizes.p32, 32), child: Column(children: [
                const SizedBox(height: 30),
                Container(width: 70, height: 70, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.mark_email_read_outlined, size: 38, color: AppColors.secondaryDark)),
                const SizedBox(height: 26),
                const Text('تحقق من الرقم', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text('تم إرسال رمز مكون من 6 أرقام إلى\n${widget.phone}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.6)),
                const SizedBox(height: 38),
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: .35), letterSpacing: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.gold.withValues(alpha: .35))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.gold.withValues(alpha: .35))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  onChanged: (v) { if (v.length == 6) _verify(); },
                ),
                const SizedBox(height: 28),
                state.isLoading ? const LoadingWidget() : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verify, style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.secondaryDark, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('تأكيد ودخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('تغيير رقم الهاتف', style: TextStyle(color: AppColors.goldLight))),
              ]))),
            ]),
          ]),
        ),
      ),
    );
  }
}
