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
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 245,
          backgroundColor: AppColors.secondaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('لوحة المحامي', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(background: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.secondaryDark, AppColors.secondary, AppColors.primaryDark], stops: [0, .62, 1])),
            child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 72, 20, 20), child: Column(children: [
              Container(width: 78, height: 78, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle), child: CircleAvatar(backgroundColor: AppColors.surfaceVariant, backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null, child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 42, color: AppColors.secondary) : null)),
              const SizedBox(height: 10),
              Text(user?.fullName?.trim().isNotEmpty == true ? user!.fullName! : 'أستاذ قانون', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('إدارة الاستشارات والمواعيد من مكان واحد', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]))),
          )),
        ),
        SliverToBoxAdapter(child: bookingsAsync.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 70), child: LoadingWidget()),
          error: (_, __) => const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('تعذر تحميل بيانات لوحة المحامي'))),
          data: (bookings) => Padding(padding: const EdgeInsets.fromLTRB(AppSizes.p20, 20, AppSizes.p20, 110), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildOverview(bookings),
            const SizedBox(height: 28),
            _sectionHeader('طلبات الاستشارة الواردة', 'عرض الكل', () => context.push('/bookings')),
            const SizedBox(height: 12),
            if (bookings.isEmpty) _emptyState() else ...bookings.take(5).map((booking) => _BookingCard(booking: booking)),
            const SizedBox(height: 24),
            const Text('الوصول السريع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 12),
            _quickActions(context),
          ])),
        )),
      ]),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary))), TextButton(onPressed: onTap, child: const Text('عرض الكل', style: TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.bold)))]);

  Widget _buildOverview(List<Booking> bookings) {
    final completed = bookings.where((b) => b.status == 'مكتمل').length;
    final active = bookings.where((b) => ['قيد انتظار الدفع','قيد معالجة الدفع','قيد مراجعة المحامي','مؤكد','قيد التنفيذ'].contains(b.status)).length;
    final earnings = bookings.where((b) => b.status == 'مكتمل').fold<double>(0, (sum, b) => sum + b.price);
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .16), blurRadius: 20, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ملخص الأداء', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Row(children: [_metric('$completed', 'استشارات مكتملة', Icons.gavel_rounded), _metric('$active', 'طلبات نشطة', Icons.timelapse_rounded), _metric('${(earnings/1000).toStringAsFixed(1)} ألف', 'أرباح د.ع', Icons.payments_rounded)]),
    ]);
  }

  Widget _metric(String value, String label, IconData icon) => Expanded(child: Column(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.gold)), const SizedBox(height: 8), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 9))]));

  Widget _emptyState() => Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.outline)), child: const Column(children: [Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.outline), SizedBox(height: 12), Text('لا توجد طلبات استشارة حالياً', style: TextStyle(color: AppColors.textSecondary))]));

  Widget _quickActions(BuildContext context) => Column(children: [
    _ActionCard(title: 'إدارة المواعيد المتاحة', subtitle: 'حدد الأوقات التي يمكن حجزها فعلياً', icon: Icons.event_available_rounded, onTap: () => context.push('/lawyer-availability')),
    _ActionCard(title: 'جدول الحجوزات', subtitle: 'تابع الطلبات وحالات الاستشارات', icon: Icons.calendar_month_rounded, onTap: () => context.push('/bookings')),
    _ActionCard(title: 'طرق الدفع', subtitle: 'إدارة المحفظة المرتبطة بالحساب', icon: Icons.account_balance_wallet_rounded, onTap: () => context.push('/payment-methods')),
    _ActionCard(title: 'تغيير التخصص', subtitle: 'إرسال طلب تعديل الاختصاصات للإدارة', icon: Icons.badge_outlined, onTap: () => context.push('/lawyer-specialization-change')),
    _ActionCard(title: 'تعديل الملف والباقات', subtitle: 'حدّث الخدمات والأسعار وبياناتك المهنية', icon: Icons.edit_note_rounded, onTap: () => context.push('/lawyer-profile-edit')),
  ]);
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 4))]), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => context.push('/booking-details', extra: booking), child: Padding(padding: const EdgeInsets.all(15), child: Consumer(builder: (context, ref, child) {
    final name = ref.watch(bookingClientNameProvider(booking.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryDark)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.maybeWhen(data: (n) => n?.trim().isNotEmpty == true ? n! : 'اسم العميل غير متوفر', loading: () => 'جاري تحميل الاسم...', error: (_, __) => 'اسم العميل غير متوفر', orElse: () => 'اسم العميل غير متوفر'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary)), const SizedBox(height: 3), Text('الحجز #${booking.id.length >= 8 ? booking.id.substring(0,8) : booking.id}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))])), _StatusChip(status: booking.status)]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.schedule_rounded, size: 17, color: AppColors.primaryDark), const SizedBox(width: 7), Expanded(child: Text(intl.DateFormat('yyyy/MM/dd - HH:mm').format(booking.scheduledAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))), Text('${booking.price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary))])),
    ]);
  }))));
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) { var color = AppColors.textSecondary; if (status == 'مؤكد' || status == 'مكتمل') color = AppColors.success; if (status.contains('انتظار') || status.contains('معالجة')) color = AppColors.warning; if (status.contains('مراجعة')) color = AppColors.info; if (status == 'ملغي' || status == 'مرفوض') color = AppColors.error; return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800))); }
}

class _ActionCard extends StatelessWidget {
  final String title; final String subtitle; final IconData icon; final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.primaryDark)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.secondary)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])), const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline)]))));
}
