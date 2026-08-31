import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/entities/booking.dart';

class LawyerDashboardPage extends ConsumerWidget {
  const LawyerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final bookings = ref.watch(lawyerBookingsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('لوحة المحامي'), centerTitle: true),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('تعذر تحميل البيانات')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(user?.fullName ?? 'أستاذ قانون', textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                onTap: () => context.push('/lawyer-profile-edit'),
                leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
                title: const Text('ملفي المهني', textAlign: TextAlign.right),
                subtitle: const Text('النبذة والإنجازات والقرارات والشهادات', textAlign: TextAlign.right),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _Metric('${items.where((b) => b.status == 'مكتمل').length}', 'مكتملة'),
                    _Metric('${items.where((b) => b.status == 'مؤكد' || b.status == 'قيد التنفيذ').length}', 'نشطة'),
                    _Metric('${items.fold<double>(0, (s, b) => s + b.price).toStringAsFixed(0)}', 'د.ع'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('طلبات الاستشارة الواردة', textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (items.isEmpty) const _EmptyState() else ...items.take(5).map((b) => _BookingCard(booking: b)),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))]));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)), child: const Column(children: [Icon(Icons.event_available_rounded, color: AppColors.gold, size: 34), SizedBox(height: 8), Text('لا توجد طلبات استشارة حالياً', style: TextStyle(fontWeight: FontWeight.w700))]));
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: () => context.push('/booking-details', extra: booking), title: Text(booking.consultationType ?? 'استشارة قانونية', textDirection: TextDirection.rtl, textAlign: TextAlign.right), subtitle: Text(booking.status, textDirection: TextDirection.rtl, textAlign: TextAlign.right), trailing: const Icon(Icons.chevron_left_rounded)));
}
