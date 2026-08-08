import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class PaymentResultPage extends StatelessWidget {
  final String? status;
  final String? bookingId;

  const PaymentResultPage({
    super.key,
    this.status,
    this.bookingId,
  });

  bool get _isSuccess {
    final value = status?.trim().toLowerCase();
    return value == 'success' || value == 'successful' || value == 'paid' || value == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    final success = _isSuccess;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة الدفع'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.info_outline,
                size: 84,
                color: success ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'تم استلام نتيجة الدفع' : 'تمت العودة من بوابة الدفع',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? 'سيتم تحديث حالة الحجز بعد التحقق من عملية الدفع.'
                    : 'يرجى التحقق من حالة الحجز من صفحة حجوزاتي. لا نعتبر الدفع ناجحاً اعتماداً على رابط العودة وحده.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.6, color: AppColors.textSecondary),
              ),
              if (bookingId != null && bookingId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'رقم الحجز: $bookingId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/bookings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('الانتقال إلى حجوزاتي'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
