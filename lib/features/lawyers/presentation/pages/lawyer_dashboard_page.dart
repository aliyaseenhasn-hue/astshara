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

class LawyerDashboardPage extends ConsumerWidget {
  const LawyerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final bookingsAsync = ref.watch(lawyerBookingsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user),
          SliverToBoxAdapter(
            child: bookingsAsync.when(
              data: (bookings) => Padding(
                padding: const EdgeInsets.all(AppSizes.p20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatsGrid(bookings),
                  const SizedBox(height: AppSizes.p32),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('طلبات الاستشارة الواردة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    TextButton(onPressed: () => context.push('/bookings'), child: const Text('عرض الكل')),
                  ]),
                  const SizedBox(height: AppSizes.p8),
                  if (bookings.isEmpty) _buildEmptyState() else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: bookings.length > 5 ? 5 : bookings.length, itemBuilder: (context, index) => _BookingTile(booking: bookings[index])),
                  const SizedBox(height: AppSizes.p32),
                  const Text('الإجراءات الإدارية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: AppSizes.p48),
                ]),
              ),
              loading: () => const Center(child: LoadingWidget()),
              error: (err, stack) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, dynamic user) => SliverAppBar(
    expandedHeight: 240,
    pinned: true,
    stretch: true,
    backgroundColor: AppColors.primary,
    actions: [
      IconButton(
        tooltip: 'الإشعارات',
        icon: const Icon(Icons.notifications_none_rounded, color: AppColors.goldLight),
        onPressed: () => context.push('/notifications'),
      ),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 40),
          Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: CircleAvatar(radius: 45, backgroundColor: AppColors.surfaceVariant, backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null, child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50, color: AppColors.primary) : null)),
          const SizedBox(height: 12),
          Text(user?.fullName ?? 'أستاذ قانون', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('لوحة التحكم المهنية', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ),
    ),
  );

  Widget _buildStatsGrid(List<Booking> bookings) {
    final earnings = bookings.where((b) => b.status == 'مكتمل').fold<double>(0.0, (sum, b) => sum + b.price);
    final active = bookings.where((b) => ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'مؤكد', 'قيد التنفيذ'].contains(b.status)).length;
    return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .9, children: [
      _StatCard(title: 'الاستشارات', value: bookings.where((b) => b.status == 'مكتمل').length.toString(), icon: Icons.gavel_rounded),
      _StatCard(title: 'نشطة', value: active.toString(), icon: Icons.timer_rounded, color: Colors.orange),
      _StatCard(title: 'الأرباح (د.ع)', value: '${(earnings / 1000).toStringAsFixed(1)} ألف', icon: Icons.payments_rounded, color: AppColors.success),
    ]);
  }

  Widget _buildEmptyState() => Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.outline.withValues(alpha: .3)), const SizedBox(height: 16), const Text('لا توجد طلبات استشارة حالية', style: TextStyle(color: AppColors.textSecondary))])));

  Widget _buildQuickActions(BuildContext context) => Column(children: [
    _ActionTile(title: 'إدارة المواعيد المتاحة', subtitle: 'نشر المواعيد التي يمكن حجزها فعليًا', icon: Icons.event_available_rounded, onTap: () => context.push('/lawyer-availability')),
    _ActionTile(title: 'جدول الحجوزات', subtitle: 'عرض الاستشارات ومتابعة حالاتها', icon: Icons.calendar_today_rounded, onTap: () => context.push('/bookings')),
    _ActionTile(title: 'المحفظة المالية', subtitle: 'تتبع المستحقات وطلبات السحب', icon: Icons.account_balance_wallet_rounded, onTap: () => context.push('/payment-methods')),
    _ActionTile(title: 'تغيير التخصص', subtitle: 'إرسال طلب تعديل الاختصاصات', icon: Icons.edit_note_rounded, onTap: () => context.push('/lawyer-specialization-change')),
    _ActionTile(title: 'تعديل باقات الاستشارة', subtitle: 'إضافة أو تعديل خدماتك وأسعارك', icon: Icons.design_services_rounded, onTap: () => context.push('/lawyer-profile-edit')),
  ]);
}

class _StatCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color? color;
  const _StatCard({required this.title, required this.value, required this.icon, this.color});
  @override Widget build(BuildContext context) => Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color ?? AppColors.primary, size: 28), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]));
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: Consumer(builder: (context, ref, child) { final name = ref.watch(bookingClientNameProvider(booking.id)); return ListTile(leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.person_outline, color: AppColors.primary)), title: Text(name.maybeWhen(data: (n) => n != null && n.trim().isNotEmpty ? n : 'اسم العميل غير متوفر', loading: () => 'جاري تحميل اسم العميل...', error: (_, __) => 'اسم العميل غير متوفر', orElse: () => 'اسم العميل غير متوفر'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(intl.DateFormat('yyyy/MM/dd').format(booking.scheduledAt), style: const TextStyle(fontSize: 12)), trailing: _StatusChip(status: booking.status), onTap: () => context.push('/booking-details', extra: booking)); }));
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override Widget build(BuildContext context) { Color color = Colors.grey; switch (status) { case 'قيد انتظار الدفع': color = Colors.orange; break; case 'قيد معالجة الدفع': color = Colors.blue; break; case 'مؤكد': color = AppColors.success; break; case 'قيد التنفيذ': color = AppColors.primary; break; case 'مكتمل': color = AppColors.success; break; case 'ملغي': case 'مرفوض': color = AppColors.error; break; case 'مسترد': color = Colors.grey; break; } return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))); }
}

class _ActionTile extends StatelessWidget {
  final String title; final String subtitle; final IconData icon; final VoidCallback onTap;
  const _ActionTile({required this.title, required this.subtitle, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14), onTap: onTap));
}
