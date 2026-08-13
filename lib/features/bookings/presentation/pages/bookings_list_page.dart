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
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(isLawyer ? 'استشارات العملاء' : 'استشاراتي'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('تعذر تحميل الاستشارات', style: TextStyle(color: scheme.onSurface))),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Text(
                isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً',
                style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Consumer(
                builder: (context, ref, child) {
                  final clientNameAsync = isLawyer ? ref.watch(bookingClientNameProvider(booking.id)) : null;
                  final lawyerInfoAsync = !isLawyer ? ref.watch(bookingLawyerInfoProvider(booking.id)) : null;
                  final rpcName = lawyerInfoAsync?.valueOrNull?['full_name']?.toString().trim();
                  final bookingName = booking.lawyerName?.trim();
                  final displayName = isLawyer
                      ? clientNameAsync!.maybeWhen(
                          data: (name) => name != null && name.trim().isNotEmpty ? name.trim() : 'اسم العميل غير متوفر',
                          loading: () => 'جاري تحميل الاسم...',
                          orElse: () => 'اسم العميل غير متوفر',
                        )
                      : (bookingName != null && bookingName.isNotEmpty
                          ? bookingName
                          : (rpcName != null && rpcName.isNotEmpty ? rpcName : 'اسم المحامي غير متوفر'));
                  final lawyerAvatar = lawyerInfoAsync?.valueOrNull?['avatar_url']?.toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: dark ? 0 : 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/booking-details', extra: booking),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (!isLawyer) ...[
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: dark ? scheme.surfaceContainerHighest : AppColors.goldLight,
                                backgroundImage: lawyerAvatar != null && lawyerAvatar.isNotEmpty ? NetworkImage(lawyerAvatar) : null,
                                child: lawyerAvatar == null || lawyerAvatar.isEmpty
                                    ? Icon(Icons.person_outline, color: dark ? AppColors.gold : AppColors.goldDark)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                                  const SizedBox(height: 6),
                                  Text(booking.consultationType ?? 'استشارة قانونية', style: TextStyle(color: scheme.onSurfaceVariant)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(booking.scheduledAt), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year/$month/$day - $hour:$minute';
  }
}
