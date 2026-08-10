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
                  _sectionHeader(context, 'طلبات الاستشارة الواردة', 'عرض الكل', () => context.push('/bookings')),
                  const SizedBox(height: AppSizes.p12),
                  if (bookings.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: bookings.length > 5 ? 5 : bookings.length, itemBuilder: (context, index) => _BookingCard(booking: bookings[index])),
                  const SizedBox(height: AppSizes.p32),
                  const Text('الإجراءات الإدارية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
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

  Widget _sectionHeader(BuildContext context, String title, String action, VoidCallback onTap) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    TextButton(onPressed: onTap, child: Text(action)),
  ]);

  Widget _buildSliverAppBar(BuildContext context, dynamic user) => SliverAppBar(
    expandedHeight: 240, pinned: true, stretch: true, backgroundColor: AppColors.primary,
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

  Widget _buildEmptyState() => Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.outline.withValues(alpha: .15))), child: Column(children: [Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.outline.withValues(alpha: .4)), const SizedBox(height: 12), const Text('لا توجد طلبات استشارة حالية', style: TextStyle(color: AppColors.textSecondary))]));

  Widget _buildQuickActions(BuildContext context) => Column(children: [
    _ActionCard(title: 'إدارة المواعيد المتاحة', subtitle: 'نشر المواعيد التي يمكن حجزها فعليًا', icon: Icons.event_available_rounded, onTap: () => context.push('/lawyer-availability')),
    _ActionCard(title: 'جدول الحجوزات', subtitle: 'عرض الاستشارات ومتابعة حالاتها', icon: Icons.calendar_today_rounded, onTap: () => context.push('/bookings')),
    _ActionCard(title: 'المحفظة المالية', subtitle: 'تتبع المستحقات وطلبات السحب', icon: Icons.account_balance_wallet_rounded, onTap: () => context.push('/payment-methods')),
    _ActionCard(title: 'تغيير التخصص', subtitle: 'إرسال طلب تعديل الاختصاصات', icon: Icons.edit_note_rounded, onTap: () => context.push('/lawyer-specialization-change')),
    _ActionCard(title: 'تعديل باقات الاستشارة', subtitle: 'إضافة أو تعديل خدماتك وأسعارك', icon: Icons.design_services_rounded, onTap: () => context.push('/lawyer-profile-edit')),
  ]);
}

class _StatCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color? color;
  const _StatCard({required this.title, required this.value, required this.icon, this.color});
  @override Widget build(BuildContext context) => Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color ?? AppColors.primary, size: 28), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]));
}

class _BookingCard extends StatefulWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  @override State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: _hovered ? [BoxShadow(color: AppColors.secondary.withValues(alpha: .22), blurRadius: 22, offset: const Offset(0, 9))] : [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _hovered ? AppColors.secondary.withValues(alpha: .5) : AppColors.outline.withValues(alpha: .12))),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/booking-details', extra: widget.booking),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Consumer(builder: (context, ref, child) {
                  final name = ref.watch(bookingClientNameProvider(widget.booking.id));
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AnimatedContainer(duration: const Duration(milliseconds: 180), width: 52, height: 52, decoration: BoxDecoration(color: _hovered ? AppColors.secondary.withValues(alpha: .15) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.person_outline_rounded, color: _hovered ? AppColors.secondary : AppColors.primary, size: 28)),
                      const SizedBox(width: 13),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.maybeWhen(data: (n) => n != null && n.trim().isNotEmpty ? n : 'اسم العميل غير متوفر', loading: () => 'جاري تحميل اسم العميل...', error: (_, __) => 'اسم العميل غير متوفر', orElse: () => 'اسم العميل غير متوفر'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 5),
                        Text('رقم الحجز: #${widget.booking.id.length >= 8 ? widget.booking.id.substring(0, 8) : widget.booking.id}', style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                      ])),
                      _StatusChip(status: widget.booking.status),
                    ]),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: AppColors.outline.withValues(alpha: .12)),
                    const SizedBox(height: 13),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 17, color: AppColors.outline),
                      const SizedBox(width: 7),
                      Expanded(child: Text(intl.DateFormat('yyyy/MM/dd - HH:mm').format(widget.booking.scheduledAt), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
                    ]),
                  ]);
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override Widget build(BuildContext context) { Color color = Colors.grey; switch (status) { case 'قيد انتظار الدفع': color = Colors.orange; break; case 'قيد معالجة الدفع': color = Colors.blue; break; case 'مؤكد': color = AppColors.success; break; case 'قيد التنفيذ': color = AppColors.primary; break; case 'مكتمل': color = AppColors.success; break; case 'ملغي': case 'مرفوض': color = AppColors.error; break; case 'مسترد': color = Colors.grey; break; } return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(9)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))); }
}

class _ActionCard extends StatefulWidget {
  final String title; final String subtitle; final IconData icon; final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  @override State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: _hovered ? [BoxShadow(color: AppColors.primary.withValues(alpha: .2), blurRadius: 22, offset: const Offset(0, 9))] : [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _hovered ? AppColors.secondary.withValues(alpha: .5) : AppColors.outline.withValues(alpha: .12))),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15), child: Row(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 180), width: 52, height: 52, decoration: BoxDecoration(color: _hovered ? AppColors.primary.withValues(alpha: .13) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(15)), child: Icon(widget.icon, color: _hovered ? AppColors.secondary : AppColors.primary, size: 27)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 5), Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                AnimatedSlide(duration: const Duration(milliseconds: 180), offset: Offset(_hovered ? -0.18 : 0, 0), child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _hovered ? AppColors.secondary : AppColors.outline)),
              ])),
            ),
          ),
        ),
      ),
    ),
  );
}
