import 'package:astshara/features/authentication/presentation/providers/auth_provider.dart';
import 'package:astshara/shared/widgets/main_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../providers/bookings_provider.dart';
import 'package:intl/intl.dart';
import 'package:astshara/features/reviews/presentation/widgets/review_dialog.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final isLawyer = user?.role == 'lawyer';
    final bookingsAsync = ref.watch(isLawyer ? lawyerBookingsProvider : userBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: bookingsAsync.when(
        data: (bookings) => CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(isLawyer ? 'طلبات الاستشارة' : 'استشاراتي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              background: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark]))),
            ),
          ),
          bookings.isEmpty
              ? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_outlined, size: 60, color: AppColors.outline.withValues(alpha: 0.5)), const SizedBox(height: 16), Text(isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً', style: const TextStyle(color: AppColors.outline))])))
              : SliverPadding(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                    final booking = bookings[index];
                    return Consumer(builder: (context, ref, child) {
                      final nameAsync = ref.watch(userNameProvider(isLawyer ? booking.userId : booking.lawyerId));
                      final displayName = nameAsync.maybeWhen(data: (name) => isLawyer ? (name ?? 'عميل') : 'المحامي ${name ?? '...'}', orElse: () => 'جاري التحميل...');
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.p16),
                        child: InkWell(
                          onTap: () => context.push('/booking-details', extra: booking),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.p16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('رقم الحجز: #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}', style: const TextStyle(fontSize: 12, color: AppColors.outline)),
                                ]),
                                _StatusBadge(status: booking.status, lawyerApproved: booking.lawyerApproved),
                              ]),
                              const Divider(height: 24),
                              Row(children: [const Icon(Icons.access_time, size: 16, color: AppColors.outline), const SizedBox(width: 8), Text(DateFormat('yyyy-MM-dd HH:mm').format(booking.scheduledAt), style: const TextStyle(fontSize: 14)), const Spacer(), Text('${booking.price} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))]),
                              const SizedBox(height: 16),
                              _buildActions(context, booking, isLawyer),
                            ]),
                          ),
                        ),
                      );
                    });
                  }, childCount: bookings.length)),
                ),
        ]),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
      bottomNavigationBar: MainBottomNav(currentIndex: isLawyer ? 0 : 1),
    );
  }

  Widget _buildActions(BuildContext context, dynamic booking, bool isLawyer) {
    if (isLawyer && booking.status == 'قيد انتظار الدفع' && !booking.lawyerApproved) {
      return ElevatedButton.icon(
        onPressed: () => context.push('/booking-details', extra: booking),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text('مراجعة الطلب والموافقة أو الرفض'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
    if (!isLawyer && booking.status == 'قيد انتظار الدفع' && booking.lawyerApproved) {
      return ElevatedButton.icon(
        onPressed: () => context.push('/upload-payment', extra: booking),
        icon: const Icon(Icons.payment, size: 18),
        label: const Text('إكمال الدفع'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
    if (isLawyer && booking.status == 'بانتظار التأكيد') {
      return ElevatedButton.icon(
        onPressed: () => context.push('/booking-details', extra: booking),
        icon: const Icon(Icons.verified_outlined, size: 18),
        label: const Text('التحقق من الدفع وتأكيد الحجز'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
    if (booking.status == 'مؤكد') {
      return ElevatedButton.icon(onPressed: () => context.push('/chat/${booking.id}'), icon: const Icon(Icons.chat_outlined, size: 18, color: Colors.white), label: const Text('المحادثة'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
    if (booking.status == 'مكتمل' && !isLawyer) {
      return ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star_outline, size: 18, color: Colors.white), label: const Text('تقييم الخدمة الآن'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
    return const SizedBox.shrink();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool lawyerApproved;
  const _StatusBadge({required this.status, required this.lawyerApproved});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String text = status;
    switch (status) {
      case 'قيد انتظار الدفع': color = lawyerApproved ? Colors.blue : Colors.orange; text = lawyerApproved ? 'بانتظار الدفع' : 'بانتظار موافقة المحامي'; break;
      case 'بانتظار التأكيد': color = Colors.blue; text = 'بانتظار تأكيد الحجز'; break;
      case 'مؤكد': color = Colors.green; text = 'مؤكد'; break;
      case 'قيد التنفيذ': color = AppColors.primary; text = 'قيد التنفيذ'; break;
      case 'مكتمل': color = AppColors.success; text = 'مكتمل'; break;
      case 'ملغي': color = AppColors.error; text = 'ملغي'; break;
      case 'مسترد': color = Colors.grey; text = 'مسترد'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }
}
