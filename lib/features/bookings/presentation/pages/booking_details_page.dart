import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientNameAsync.maybeWhen(
                      data: (name) => name ?? 'عميل استشارة',
                      orElse: () => '...',
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final phone = extraDetailsAsync.value?['whatsapp_number'];
                      if (phone != null) {
                        final url = Uri.parse(
                            'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.wechat, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          extraDetailsAsync.value?['whatsapp_number'] ??
                              'غير متوفر',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    _buildDetailRow(
                        'النوع:',
                        _getConsultationTypeText(
                            details?['consultation_type'])),
                    const SizedBox(height: 8),
                    _buildDetailRow('التاريخ:',
                        DateFormat('yyyy-MM-dd').format(booking.scheduledAt)),
                    const SizedBox(height: 8),
                    _buildDetailRow('الوقت:',
                        DateFormat('HH:mm').format(booking.scheduledAt)),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل تفاصيل الموعد'),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'وصف المشكلة القانونية',
              icon: Icons.description_outlined,
              child: extraDetailsAsync.when(
                data: (details) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details?['description'] ?? 'لا يوجد وصف متاح لهذا الطلب.',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    if (details?['document_url'] != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('المستندات المرفقة:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(details!['document_url']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        icon: const Icon(Icons.file_present, size: 18),
                        label: const Text('فتح المستند المرفق'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
                loading: () => const Text('جاري التحميل...'),
                error: (_, __) => const Text('خطأ في تحميل الوصف'),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'تفاصيل الدفع والوصل',
              icon: Icons.receipt_long_outlined,
              child: paymentAsync.when(
                data: (payment) {
                  if (payment == null) {
                    return const Text('لم يتم رفع إيصال الدفع بعد.',
                        style: TextStyle(color: AppColors.error));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('المبلغ:', '${payment.amount} د.ع'),
                      const SizedBox(height: 8),
                      _buildDetailRow('الوسيلة:', payment.paymentMethod),
                      const SizedBox(height: 8),
                      _buildDetailRow('رقم العملية:',
                          payment.transactionNumber ?? 'غير متوفر'),
                      const SizedBox(height: 16),
                      const Text('صورة الوصل:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      if (payment.receiptUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            payment.receiptUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Text('تعذر تحميل الصورة')),
                          ),
                        )
                      else
                        const Text('لا توجد صورة وصل مرفقة.'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ في تحميل بيانات الدفع: $e'),
              ),
            ),
            const SizedBox(height: 32),
            if (booking.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, 'accepted'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white),
                      child: const Text('قبول وتأكيد'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, 'cancelled'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white),
                      child: const Text('رفض الطلب'),
                    ),
                  ),
                ],
              ),
            if (booking.status == 'accepted')
              ElevatedButton.icon(
                onPressed: () => context.push('/chat/${booking.id}'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('بدء المحادثة المباشرة الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
    if (booking.status == 'pending') {
      color = Colors.orange;
      text = 'بانتظار المراجعة';
    } else if (booking.status == 'accepted') {
      color = AppColors.success;
      text = 'مقبولة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'حالة الطلب: $text',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(width: 8),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  String _getConsultationTypeText(String? type) {
    switch (type) {
      case 'text':
        return 'استشارة نصية';
      case 'audio':
        return 'استشارة صوتية';
      case 'video':
        return 'استشارة فيديو';
      default:
        return 'استشارة قانونية';
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(bookingsRepositoryProvider)
          .updateBookingStatus(booking.id, status);
      ref.invalidate(lawyerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(status == 'accepted'
                ? 'تم قبول الطلب بنجاح'
                : 'تم رفض الطلب')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
