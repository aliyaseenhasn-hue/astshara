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
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.length == 6) {
      await ref.read(authControllerProvider.notifier).verifyOTP(
            widget.phone,
            _otpController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('رمز التحقق غير صحيح'),
                backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('تحقق من الرقم'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.mark_email_read_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'أدخل رمز التحقق',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'تم إرسال رمز مكون من 6 أرقام إلى\n ${widget.phone}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.outline),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                hintText: '000000',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
              onChanged: (v) {
                if (v.length == 6) _verify();
              },
            ),
            const SizedBox(height: 32),
            state.isLoading
                ? const LoadingWidget()
                : ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('تأكيد ودخول',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تغيير رقم الهاتف',
                  style: TextStyle(color: AppColors.outline)),
            ),
          ],
        ),
      ),
    );
  }
}
