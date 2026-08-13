import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/bookings_provider.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateChangesProvider);
    final isLawyer = auth.maybeWhen(
      data: (user) => user?.role == 'lawyer',
      orElse: () => false,
    );
    final bookingsAsync = isLawyer
        ? ref.watch(lawyerBookingsProvider)
        : ref.watch(userBookingsProvider);
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: dark ? scheme.surfaceContainerHighest : AppColors.goldLight.withValues(alpha: .42),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.calendar_month_outlined, size: 42, color: dark ? AppColors.gold : AppColors.goldDark),
                    ),
                    const SizedBox(height: 18),
                    Text(isLawyer ? 'لا توجد طلبات واردة حالياً' : 'ليس لديك أي حجوزات حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: 8),
                    Text('ستظهر هنا الاستشارات عند توفرها.', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
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
                  final lawyerInfoAsync = isLawyer ? null : ref.watch(bookingLawyerInfoProvider(booking.id));
                  final displayName = isLawyer
                      ? clientNameAsync!.maybeWhen(
                          data: (name) => name != null && name.trim().isNotEmpty ? name.trim() : 'اسم العميل غير متوفر',
                          loading: () => 'جاري تحميل الاسم...',
                          orElse: () => 'اسم العميل غير متوفر',
                        )
                      : lawyerInfoAsync!.maybeWhen(
                          data: (info) {
                            final name = info?['full_name']?.toString().trim();
                            return name != null && name.isNotEmpty ? name : 'اسم المحامي غير متوفر';
                          },
                          loading: () => 'جاري تحميل اسم المحامي...',
                          orElse: () => 'اسم المحامي غير متوفر',
                        );
                  final lawyerAvatar = !isLawyer ? lawyerInfoAsync!.valueOrNull?['avatar_url']?.toString() : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: dark ? 0 : 1,
                    shadowColor: Colors.black.withValues(alpha: .05),
                    color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .82) : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: dark ? scheme.outlineVariant : AppColors.outline),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/booking-details', extra: booking),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (!isLawyer) ...[
                              CircleAvatar(
                                radius: 27,
                                backgroundColor: scheme.surfaceContainerHighest,
                                backgroundImage: lawyerAvatar != null && lawyerAvatar.isNotEmpty ? NetworkImage(lawyerAvatar) : null,
                                child: lawyerAvatar == null || lawyerAvatar.isEmpty ? Icon(Icons.person_rounded, color: scheme.onSurfaceVariant) : null,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(displayName, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                                  const SizedBox(height: 6),
                                  Text(booking.serviceType.isNotEmpty ? booking.serviceType : 'استشارة قانونية', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(booking.status, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
}
