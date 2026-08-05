import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/bookings_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:astshara/features/reviews/presentation/widgets/review_dialog.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('استشاراتي')),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 60,
                        color: AppColors.outline.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('ليس لديك أي حجوزات حالياً',
                        style: TextStyle(color: AppColors.outline)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p20),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  // اسم المحامي يُجلب من قاعدة البيانات عبر booking.lawyerId
                  const lawyerName = 'محامي'; // يُحدَّث عبر FutureBuilder أو join

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.p16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lawyerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                      'رقم الحجز: #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.outline)),
                                ],
                              ),
                              _StatusBadge(status: booking.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 16, color: AppColors.outline),
                              const SizedBox(width: 8),
                              Text(
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(booking.scheduledAt),
                                  style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              Text('${booking.price} د.ع',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildActions(context, booking),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  Widget _buildActions(BuildContext context, dynamic booking) {
    if (booking.status == 'pending') {
      return ElevatedButton.icon(
        onPressed: () => context.push('/upload-payment', extra: booking),
        icon: const Icon(Icons.payment, size: 18),
        label: const Text('رفع إيصال الدفع'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(40)),
      );
    }
    if (booking.status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/chat/${booking.id}'),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('المحادثة'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse("https://wa.me/9647700000000");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.wechat, size: 18),
              label: const Text('واتساب'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green)),
            ),
          ),
        ],
      );
    }
    if (booking.status == 'completed') {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId),
          );
        },
        icon: const Icon(Icons.star_outline, size: 18),
        label: const Text('تقييم الخدمة'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'بانتظار الدفع';
        break;
      case 'accepted':
        color = Colors.green;
        text = 'مقبول';
        break;
      case 'completed':
        color = AppColors.primary;
        text = 'مكتمل';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
