import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

class BookingDetailsPage extends ConsumerWidget {
  final Booking booking;
  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(bookingPaymentProvider(booking.id));
    final clientNameAsync = ref.watch(userNameProvider(booking.userId));
    final extraDetailsAsync = ref.watch(bookingDetailsProvider(booking.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الاستشارة'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'معلومات العميل',
              icon: Icons.person_outline,
              child: Text(
                clientNameAsync.maybeWhen(
                  data: (name) => name ?? 'عميل الاستشارة',
                  orElse: () => 'جاري التحميل...',
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'نوع الاستشارة والموعد',
              icon: Icons.calendar_today_outlined,
              child: extraDetailsAsync.when(
                data: (details) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('الباقة:', details?['package_name'] ?? 'غير محددة'),
                    const SizedBox(height: 8),
                    _buildDetailRow('النوع:', _getConsultationTypeText(details?['consultation_type'])),
                    const SizedBox(height: 8),
                    _buildDetailRow('التاريخ:', DateFormat('yyyy-MM-dd').format(booking.scheduledAt)),
                    const SizedBox(height: 8),
                    _buildDetailRow('الوقت:', DateFormat('HH:mm').format(booking.scheduledAt)),
                    const SizedBox(height: 8),
                    _buildDetailRow('المدة:', '${details?['package_duration_minutes'] ?? 30} دقيقة'),
                    const SizedBox(height: 8),
                    _buildDetailRow('السعر:', '${booking.price} د.ع'),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('تعذر تحميل تفاصيل الموعد'),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'وصف الموضوع',
              icon: Icons.description_outlined,
              child: extraDetailsAsync.when(
                data: (details) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(details?['description'] ?? 'لا يوجد وصف متاح لهذا الطلب.'),
                    if (details?['document_url'] != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('المستندات المرفقة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(details!['document_url']);
                          await launchUrl(url);
                        },
                        icon: const Icon(Icons.file_present, size: 18),
                        label: const Text('فتح المستند المرفق'),
                      ),
                    ],
                  ],
                ),
                loading: () => const Text('جاري التحميل...'),
                error: (_, __) => const Text('تعذر تحميل الوصف'),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'حالة الدفع',
              icon: Icons.receipt_long_outlined,
              child: paymentAsync.when(
                data: (payment) {
                  if (payment == null) {
                    return const Text('بانتظار إكمال الدفع.', style: TextStyle(color: AppColors.error));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('المبلغ:', '${payment.amount} د.ع'),
                      const SizedBox(height: 8),
                      _buildDetailRow('الوسيلة:', _paymentMethodText(payment.paymentMethod)),
                      const SizedBox(height: 8),
                      _buildDetailRow('حالة الدفع:', _paymentStatusText(payment.status)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('تعذر تحميل بيانات الدفع'),
              ),
            ),
            const SizedBox(height: 32),
            // موافقة المحامي أو رفضه متاحة فقط بعد وصول الطلب إلى حالة انتظار التأكيد.
            if (booking.status == 'بانتظار التأكيد')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, 'مؤكد'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                      child: const Text('موافقة وتأكيد'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, 'ملغي'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('رفض الطلب'),
                    ),
                  ),
                ],
              ),
            if (booking.status == 'مؤكد')
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, 'قيد التنفيذ'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('بدء الاستشارة'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            if (booking.status == 'قيد التنفيذ')
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, 'مكتمل'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('إنهاء الاستشارة'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color color = Colors.grey;
    String text = booking.status;
    switch (booking.status) {
      case 'قيد انتظار الدفع':
        color = Colors.orange;
        text = 'بانتظار إكمال الدفع';
        break;
      case 'بانتظار التأكيد':
        color = Colors.blue;
        text = 'بانتظار موافقة المحامي';
        break;
      case 'مؤكد':
        color = AppColors.success;
        text = 'الحجز مؤكد';
        break;
      case 'قيد التنفيذ':
        color = AppColors.primary;
        text = 'الاستشارة قيد التنفيذ';
        break;
      case 'مكتمل':
        color = AppColors.success;
        text = 'الاستشارة مكتملة';
        break;
      case 'ملغي':
        color = AppColors.error;
        text = 'الحجز ملغي';
        break;
      case 'مسترد':
        color = Colors.grey;
        text = 'تم استرداد المبلغ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary))]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
        child,
      ]),
    );
  }

  Widget _buildDetailRow(String label, String value) => Row(children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
      ]);

  String _getConsultationTypeText(String? type) {
    switch (type) {
      case 'نصية': return 'استشارة نصية';
      case 'صوتية': return 'استشارة صوتية';
      case 'فيديو': return 'استشارة فيديو';
      default: return type ?? 'استشارة قانونية';
    }
  }

  String _paymentStatusText(String? status) {
    switch (status) {
      case 'قيد معالجة الدفع': return 'قيد التحقق من الدفع';
      case 'تم الدفع': return 'تم التحقق من الدفع';
      case 'فشل الدفع': return 'فشل الدفع';
      case 'تم استرداد المبلغ': return 'تم استرداد المبلغ';
      default: return 'بانتظار الدفع';
    }
  }

  String _paymentMethodText(String method) {
    switch (method) {
      case 'ZainCash': return 'زين كاش';
      case 'Asia Hawala': return 'آسيا حوالة';
      case 'Qi Card': return 'كي كارد';
      case 'MasterCard': return 'ماستركارد';
      default: return method;
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(bookingsRepositoryProvider).updateBookingStatus(booking.id, status);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(userBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'مؤكد' ? 'تمت الموافقة على الطلب وتأكيد الحجز' : status == 'ملغي' ? 'تم رفض الطلب' : status == 'قيد التنفيذ' ? 'بدأت الاستشارة' : 'تم إنهاء الاستشارة')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
