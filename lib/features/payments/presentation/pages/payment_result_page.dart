import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  final String? status;
  final String? bookingId;
  const PaymentResultPage({super.key, this.status, this.bookingId});

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  Timer? _pollTimer;
  bool _checking = false;
  String? _checkedStatus;
  String? _bookingStatus;
  String? _error;

  bool _isSuccess(String? value) {
    final status = value?.trim().toLowerCase();
    return status == 'success' || status == 'successful' || status == 'paid' || status == 'completed' || status == 'تم الدفع' || status == 'قيد مراجعة المحامي' || status == 'مؤكد';
  }

  bool _isFailed(String? value) {
    final status = value?.trim().toLowerCase();
    return status == 'failed' || status == 'authentication_failed' || status == 'فشل الدفع';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPaymentStatus();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (widget.bookingId == null || widget.bookingId!.isEmpty) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final status = _checkedStatus;
      if (_isSuccess(status) || _isFailed(status)) {
        _pollTimer?.cancel();
        return;
      }
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    final id = widget.bookingId;
    if (id == null || id.isEmpty || _checking || !mounted) return;
    setState(() { _checking = true; _error = null; });
    try {
      final response = await SupabaseConfig.client.functions.invoke('qicard-check-payment-status', body: {'booking_id': id});
      final data = response.data;
      if (data is! Map) throw Exception('تعذر التحقق من حالة الدفع');
      if (data['error'] != null) throw Exception(data['error'].toString());
      if (!mounted) return;
      final paymentStatus = data['payment_status']?.toString();
      final bookingStatus = data['booking_status']?.toString();
      setState(() { _checkedStatus = paymentStatus; _bookingStatus = bookingStatus; });
      if (_isSuccess(paymentStatus) || _isFailed(paymentStatus)) _pollTimer?.cancel();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _checkedStatus ?? widget.status;
    final success = _isSuccess(status);
    final failed = _isFailed(status);
    final title = success ? 'تم الدفع بنجاح' : failed ? 'لم تكتمل عملية الدفع' : 'التحقق من نتيجة الدفع';
    final message = success
        ? (_bookingStatus == 'مؤكد' ? 'تم تأكيد الحجز بنجاح.' : 'تم استلام الدفع بنجاح، والحجز بانتظار إجراءات المحامي.')
        : failed
            ? 'لم يتم اعتماد الدفع. يمكنك العودة إلى حجوزاتك لمعرفة الحالة.'
            : _checking ? 'جاري التحقق من حالة العملية لدى كي كارد...' : 'لم نتمكن من تأكيد النتيجة بعد. سيستمر التحقق تلقائياً.';
    final icon = success ? Icons.check_circle_outline_rounded : failed ? Icons.cancel_outlined : Icons.info_outline_rounded;
    final iconColor = success ? scheme.primary : failed ? scheme.error : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('نتيجة الدفع'), centerTitle: true, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 64, color: iconColor),
                ),
                const SizedBox(height: 24),
                Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
                  child: Text(message, textAlign: TextAlign.center, style: TextStyle(height: 1.6, color: scheme.onSurfaceVariant)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
                ],
                if (widget.bookingId != null && widget.bookingId!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('رقم الحجز: ${widget.bookingId}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 28),
                if (!success && !failed && !_checking && widget.bookingId != null)
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _checkPaymentStatus, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة التحقق من الدفع'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)))),
                if (!success && !failed && !_checking && widget.bookingId != null) const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => context.go('/bookings'), icon: const Icon(Icons.calendar_month_outlined), label: const Text('الانتقال إلى حجوزاتي'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
