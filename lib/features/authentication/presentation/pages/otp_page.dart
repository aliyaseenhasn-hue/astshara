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
    final state = ref.watch(authControllerProvider);
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(error: (_, __) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح'))));
    });
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.shield_rounded, size: 42, color: AppColors.primaryFixed),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تحقق من رقم الهاتف',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل رمز التحقق المكون من 6 أرقام\nالمرسل إلى ${widget.phone}',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _otpController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '000000',
                            filled: true,
                            fillColor: AppColors.surfaceContainerHigh,
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 29,
                            letterSpacing: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          onChanged: (v) { if (v.length == 6) _verify(); },
                        ),
                        const SizedBox(height: 18),
                        if (state.isLoading)
                          const LoadingWidget()
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _verify,
                              child: const Text('تأكيد ودخول'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('تغيير رقم الهاتف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
