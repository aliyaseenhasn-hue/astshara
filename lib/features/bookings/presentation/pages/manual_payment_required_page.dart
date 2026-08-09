import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/models/booking_model.dart';
import '../../domain/entities/booking.dart';

class ManualPaymentRequiredPage extends StatefulWidget {
  const ManualPaymentRequiredPage({super.key});

  @override
  State<ManualPaymentRequiredPage> createState() => _ManualPaymentRequiredPageState();
}

class _ManualPaymentRequiredPageState extends State<ManualPaymentRequiredPage> {
  bool _loading = true;
  String? _error;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    _loadPendingBooking();
  }

  Future<void> _loadPendingBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();
      final profileId = profile?['id'] as String?;
      if (profileId == null) throw Exception('ملف المحامي غير مكتمل');

      final row = await SupabaseConfig.client
          .from('bookings')
          .select()
          .eq('lawyer_id', profileId)
          .eq('manual_payment_required', true)
          .isFilter('manual_received_at', null)
          .inFilter('status', ['بانتظار التأكيد', 'قيد مراجعة المحامي'])
          .order('scheduled_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        _booking = BookingModel.fromJson(Map<String, dynamic>.from(row)).toEntity();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPayment() {
    final booking = _booking;
    if (booking == null) return;
    context.push('/manual-payment', extra: booking).then((_) => _loadPendingBooking());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('تأكيد الدفع اليدوي')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadPendingBooking, child: const Text('إعادة المحاولة')),
                        ],
                      )
                    : _booking == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
                              const SizedBox(height: 16),
                              const Text('لا توجد دفعات يدوية معلقة حالياً.', textAlign: TextAlign.center),
                            ],
                          )
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'يوجد حجز مكتبي بانتظار تسجيل المبلغ المستلم.',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text('رسوم الاستشارة: ${_booking!.price} د.ع', textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'لن تتمكن من استخدام ميزات المحامي أو بدء أي استشارة حتى يتم تسجيل المبلغ المستلم من الموكل.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _openPayment,
                                    icon: const Icon(Icons.payments_outlined),
                                    label: const Text('تسجيل المبلغ المستلم'),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}
