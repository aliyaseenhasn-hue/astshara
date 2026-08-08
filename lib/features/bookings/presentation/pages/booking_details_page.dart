import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../reviews/presentation/widgets/review_dialog.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';

class BookingDetailsPage extends ConsumerWidget {
  final Booking booking;
  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(bookingPaymentProvider(booking.id));
    final detailsAsync = ref.watch(bookingDetailsProvider(booking.id));
    final owner = ref.watch(authStateChangesProvider).value;
    final isLawyer = owner?.role == 'lawyer';
    final isOwner = !isLawyer && owner?.id == booking.userId;
    final contactAsync = isOwner && ['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status) ? ref.watch(bookingContactProvider(booking.id)) : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الاستشارة'), backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _statusHeader(), const SizedBox(height: 20),
          _section('بيانات الحجز', Icons.calendar_month_outlined, detailsAsync.when(
            data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('الباقة', d?['package_name'] ?? 'غير محددة'), _row('طريقة الاستشارة', d?['consultation_type'] ?? 'غير محددة'),
              _row('التاريخ', DateFormat('yyyy-MM-dd').format(booking.scheduledAt)), _row('الوقت', DateFormat('HH:mm').format(booking.scheduledAt)),
              _row('المدة', '${d?['package_duration_minutes'] ?? 30} دقيقة'), _row('الرسوم', '${booking.price} د.ع'),
            ]), loading: () => const CircularProgressIndicator(), error: (_, __) => const Text('تعذر تحميل تفاصيل الحجز'),
          )),
          const SizedBox(height: 16),
          _section('وصف الموضوع', Icons.description_outlined, detailsAsync.when(
            data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d?['description'] ?? 'لا يوجد وصف متاح.'), if (d?['document_url'] != null) OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(d!['document_url'] as String)), icon: const Icon(Icons.file_present), label: const Text('فتح المستند المرفق'))]),
            loading: () => const Text('جاري التحميل...'), error: (_, __) => const Text('تعذر تحميل الوصف'),
          )),
          const SizedBox(height: 16),
          _section('حالة الدفع', Icons.receipt_long_outlined, paymentAsync.when(
            data: (p) => p == null ? const Text('لم يتم إرسال الدفع بعد.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_row('الوسيلة', _paymentMethod(p.paymentMethod)), _row('حالة الدفع', p.status), if (p.transactionNumber != null) _row('رقم العملية', p.transactionNumber!)]),
            loading: () => const CircularProgressIndicator(), error: (_, __) => const Text('تعذر تحميل بيانات الدفع'),
          )),
          if (isOwner && ['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status)) ...[
            const SizedBox(height: 16),
            _section('معلومات التواصل', Icons.contact_phone_outlined, contactAsync.when(
              data: (c) => c == null ? const Text('لا توجد معلومات تواصل متاحة.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المحامي: ${c['lawyer_name'] ?? 'محامي'}'), if (c['lawyer_phone'] != null) _row('رقم الهاتف', c['lawyer_phone']), if (c['lawyer_whatsapp'] != null) _row('واتساب', c['lawyer_whatsapp'])]),
              loading: () => const CircularProgressIndicator(), error: (e, _) => Text(e.toString().replaceFirst('Exception: ', '')),
            )),
          ],
          const SizedBox(height: 24),
          if (isOwner && booking.status == 'قيد انتظار الدفع') ElevatedButton.icon(onPressed: () => context.push('/upload-payment', extra: booking), icon: const Icon(Icons.payment), label: const Text('إرسال الدفع'), style: _button()),
          if (isLawyer && booking.status == 'مؤكد') ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'قيد التنفيذ'), icon: const Icon(Icons.play_arrow), label: const Text('بدء الاستشارة'), style: _button()),
          if (isLawyer && booking.status == 'قيد التنفيذ') ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'مكتمل'), icon: const Icon(Icons.check_circle_outline), label: const Text('إنهاء الاستشارة'), style: _button(color: AppColors.success)),
          if (isOwner && booking.status == 'مكتمل') ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star), label: const Text('تقييم الاستشارة'), style: _button()),
        ]),
      ),
    );
  }

  Widget _statusHeader() {
    final color = switch (booking.status) { 'قيد انتظار الدفع' => Colors.orange, 'قيد معالجة الدفع' => Colors.blue, 'مؤكد' => AppColors.success, 'قيد التنفيذ' => AppColors.primary, 'مكتمل' => AppColors.success, 'ملغي' => AppColors.error, _ => Colors.grey };
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(booking.status, style: TextStyle(color: color, fontWeight: FontWeight.bold))));
  }
  Widget _section(String title, IconData icon, Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary))]), const Divider(height: 24), child]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  ButtonStyle _button({Color? color}) => ElevatedButton.styleFrom(backgroundColor: color ?? AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16));
  String _paymentMethod(String value) => switch (value) { 'ZainCash' => 'زين كاش', 'Qi Card' => 'كي كارد', 'MasterCard' => 'ماستركارد', _ => value };
  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async { try { await ref.read(bookingsRepositoryProvider).updateBookingStatus(booking.id, status); ref.invalidate(lawyerBookingsProvider); ref.invalidate(userBookingsProvider); if (context.mounted) Navigator.pop(context); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error)); } }
}
