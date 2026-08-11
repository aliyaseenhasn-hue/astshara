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
      final profile = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
      final profileId = profile?['id'] as String?;
      if (profileId == null) throw Exception('ملف المحامي غير مكتمل');
      final row = await SupabaseConfig.client.from('bookings').select().eq('lawyer_id', profileId).eq('manual_payment_required', true).isFilter('manual_received_at', null).inFilter('status', ['بانتظار التأكيد', 'قيد مراجعة المحامي']).order('scheduled_at', ascending: true).limit(1).maybeSingle();
      if (row != null) _booking = BookingModel.fromJson(Map<String, dynamic>.from(row)).toEntity();
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(title: const Text('تأكيد الدفع اليدوي')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadPendingBooking,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.payments_rounded, color: scheme.primary, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('دفعة مكتبية معلقة', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 6),
                      Text('يوجد حجز حضوري يحتاج إلى تسجيل المبلغ المستلم قبل بدء الاستشارة.', style: TextStyle(color: scheme.onPrimaryContainer, height: 1.45)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  _stateCard(context, Icons.error_outline_rounded, 'تعذر تحميل الحجز', _error!, 'إعادة المحاولة', _loadPendingBooking)
                else if (_booking == null)
                  _stateCard(context, Icons.check_circle_outline_rounded, 'لا توجد دفعات معلقة', 'لا توجد حالياً دفعة مكتبية تحتاج إلى تسجيل. يمكنك تحديث الصفحة للتحقق من جديد.', 'تحديث', _loadPendingBooking)
                else ...[
                  Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الحجز الحالي', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    const SizedBox(height: 16),
                    _row(context, 'رقم الحجز', _booking!.id.length >= 8 ? '#${_booking!.id.substring(0, 8)}' : '#${_booking!.id}'),
                    _row(context, 'رسوم الاستشارة', '${_booking!.price} د.ع'),
                    _row(context, 'الحالة', _booking!.status),
                  ])),
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lock_outline_rounded, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text('سجّل المبلغ الذي استلمته فعلياً فقط. بعد التأكيد سيُحدّث الحجز وتصبح الاستشارة جاهزة وفق شروطها.', style: TextStyle(color: scheme.onSurface, height: 1.5)))])),
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _openPayment, icon: const Icon(Icons.payments_outlined), label: const Text('تسجيل المبلغ المستلم'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$label: ', style: TextStyle(color: scheme.onSurfaceVariant)), Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)))]));
  }

  Widget _stateCard(BuildContext context, IconData icon, String title, String message, String action, VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(icon, size: 52, color: scheme.primary), const SizedBox(height: 14), Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: scheme.onSurface), textAlign: TextAlign.center), const SizedBox(height: 8), Text(message, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center), const SizedBox(height: 18), OutlinedButton.icon(onPressed: onPressed, icon: const Icon(Icons.refresh_rounded), label: Text(action))])));
  }
}
