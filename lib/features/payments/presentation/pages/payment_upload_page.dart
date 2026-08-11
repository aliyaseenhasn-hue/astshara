import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/bookings/domain/entities/booking.dart';
import 'package:astshara/features/bookings/presentation/providers/bookings_provider.dart';
import '../../data/services/qicard_payment_service.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      if (uri == null || !(await canLaunchUrl(uri))) throw Exception('تعذر فتح صفحة الدفع');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('تعذر فتح صفحة الدفع الآمنة لكي كارد');
      if (!mounted) return;
      setState(() => _opened = true);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPaymentStatus(showErrors: false));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح بوابة كي كارد. بعد إتمام الدفع سيجري تحديث حالة الحجز تلقائياً.')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshBookingAfterPayment() async {
    ref.invalidate(userBookingsProvider);
    ref.invalidate(lawyerBookingsProvider);
    try {
      final bookings = await ref.read(userBookingsProvider.future);
      Booking? updated;
      for (final booking in bookings) {
        if (booking.id == widget.booking.id) { updated = booking; break; }
      }
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
      if (paymentStatus == 'تم الدفع' || bookingStatus == 'قيد مراجعة المحامي' || bookingStatus == 'مؤكد') {
        _pollTimer?.cancel();
        await _refreshBookingAfterPayment();
        return;
      }
      if (paymentStatus == 'فشل الدفع') {
        _pollTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم تكتمل عملية الدفع. يمكنك المحاولة مرة أخرى.')));
      }
    } catch (e) {
      if (showErrors && mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _checkingPayment = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('إكمال الدفع'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 34, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('المبلغ المطلوب', style: TextStyle(color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 6),
                  Text('${widget.booking.price} د.ع', style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 28, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outlineVariant)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.lock_outline_rounded, color: scheme.primary), const SizedBox(width: 10), Text('الدفع الآمن', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface))]),
                    const SizedBox(height: 12),
                    Text('طريقة الدفع: كي كارد', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
                    const SizedBox(height: 8),
                    Text('سيتم نقلك إلى صفحة الدفع الآمنة الخاصة بكي كارد. لا يتم إدخال بيانات البطاقة داخل تطبيق الاستشارة.', style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(14)), child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onErrorContainer))),
                const SizedBox(height: 12),
              ],
              _loading
                  ? const LoadingWidget()
                  : ElevatedButton.icon(
                      onPressed: _startQiCardPayment,
                      icon: Icon(_opened ? Icons.refresh_rounded : Icons.lock_outline_rounded),
                      label: Text(_opened ? 'إعادة فتح صفحة الدفع' : 'إكمال الدفع بواسطة كي كارد'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _checkingPayment ? null : () => _checkPaymentStatus(showErrors: true),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('تحقق من حالة الدفع'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 20),
              Center(child: TextButton.icon(onPressed: () => context.go('/bookings'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('العودة إلى حجوزاتي'))),
            ],
          ),
        ),
      ),
    );
  }
}
