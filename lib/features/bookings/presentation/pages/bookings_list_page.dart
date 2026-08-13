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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateChangesProvider).value;
    final isLawyer = user?.role == 'lawyer';
    final bookingsAsync = ref.watch(isLawyer ? lawyerBookingsProvider : userBookingsProvider);
    final title = isLawyer ? 'طلبات الاستشارة' : 'استشاراتي';

    return Scaffold(
      backgroundColor: dark ? scheme.surface : AppColors.background,
      appBar: AppBar(
        backgroundColor: dark ? scheme.surface : AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () => context.push('/archived-bookings'), icon: Icon(Icons.archive_outlined, color: scheme.onSurface), tooltip: 'أرشيف الاستشارات'),
          IconButton(onPressed: () => ref.invalidate(isLawyer ? lawyerBookingsProvider : userBookingsProvider), icon: Icon(Icons.refresh_rounded, color: scheme.onSurface), tooltip: 'تحديث'),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text('تعذر تحميل الاستشارات', style: TextStyle(color: scheme.onSurface))),
        data: (bookings) {
          if (bookings.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 82, height: 82, decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest : AppColors.goldLight.withValues(alpha: .42), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.calendar_month_outlined, size: 42, color: dark ? AppColors.gold : AppColors.goldDark)), const SizedBox(height: 18), Text(isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 8), Text('ستظهر هنا الاستشارات عند توفرها.', style: TextStyle(color: scheme.onSurfaceVariant))])));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Consumer(builder: (context, ref, child) {
                final nameAsync = isLawyer ? ref.watch(bookingClientNameProvider(booking.id)) : ref.watch(userNameProvider(booking.lawyerId));
                final displayName = nameAsync.maybeWhen(data: (name) => name != null && name.trim().isNotEmpty ? name.trim() : (isLawyer ? 'اسم العميل غير متوفر' : 'المحامي غير متوفر'), loading: () => 'جاري تحميل الاسم...', orElse: () => isLawyer ? 'اسم العميل غير متوفر' : 'المحامي غير متوفر');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: dark ? 0 : 1,
                  shadowColor: Colors.black.withValues(alpha: .05),
                  color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .82) : AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: dark ? scheme.outlineVariant : AppColors.outline)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/booking-details', extra: booking),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest : AppColors.goldLight.withValues(alpha: .38), borderRadius: BorderRadius.circular(14)), child: Icon(isLawyer ? Icons.person_outline_rounded : Icons.balance_rounded, color: dark ? AppColors.gold : AppColors.goldDark)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 4), Text('رقم الحجز: #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant))])), _StatusBadge(status: booking.status, lawyerApproved: booking.lawyerApproved)]),
                        const SizedBox(height: 14),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), decoration: BoxDecoration(color: dark ? scheme.surface : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(13), border: Border.all(color: dark ? scheme.outlineVariant : AppColors.divider)), child: Row(children: [Icon(Icons.schedule_rounded, size: 18, color: dark ? AppColors.gold : AppColors.primaryDark), const SizedBox(width: 8), Expanded(child: Text(DateFormat('yyyy/MM/dd - HH:mm').format(booking.scheduledAt), style: TextStyle(fontSize: 12, color: scheme.onSurface))), Text('${booking.price} د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: dark ? AppColors.gold : AppColors.secondary))])),
                        const SizedBox(height: 12),
                        _buildActions(context, ref, booking, isLawyer),
                        if (['مكتمل', 'ملغي', 'مسترد', 'بانتظار الاسترداد'].contains(booking.status)) ...[
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async { await ref.read(bookingsControllerProvider.notifier).archiveBooking(booking.id, isLawyer: isLawyer); }, icon: const Icon(Icons.archive_outlined, size: 18), label: const Text('أرشفة الاستشارة'))),
                        ],
                      ]),
                    ),
                  ),
                );
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, dynamic booking, bool isLawyer) {
    if (!isLawyer && booking.status == 'قيد انتظار الدفع') return _action(context, Icons.payment_rounded, 'إكمال الدفع', () => context.push('/upload-payment', extra: booking));
    if (!isLawyer && booking.status == 'قيد معالجة الدفع') return _action(context, Icons.sync_rounded, 'التحقق من حالة الدفع', () => context.push('/booking-details', extra: booking));
    if (isLawyer && !booking.lawyerApproved && booking.status == 'قيد مراجعة المحامي') return _action(context, Icons.rate_review_outlined, 'مراجعة الطلب والموافقة أو الرفض', () => context.push('/booking-details', extra: booking));
    if (isLawyer && booking.isInOffice && booking.isManualPaymentPending) return _action(context, Icons.payments_outlined, 'تسجيل المبلغ المستلم', () => context.push('/manual-payment', extra: booking), dark: true);
    if (!isLawyer && booking.status == 'بانتظار الاسترداد') return _action(context, Icons.account_balance_outlined, 'تفاصيل الاسترداد', () => context.push('/booking-details', extra: booking), outlined: true);
    if (booking.status == 'مؤكد') return _action(context, Icons.play_arrow_rounded, 'تفاصيل وبدء الاستشارة', () => context.push('/booking-details', extra: booking));
    if (booking.status == 'قيد التنفيذ') return _action(context, Icons.chat_outlined, isLawyer ? 'الاستشارة جارية' : 'بدء الاستشارة عبر واتساب', () => context.push('/booking-details', extra: booking));
    if (booking.status == 'مكتمل' && !isLawyer) return _action(context, Icons.star_outline_rounded, 'تقييم الخدمة الآن', () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), dark: true);
    return const SizedBox.shrink();
  }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onPressed, {bool outlined = false, bool dark = false}) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(width: double.infinity, child: outlined ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 19), label: Text(label), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), foregroundColor: dark ? AppColors.gold : AppColors.primaryDark, side: BorderSide(color: dark ? AppColors.gold : AppColors.primaryDark))) : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 19), label: Text(label), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: dark ? AppColors.gold : AppColors.primary, foregroundColor: dark ? AppColors.secondaryDark : scheme.onPrimary)));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool lawyerApproved;
  const _StatusBadge({required this.status, required this.lawyerApproved});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = status.trim().isEmpty ? 'غير محدد' : status;
    final pending = label.contains('انتظار') || label.contains('مراجعة') || label.contains('معالجة');
    final success = label == 'مؤكد' || label == 'مكتمل' || label == 'قيد التنفيذ';
    final background = pending ? AppColors.pendingBg : success ? AppColors.acceptedBg : dark ? scheme.surfaceContainerHighest : AppColors.surfaceVariant;
    final foreground = pending ? AppColors.pendingText : success ? AppColors.acceptedText : scheme.onSurfaceVariant;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: foreground)));
  }
}
