import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/bookings_provider.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateChangesProvider);
    final isLawyer = auth.maybeWhen(data: (user) => user?.role == 'lawyer', orElse: () => false);
    final bookingsAsync = isLawyer ? ref.watch(lawyerBookingsProvider) : ref.watch(userBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isLawyer ? 'استشارات العملاء' : 'استشاراتي'), centerTitle: true, surfaceTintColor: Colors.transparent),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('تعذر تحميل الاستشارات', style: TextStyle(color: AppColors.onSurface))),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 34)),
                  const SizedBox(height: 14),
                  Text(isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 6),
                  const Text('ستظهر هنا الاستشارات عند توفرها.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                ]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Consumer(builder: (context, ref, child) {
                final clientNameAsync = isLawyer ? ref.watch(bookingClientNameProvider(booking.id)) : null;
                final lawyerInfoAsync = !isLawyer ? ref.watch(bookingLawyerInfoProvider(booking.id)) : null;
                final rpcName = lawyerInfoAsync?.valueOrNull?['full_name']?.toString().trim();
                final bookingName = booking.lawyerName?.trim();
                final displayName = isLawyer
                    ? clientNameAsync!.maybeWhen(data: (name) => name != null && name.trim().isNotEmpty ? name.trim() : 'اسم العميل غير متوفر', loading: () => 'جاري تحميل الاسم...', orElse: () => 'اسم العميل غير متوفر')
                    : (bookingName != null && bookingName.isNotEmpty ? bookingName : (rpcName != null && rpcName.isNotEmpty ? rpcName : 'اسم المحامي غير متوفر'));
                final lawyerAvatar = lawyerInfoAsync?.valueOrNull?['avatar_url']?.toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outlineVariant)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/booking-details', extra: booking),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (!isLawyer) ...[
                          CircleAvatar(radius: 26, backgroundColor: AppColors.surfaceContainerHigh, backgroundImage: lawyerAvatar != null && lawyerAvatar.isNotEmpty ? NetworkImage(lawyerAvatar) : null, child: lawyerAvatar == null || lawyerAvatar.isEmpty ? const Icon(Icons.person_outline, color: AppColors.primary) : null),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(displayName, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface))), const SizedBox(width: 8), _StatusChip(status: booking.status)]),
                          const SizedBox(height: 6),
                          Text(booking.consultationType ?? 'استشارة قانونية', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                          const SizedBox(height: 5),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [const Icon(Icons.schedule_rounded, size: 15, color: AppColors.onSurfaceVariant), const SizedBox(width: 4), Text(_formatDate(booking.scheduledAt), style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11))]),
                        ])),
                        const SizedBox(width: 6),
                        const Padding(padding: EdgeInsets.only(top: 16), child: Icon(Icons.chevron_left_rounded, color: AppColors.onSurfaceVariant)),
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} - ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim();
    Color background;
    Color foreground;
    if (normalized == 'مؤكد' || normalized == 'مكتمل' || normalized == 'قيد التنفيذ') {
      background = AppColors.acceptedBg;
      foreground = AppColors.acceptedText;
    } else if (normalized.contains('إلغاء') || normalized.contains('رفض') || normalized.contains('عدم حضور')) {
      background = AppColors.cancelledBg;
      foreground = AppColors.cancelledText;
    } else {
      background = AppColors.pendingBg;
      foreground = AppColors.pendingText;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: .45))), child: Text(normalized, style: TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w600)));
  }
}
