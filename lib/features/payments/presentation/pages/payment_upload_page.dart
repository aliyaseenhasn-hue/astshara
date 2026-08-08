import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/bookings/domain/entities/booking.dart';
import 'package:astshara/features/bookings/presentation/providers/bookings_provider.dart';
import '../../data/services/qicard_payment_service.dart';
import 'package:astshara/core/config/supabase_config.dart';

class PaymentUploadPage extends ConsumerStatefulWidget {
  final Booking booking;
  const PaymentUploadPage({super.key, required this.booking});
  @override
  ConsumerState<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends ConsumerState<PaymentUploadPage> with WidgetsBindingObserver {
  bool _loading = false;
  bool _checkingPayment = false;
  bool _opened = false;
  String? _error;
  Timer? _pollTimer;
  QiCardPaymentService get _paymentService => QiCardPaymentService(SupabaseConfig.client);

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { _pollTimer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPaymentStatus(showErrors: false);
  }

  Future<void> _startQiCardPayment() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final formUrl = await _paymentService.createPayment(bookingId: widget.booking.id);
      final uri = Uri.tryParse(formUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) throw Exception('رابط الدفع المستلم غير صالح');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (!launched) throw Exception('تعذر فتح صفحة الدفع الآمنة لكي كارد');
      if (!mounted) return;
      setState(() => _opened = true);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPaymentStatus(showErrors: false));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح بوابة كي كارد. بعد إتمام الدفع سيجري تحديث حالة الحجز تلقائياً.')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _refreshBookingAfterPayment() async {
    ref.invalidate(userBookingsProvider);
    ref.invalidate(lawyerBookingsProvider);
    try {
      final bookings = await ref.read(userBookingsProvider.future);
      final updated = bookings.cast<Booking?>().firstWhere((b) => b?.id == widget.booking.id, orElse: () => null);
      if (!mounted) return;
      if (updated != null) { context.go('/booking-details', extra: updated); return; }
    } catch (_) {}
    if (mounted) context.go('/bookings');
  }

  Future<void> _checkPaymentStatus({required bool showErrors}) async {
    if (_checkingPayment || !mounted) return;
    _checkingPayment = true;
    try {
      final result = await _paymentService.checkPaymentStatus(bookingId: widget.booking.id);
      final paymentStatus = result['payment_status']?.toString();
      final bookingStatus = result['booking_status']?.toString();
      if (!mounted) return;
      if (paymentStatus == 'تم الدفع' || bookingStatus == 'مؤكد' || bookingStatus == 'قيد مراجعة المحامي') {
        _pollTimer?.cancel();
        await _refreshBookingAfterPayment();
        return;
      }
      if (paymentStatus == 'فشل الدفع') {
        _pollTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم تكتمل عملية الدفع. يمكنك المحاولة مرة أخرى.'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (showErrors && mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { _checkingPayment = false; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إكمال الدفع'), centerTitle: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(14)), child: Column(children: [
          const Text('المبلغ المطلوب', style: TextStyle(color: Colors.white70)), const SizedBox(height: 6),
          Text('${widget.booking.price} د.ع', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 20),
        const Text('طريقة الدفع: كي كارد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('اضغط على الزر للانتقال إلى صفحة الدفع الآمنة الخاصة بكي كارد وإكمال العملية. لا يتم إدخال بيانات البطاقة داخل تطبيق الاستشارة.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 28),
        if (_error != null) ...[
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error))),
          const SizedBox(height: 12),
        ],
        _loading ? const LoadingWidget() : ElevatedButton.icon(onPressed: _startQiCardPayment, icon: Icon(_opened ? Icons.refresh : Icons.lock_outline), label: Text(_opened ? 'إعادة فتح صفحة الدفع' : 'إكمال الدفع بواسطة كي كارد'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _checkingPayment ? null : () => _checkPaymentStatus(showErrors: true), icon: const Icon(Icons.refresh_rounded), label: const Text('تحقق من حالة الدفع')),
      ]),
    ),
  );
}
