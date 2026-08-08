import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/supabase_config.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  final String? status;
  final String? bookingId;

  const PaymentResultPage({
    super.key,
    this.status,
    this.bookingId,
  });

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  bool _checking = false;
  String? _checkedStatus;
  String? _bookingStatus;
  String? _error;

  bool _isSuccess(String? value) {
    final status = value?.trim().toLowerCase();
    return status == 'success' ||
        status == 'successful' ||
        status == 'paid' ||
        status == 'completed' ||
        status == 'تم الدفع' ||
        status == 'قيد مراجعة المحامي' ||
        status == 'مؤكد';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPaymentStatus());
  }

  Future<void> _checkPaymentStatus() async {
    final id = widget.bookingId;
    if (id == null || id.isEmpty || _checking) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'qicard-check-payment-status',
        body: {'booking_id': id},
      );
      final data = response.data;
      if (data is! Map) throw Exception('تعذر التحقق من حالة الدفع');
      if (data['error'] != null) throw Exception(data['error'].toString());
      if (!mounted) return;

      setState(() {
        _checkedStatus = data['payment_status']?.toString();
        _bookingStatus = data['booking_status']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _checkedStatus ?? widget.status;
    final success = _isSuccess(status);
    final failed = status?.trim().toLowerCase() == 'failed' ||
        status?.trim() == 'فشل الدفع';

    final title = success
        ? 'تم الدفع بنجاح'
        : failed
            ? 'لم تكتمل عملية الدفع'
            : 'التحقق من نتيجة الدفع';

    final message = success
        ? (_bookingStatus == 'مؤكد'
            ? 'تم تأكيد الحجز بنجاح.'
            : 'تم استلام الدفع بنجاح، والحجز بانتظار إجراءات المحامي.')
        : failed
            ? 'لم يتم اعتماد الدفع. يمكنك العودة إلى حجوزاتك لمعرفة الحالة.'
            : _checking
                ? 'جاري التحقق من حالة العملية لدى كي كارد...'
                : 'لم نتمكن من تأكيد النتيجة بعد. أعد المحاولة بعد لحظات.';

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
                success
                    ? Icons.check_circle_outline
                    : failed
                        ? Icons.cancel_outlined
                        : Icons.info_outline,
                size: 84,
                color: success
                    ? AppColors.success
                    : failed
                        ? AppColors.error
                        : AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              if (widget.bookingId != null && widget.bookingId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'رقم الحجز: ${widget.bookingId}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 28),
              if (!success && !_checking && widget.bookingId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _checkPaymentStatus,
                    child: const Text('إعادة التحقق من الدفع'),
                  ),
                ),
              const SizedBox(height: 12),
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
