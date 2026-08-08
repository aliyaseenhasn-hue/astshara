import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/bookings/domain/entities/booking.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../data/services/qicard_payment_service.dart';
import 'package:astshara/core/config/supabase_config.dart';

class PaymentUploadPage extends ConsumerStatefulWidget {
  final Booking booking;
  const PaymentUploadPage({super.key, required this.booking});

  @override
  ConsumerState<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends ConsumerState<PaymentUploadPage> {
  bool _loading = false;

  Future<void> _startQiCardPayment() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final service = QiCardPaymentService(SupabaseConfig.client);
      final formUrl = await service.createPayment(bookingId: widget.booking.id);
      final uri = Uri.tryParse(formUrl);
      if (uri == null || !(await canLaunchUrl(uri))) {
        throw Exception('تعذر فتح صفحة الدفع');
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل الدفع في صفحة كي كارد. سيتم تأكيد الحجز تلقائياً بعد نجاح العملية.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameAsync = ref.watch(userNameProvider(widget.booking.lawyerId));

    return Scaffold(
      appBar: AppBar(title: const Text('الدفع وتأكيد الحجز'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameAsync.when(
              data: (name) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('الدفع لاستشارة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'المحامي ${name ?? '...'}',
                      style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              'المبلغ المطلوب: ${widget.booking.price} د.ع',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Column(
                children: [
                  Icon(Icons.credit_card_rounded, size: 46, color: AppColors.gold),
                  SizedBox(height: 12),
                  Text('الدفع الإلكتروني عبر كي كارد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'يمكنك الدفع بأمان باستخدام وسائل الدفع المتاحة في بوابة كي كارد. لا يتم تخزين بيانات البطاقة داخل التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'لن يتم تأكيد الحجز أو إتاحة معلومات التواصل إلا بعد استلام إشعار نجاح الدفع والتحقق منه من الخادم.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.p32),
            _loading
                ? const LoadingWidget()
                : ElevatedButton.icon(
                    onPressed: _startQiCardPayment,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('الدفع الآن وتأكيد الحجز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
