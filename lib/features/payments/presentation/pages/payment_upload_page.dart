import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/bookings/domain/entities/booking.dart';
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
  bool _opened = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPayment());
  }

  Future<void> _openPayment() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final formUrl = await QiCardPaymentService(SupabaseConfig.client)
          .createPayment(bookingId: widget.booking.id);
      final uri = Uri.tryParse(formUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw Exception('رابط الدفع المستلم غير صالح');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched) throw Exception('تعذر فتح صفحة الدفع الآمنة لكي كارد');

      if (mounted) {
        setState(() => _opened = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح صفحة الدفع الآمنة لكي كارد. أكمل الدفع ثم عد إلى التطبيق.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('إكمال الدفع'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('المبلغ المطلوب', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.booking.price} د.ع',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'طريقة الدفع: كي كارد',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم فتح صفحة الدفع الآمنة الخاصة بكي كارد لإكمال العملية. لا يتم إدخال بيانات البطاقة داخل تطبيق الاستشارة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_loading)
                const LoadingWidget()
              else
                ElevatedButton.icon(
                  onPressed: _openPayment,
                  icon: Icon(_opened ? Icons.refresh : Icons.lock_outline),
                  label: Text(_opened ? 'إعادة فتح صفحة الدفع' : 'فتح صفحة الدفع بواسطة كي كارد'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF81C7F5),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_opened) ...[
                const SizedBox(height: 16),
                const Text(
                  'بعد إكمال الدفع ستتم إعادتك إلى صفحة نتيجة الدفع، وسيتم التحقق من العملية لدى كي كارد قبل تأكيد الحجز.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      );
}
