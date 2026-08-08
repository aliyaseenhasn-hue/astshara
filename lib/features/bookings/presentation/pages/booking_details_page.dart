import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';
import '../../../reviews/presentation/widgets/review_dialog.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';

class BookingDetailsPage extends ConsumerWidget {
  final Booking booking;
  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(bookingPaymentProvider(booking.id));
    final contactAsync = ref.watch(bookingContactProvider(booking.id));
    final extraDetailsAsync = ref.watch(bookingDetailsProvider(booking.id));
    final reviewAsync = ref.watch(reviewForBookingProvider(booking.id));
    final currentUser = ref.watch(authStateChangesProvider).value;
    final isClient = currentUser?.role != 'lawyer' && currentUser?.role != 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الاستشارة'), backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildStatusHeader(),
          const SizedBox(height: 20),
          _section('تفاصيل الحجز', Icons.calendar_today_outlined, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row('الباقة', booking.packageName ?? 'استشارة'),
            _row('طريقة الاستشارة', booking.consultationType ?? 'غير محددة'),
            _row('المدة', '${booking.packageDurationMinutes} دقيقة'),
            _row('التاريخ', DateFormat('yyyy/MM/dd').format(booking.scheduledAt)),
            _row('الوقت', DateFormat('HH:mm').format(booking.scheduledAt)),
            _row('المبلغ', '${booking.price.toStringAsFixed(0)} د.ع'),
            _row('حالة الاستشارة', booking.consultationStatus),
          ])),
          const SizedBox(height: 16),
          _section('وصف الموضوع', Icons.description_outlined, extraDetailsAsync.when(
            data: (details) => Text(details?['description'] as String? ?? 'لا يوجد وصف.', style: const TextStyle(height: 1.5)),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('تعذر تحميل الوصف'),
          )),
          const SizedBox(height: 16),
          _section('بيانات الدفع', Icons.receipt_long_outlined, paymentAsync.when(
            data: (payment) => payment == null
                ? const Text('لم يتم إرسال بيانات الدفع بعد.')
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _row('حالة الدفع', payment.status),
                    _row('المبلغ', '${payment.amount.toStringAsFixed(0)} د.ع'),
                    _row('الوسيلة', _paymentMethodText(payment.paymentMethod)),
                    _row('رقم العملية', payment.transactionNumber ?? 'غير متوفر'),
                  ]),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('تعذر تحميل بيانات الدفع: $e'),
          )),
          if (isClient) ...[
            const SizedBox(height: 16),
            _section('معلومات التواصل', Icons.contact_phone_outlined, contactAsync.when(
              data: (contact) => contact == null
                  ? const Text('ستتوفر معلومات التواصل بعد إكمال الدفع وتأكيد الحجز.')
                  : Column(children: [
                      if (contact['phone'] != null) _contactButton(context, 'اتصال الآن', Icons.phone, 'tel:${contact['phone']}'),
                      if (contact['whatsapp'] != null)
                        _contactButton(context, 'واتساب', Icons.wechat, 'https://wa.me/${contact['whatsapp']!.replaceAll(RegExp(r'[^0-9]'), '')}'),
                    ]),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('ستتوفر معلومات التواصل بعد تأكيد الحجز.'),
            )),
          ],
          const SizedBox(height: 24),
          _buildActions(context, ref, isClient, reviewAsync),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, bool isClient, AsyncValue<dynamic> reviewAsync) {
    if (isClient && booking.status == 'قيد انتظار الدفع') {
      return ElevatedButton(
        onPressed: () => context.push('/upload-payment', extra: booking),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('إكمال الدفع'),
      );
    }
    if (isClient && ['بانتظار التأكيد', 'مؤكد'].contains(booking.status)) {
      return OutlinedButton(onPressed: () => _changeStatus(context, ref, 'ملغي'), child: const Text('إلغاء الحجز'));
    }
    if (!isClient && booking.status == 'مؤكد') {
      return ElevatedButton.icon(onPressed: () => _changeStatus(context, ref, 'قيد التنفيذ'), icon: const Icon(Icons.play_arrow), label: const Text('بدء الاستشارة'));
    }
    if (!isClient && booking.status == 'قيد التنفيذ') {
      return ElevatedButton.icon(onPressed: () => _changeStatus(context, ref, 'مكتمل'), icon: const Icon(Icons.check_circle_outline), label: const Text('إنهاء الاستشارة'));
    }
    if (isClient && booking.status == 'مكتمل') {
      return reviewAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => OutlinedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star_outline), label: const Text('تقييم تجربتك')),
        data: (review) => review == null
            ? OutlinedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star_outline), label: const Text('تقييم تجربتك'))
            : const OutlinedButton.icon(onPressed: null, icon: Icon(Icons.check_circle_outline), label: Text('تم تقييم هذه الاستشارة')),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(bookingsRepositoryProvider).updateBookingStatus(booking.id, status);
      ref.invalidate(userBookingsProvider);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(bookingDetailsProvider(booking.id));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ الإجراء: $e')));
    }
  }

  Widget _contactButton(BuildContext context, String label, IconData icon, String uri) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        onTap: () async {
          final url = Uri.parse(uri);
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        },
      );

  Widget _buildStatusHeader() {
    final color = _statusColor(booking.status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.info_outline, color: color), const SizedBox(width: 8), Text('حالة الحجز: ${booking.status}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))]),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary))]), const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)), child]),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'مؤكد': return AppColors.success;
      case 'قيد التنفيذ': return Colors.blue;
      case 'مكتمل': return Colors.green;
      case 'ملغي':
      case 'مسترد': return AppColors.error;
      case 'بانتظار التأكيد': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _paymentMethodText(String method) => {
        'ZainCash': 'زين كاش',
        'Asia Hawala': 'آسيا حوالة',
        'Qi Card': 'كي كارد',
        'MasterCard': 'بطاقة مصرفية',
      }[method] ?? method;
}
