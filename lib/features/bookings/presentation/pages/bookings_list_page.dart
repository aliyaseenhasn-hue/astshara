import 'package:astshara/features/authentication/presentation/providers/auth_provider.dart';
import 'package:astshara/features/lawyers/presentation/providers/lawyers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/bookings_provider.dart';
import 'package:intl/intl.dart';
import 'package:astshara/features/reviews/presentation/widgets/review_dialog.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final isLawyer = user?.role == 'lawyer';
    final bookingsAsync = ref.watch(
      isLawyer ? lawyerBookingsProvider : userBookingsProvider,
    );
    final title = isLawyer ? 'طلبات الاستشارة' : 'استشاراتي';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: bookingsAsync.when(
        data: (bookings) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 170,
              backgroundColor: AppColors.secondaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.secondaryDark,
                        AppColors.secondary,
                        AppColors.primaryDark,
                      ],
                      stops: [0, .65, 1],
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isLawyer
                                  ? 'تابع الطلبات القادمة وحالتها'
                                  : 'تابع مواعيدك وحالة استشاراتك',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (bookings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            size: 42,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isLawyer
                              ? 'لا توجد طلبات واردة حالياً'
                              : 'ليس لديك أي حجوزات حالياً',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ستظهر هنا الاستشارات عند توفرها.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = bookings[index];
                      return Consumer(
                        builder: (context, ref, child) {
                          final nameAsync = isLawyer
                              ? ref.watch(
                                  bookingClientNameProvider(booking.id),
                                )
                              : ref.watch(
                                  userNameProvider(booking.lawyerId),
                                );
                          final displayName = nameAsync.maybeWhen(
                            data: (name) {
                              final n = name?.trim();
                              if (isLawyer) {
                                return n != null && n.isNotEmpty
                                    ? n
                                    : 'اسم العميل غير متوفر';
                              }
                              return n != null && n.isNotEmpty
                                  ? 'المحامي $n'
                                  : 'المحامي غير متوفر';
                            },
                            loading: () => 'جاري تحميل الاسم...',
                            error: (_, __) => isLawyer
                                ? 'اسم العميل غير متوفر'
                                : 'المحامي غير متوفر',
                            orElse: () => isLawyer
                                ? 'اسم العميل غير متوفر'
                                : 'المحامي غير متوفر',
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.outline),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: .04,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.push(
                                '/booking-details',
                                extra: booking,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          child: Icon(
                                            isLawyer
                                                ? Icons.person_outline_rounded
                                                : Icons.balance_rounded,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'رقم الحجز: #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusBadge(
                                          status: booking.status,
                                          lawyerApproved: booking.lawyerApproved,
                                        ),
                                        if (isLawyer &&
                                            booking.status != 'قيد التنفيذ')
                                          PopupMenuButton<String>(
                                            tooltip: 'خيارات الطلب',
                                            onSelected: (value) {
                                              if (value == 'archive') {
                                                _archiveBooking(
                                                  context,
                                                  ref,
                                                  booking.id,
                                                );
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem<String>(
                                                value: 'archive',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'حذف الاستشارة من القائمة',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule_rounded,
                                            size: 18,
                                            color: AppColors.primaryDark,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              DateFormat('yyyy/MM/dd - HH:mm')
                                                  .format(booking.scheduledAt),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${booking.price} د.ع',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildActions(
                                      context,
                                      ref,
                                      booking,
                                      isLawyer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: bookings.length,
                  ),
                ),
              ),
          ],
        ),
        loading: () => const LoadingWidget(),
        error: (_, __) => const Center(
          child: Text('تعذر تحميل الاستشارات'),
        ),
      ),
    );
  }

  Future<void> _archiveBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الاستشارة من قائمتك؟'),
        content: const Text(
          'ستختفي الاستشارة من قائمة المحامي فقط، ولن يتم حذف سجل الحجز أو بيانات العميل من النظام.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(bookingsRepositoryProvider)
          .archiveBookingForLawyer(bookingId);
      ref.invalidate(lawyerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الاستشارة من القائمة')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    dynamic booking,
    bool isLawyer,
  ) {
    if (isLawyer &&
        !booking.lawyerApproved &&
        ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'قيد مراجعة المحامي']
            .contains(booking.status)) {
      return _action(
        context,
        Icons.rate_review_outlined,
        'مراجعة الطلب والموافقة أو الرفض',
        () => context.push('/booking-details', extra: booking),
      );
    }
    if (!isLawyer &&
        booking.status == 'قيد انتظار الدفع' &&
        booking.lawyerApproved) {
      return _action(
        context,
        Icons.payment_rounded,
        'إكمال الدفع',
        () => context.push('/upload-payment', extra: booking),
      );
    }
    if (!isLawyer && booking.status == 'قيد معالجة الدفع') {
      return _action(
        context,
        Icons.sync_rounded,
        'التحقق من حالة الدفع',
        () => context.push('/booking-details', extra: booking),
      );
    }
    if (!isLawyer && booking.status == 'قيد مراجعة المحامي') {
      return _action(
        context,
        Icons.hourglass_top_rounded,
        'بانتظار موافقة المحامي',
        () => context.push('/booking-details', extra: booking),
        outlined: true,
      );
    }
    if (isLawyer && booking.status == 'بانتظار التأكيد') {
      return _action(
        context,
        Icons.payments_outlined,
        'تسجيل المبلغ المستلم',
        () => context.push('/manual-payment', extra: booking),
        dark: true,
      );
    }
    if (booking.status == 'مؤكد') {
      return _action(
        context,
        Icons.play_arrow_rounded,
        'تفاصيل وبدء الاستشارة',
        () => context.push('/booking-details', extra: booking),
      );
    }
    if (booking.status == 'قيد التنفيذ') {
      return _action(
        context,
        Icons.chat_outlined,
        isLawyer ? 'الاستشارة جارية' : 'بدء الاستشارة عبر واتساب',
        () => context.push('/booking-details', extra: booking),
      );
    }
    if (booking.status == 'مكتمل' && !isLawyer) {
      return _action(
        context,
        Icons.star_outline_rounded,
        'تقييم الخدمة الآن',
        () => showDialog(
          context: context,
          builder: (_) => ReviewDialog(
            bookingId: booking.id,
            lawyerId: booking.lawyerId,
          ),
        ),
        dark: true,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool outlined = false,
    bool dark = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 19),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 19),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: dark ? AppColors.secondary : AppColors.gold,
                foregroundColor: dark ? Colors.white : AppColors.secondaryDark,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool lawyerApproved;

  const _StatusBadge({
    required this.status,
    required this.lawyerApproved,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textSecondary;
    String text = status;
    switch (status) {
      case 'قيد انتظار الدفع':
        color = lawyerApproved ? AppColors.info : AppColors.warning;
        text = lawyerApproved ? 'بانتظار الدفع' : 'بانتظار الموافقة';
        break;
      case 'قيد معالجة الدفع':
        color = AppColors.warning;
        text = 'قيد معالجة الدفع';
        break;
      case 'قيد مراجعة المحامي':
        color = AppColors.info;
        text = 'بانتظار موافقة المحامي';
        break;
      case 'بانتظار التأكيد':
        color = AppColors.info;
        text = 'بانتظار تسجيل المبلغ';
        break;
      case 'مؤكد':
        color = AppColors.success;
        text = 'مؤكد';
        break;
      case 'قيد التنفيذ':
        color = AppColors.primaryDark;
        text = 'قيد التنفيذ';
        break;
      case 'مكتمل':
        color = AppColors.success;
        text = 'مكتمل';
        break;
      case 'ملغي':
        color = AppColors.error;
        text = 'ملغي';
        break;
      case 'مسترد':
        color = AppColors.textSecondary;
        text = 'مسترد';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
