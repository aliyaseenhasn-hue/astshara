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
  Future<void> _startQiCardPayment() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final formUrl = await QiCardPaymentService(SupabaseConfig.client).createPayment(bookingId: widget.booking.id);
      final uri = Uri.tryParse(formUrl);
      if (uri == null || !(await canLaunchUrl(uri))) throw Exception('تعذر فتح صفحة الدفع');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال عملية الدفع إلى بوابة كي كارد. ستبقى الحالة «قيد معالجة الدفع» حتى تعتمد الإدارة الدفع.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إرسال الدفع'), centerTitle: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(14)), child: Column(children: [const Text('المبلغ المطلوب', style: TextStyle(color: Colors.white70)), const SizedBox(height: 6), Text('${widget.booking.price} د.ع', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold))])),
        const SizedBox(height: 20),
        const Text('حالة الحجز الحالية: قيد انتظار الدفع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 20),
        const Text('بعد إرسال الدفع تصبح العملية «قيد معالجة الدفع». اعتماد الإدارة للدفع هو الذي ينقل الحجز إلى «مؤكد».', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 28),
        _loading ? const LoadingWidget() : ElevatedButton.icon(onPressed: _startQiCardPayment, icon: const Icon(Icons.lock_outline), label: const Text('إرسال الدفع'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
      ]),
    ),
  );
}
