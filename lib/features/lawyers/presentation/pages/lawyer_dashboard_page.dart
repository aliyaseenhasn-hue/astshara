import 'package:astshara/features/lawyers/presentation/providers/lawyers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/entities/booking.dart';
import 'package:intl/intl.dart' as intl;

final bookingClientNameProvider = FutureProvider.family<String?, String>((ref, bookingId) async {
  final response = await SupabaseConfig.client.rpc('get_booking_client_name', params: {
    'p_booking_id': bookingId,
  });
  final rows = response as List;
  if (rows.isEmpty) return null;
  final row = Map<String, dynamic>.from(rows.first as Map);
  final name = row['full_name']?.toString().trim();
  return name == null || name.isEmpty ? null : name;
});

class LawyerDashboardPage extends ConsumerWidget {
  const LawyerDashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final bookingsAsync = ref.watch(lawyerBookingsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(background: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark])),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 35),
              CircleAvatar(radius: 42, backgroundColor: Colors.white, backgroundImage: user?.avatarUrl?.isNotEmpty == true ? NetworkImage(user!.avatarUrl!) : null, child: user?.avatarUrl?.isNotEmpty == true ? null : const Icon(Icons.person, size: 45, color: AppColors.primary)),
              const SizedBox(height: 10),
              Text(user?.fullName ?? 'أستاذ قانون', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('لوحة التحكم المهنية', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          )),
          actions: [IconButton(onPressed: () => context.push('/profile'), icon: const Icon(Icons.settings_outlined, color: Colors.white))],
        ),
        SliverToBoxAdapter(child: bookingsAsync.when(
          loading: () => const Center(child: LoadingWidget()),
          error: (e, _) => Center(child: Text('تعذر تحميل الحجوزات: $e')),
          data: (bookings) => Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _stats(bookings),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الحجوزات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: () => context.push('/bookings'), child: const Text('عرض الكل'))]),
              const SizedBox(height: 8),
              if (bookings.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('لا توجد حجوزات حالياً')))) else ...bookings.take(8).map((booking) => _BookingTile(booking: booking)),
              const SizedBox(height: 24),
              const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ActionTile(title: 'طلبات الاستشارة المخصصة', subtitle: 'مراجعة الطلبات التي لا تناسب الباقات الحالية', icon: Icons.markunread_mail_outline_rounded, onTap: () => context.push('/lawyer-custom-requests')),
              _ActionTile(title: 'إدارة المواعيد المتاحة', subtitle: 'إضافة أو حذف أوقات يمكن حجزها', icon: Icons.event_available_rounded, onTap: () => context.push('/lawyer-availability')),
              _ActionTile(title: 'جدول الحجوزات', subtitle: 'عرض الحجوزات ومتابعة الاستشارات', icon: Icons.calendar_today_rounded, onTap: () => context.push('/bookings')),
              _ActionTile(title: 'تعديل باقات الاستشارة', subtitle: 'إضافة أو تعديل خدماتك وأسعارك', icon: Icons.design_services_rounded, onTap: () => context.push('/lawyer-profile-edit')),
              _ActionTile(title: 'المحفظة المالية', subtitle: 'متابعة المستحقات وطلبات السحب', icon: Icons.account_balance_wallet_rounded, onTap: () => context.push('/payment-methods')),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _stats(List<Booking> bookings) {
    final completed = bookings.where((b) => b.status == 'مكتمل').length;
    final active = bookings.where((b) => ['بانتظار التأكيد', 'مؤكد', 'قيد التنفيذ'].contains(b.status)).length;
    final earnings = bookings.where((b) => b.status == 'مكتمل').fold<double>(0, (sum, b) => sum + b.price);
    return Row(children: [Expanded(child: _StatCard(title: 'مكتملة', value: completed.toString(), icon: Icons.check_circle_outline)), const SizedBox(width: 10), Expanded(child: _StatCard(title: 'نشطة', value: active.toString(), icon: Icons.timer_outlined, color: Colors.orange)), const SizedBox(width: 10), Expanded(child: _StatCard(title: 'الأرباح (د.ع)', value: earnings.toStringAsFixed(0), icon: Icons.payments_outlined, color: AppColors.success))]);
  }
}

class _StatCard extends StatelessWidget { final String title, value; final IconData icon; final Color? color; const _StatCard({required this.title, required this.value, required this.icon, this.color}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6), child: Column(children: [Icon(icon, color: color ?? AppColors.primary), const SizedBox(height: 8), Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]))); }
class _BookingTile extends ConsumerWidget {
  final Booking booking;
  const _BookingTile({required this.booking});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(bookingClientNameProvider(booking.id));
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: nameAsync.when(
          loading: () => const Text('جاري تحميل اسم العميل...'),
          error: (_, __) => const Text('اسم العميل غير متوفر'),
          data: (name) => Text(
            name ?? 'اسم العميل غير متوفر',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Text('${intl.DateFormat('yyyy/MM/dd').format(booking.scheduledAt)} • ${booking.packageName ?? 'استشارة'}'),
        trailing: _StatusChip(booking.status),
        onTap: () => context.push('/booking-details', extra: booking),
      ),
    );
  }
}
class _StatusChip extends StatelessWidget { final String status; const _StatusChip(this.status); @override Widget build(BuildContext context) { final color = _color(status); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))); } Color _color(String value) { switch (value) { case 'مؤكد': return AppColors.success; case 'قيد التنفيذ': return Colors.blue; case 'مكتمل': return Colors.green; case 'ملغي': case 'مسترد': return AppColors.error; case 'بانتظار التأكيد': return Colors.orange; default: return Colors.grey; } } }
class _ActionTile extends StatelessWidget { final String title, subtitle; final IconData icon; final VoidCallback onTap; const _ActionTile({required this.title, required this.subtitle, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14), onTap: onTap)); }
