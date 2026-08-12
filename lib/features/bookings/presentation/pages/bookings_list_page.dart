import 'package:astshara/features/authentication/presentation/providers/auth_provider.dart';
import 'package:astshara/features/lawyers/presentation/providers/lawyers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/bookings_provider.dart';
import 'package:intl/intl.dart';
import 'package:astshara/features/reviews/presentation/widgets/review_dialog.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateChangesProvider).value;
    final isLawyer = user?.role == 'lawyer';
    final bookingsAsync = ref.watch(isLawyer ? lawyerBookingsProvider : userBookingsProvider);
    final title = isLawyer ? 'طلبات الاستشارة' : 'استشاراتي';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: scheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: IconButton.filledTonal(
              onPressed: () => ref.invalidate(isLawyer ? lawyerBookingsProvider : userBookingsProvider),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
            ),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(
          child: _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'تعذر تحميل الاستشارات',
            subtitle: 'تحقق من الاتصال ثم حاول مرة أخرى.',
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return _EmptyState(
              icon: Icons.calendar_month_outlined,
              title: isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً',
              subtitle: isLawyer ? 'ستظهر طلبات العملاء هنا عند وصولها.' : 'ستظهر استشاراتك هنا عند إنشاء أول حجز.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Consumer(
                builder: (context, ref, child) {
                  final nameAsync = isLawyer
                      ? ref.watch(bookingClientNameProvider(booking.id))
                      : ref.watch(userNameProvider(booking.lawyerId));
                  final displayName = nameAsync.maybeWhen(
                    data: (name) => name != null && name.trim().isNotEmpty
                        ? (isLawyer ? name : 'المحامي $name')
                        : (isLawyer ? 'اسم العميل غير متوفر' : 'المحامي غير متوفر'),
                    loading: () => 'جاري تحميل الاسم...',
                    orElse: () => isLawyer ? 'اسم العميل غير متوفر' : 'المحامي غير متوفر',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .72) : scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: .85)),
                      boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 22, offset: const Offset(0, 8))],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => context.push('/booking-details', extra: booking),
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                                  child: Icon(isLawyer ? Icons.person_outline_rounded : Icons.balance_rounded, color: scheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                                      const SizedBox(height: 4),
                                      Text('رقم الحجز: #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(status: booking.status, lawyerApproved: booking.lawyerApproved),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                              decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: dark ? .8 : .55), borderRadius: BorderRadius.circular(15)),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 18, color: scheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(DateFormat('yyyy/MM/dd - HH:mm').format(booking.scheduledAt), style: TextStyle(fontSize: 12, color: scheme.onSurface, fontWeight: FontWeight.w600))),
                                  Text('${booking.price} د.ع', style: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSurface)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildActions(context, ref, booking, isLawyer),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, dynamic booking, bool isLawyer) {
    if (!isLawyer && booking.status == 'قيد انتظار الدفع') {
      return _action(context, Icons.payment_rounded, 'إكمال الدفع', () => context.push('/upload-payment', extra: booking));
    }
    if (!isLawyer && booking.status == 'قيد معالجة الدفع') {
      return _action(context, Icons.sync_rounded, 'التحقق من حالة الدفع', () => context.push('/booking-details', extra: booking));
    }
    if (isLawyer && !booking.lawyerApproved && booking.status == 'قيد مراجعة المحامي') {
      return _action(context, Icons.rate_review_outlined, 'مراجعة الطلب والموافقة أو الرفض', () => context.push('/booking-details', extra: booking));
    }
    if (isLawyer && booking.isInOffice && booking.isManualPaymentPending) {
      return _action(context, Icons.payments_outlined, 'تسجيل المبلغ المستلم', () => context.push('/manual-payment', extra: booking), dark: true);
    }
    if (!isLawyer && booking.status == 'بانتظار الاسترداد') {
      return _action(context, Icons.account_balance_outlined, 'تفاصيل الاسترداد', () => context.push('/booking-details', extra: booking), outlined: true);
    }
    if (booking.status == 'مؤكد') {
      return _action(context, Icons.play_arrow_rounded, 'تفاصيل وبدء الاستشارة', () => context.push('/booking-details', extra: booking));
    }
    if (booking.status == 'قيد التنفيذ') {
      return _action(context, Icons.chat_outlined, isLawyer ? 'الاستشارة جارية' : 'بدء الاستشارة عبر واتساب', () => context.push('/booking-details', extra: booking));
    }
    if (booking.status == 'مكتمل' && !isLawyer) {
      return _action(context, Icons.star_outline_rounded, 'تقييم الخدمة الآن', () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), dark: true);
    }
    return const SizedBox.shrink();
  }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onPressed, {bool outlined = false, bool dark = false}) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = dark ? scheme.onPrimary : scheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 19), label: Text(label), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(47), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))
          : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 19), label: Text(label), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(47), backgroundColor: scheme.primary, foregroundColor: foreground, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool lawyerApproved;
  const _StatusBadge({required this.status, required this.lawyerApproved});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = status.trim().isEmpty ? 'غير محدد' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 88, height: 88, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(28)), child: Icon(icon, size: 43, color: scheme.primary)),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.55)),
          ],
        ),
      ),
    );
  }
}
