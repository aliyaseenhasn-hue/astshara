import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../profile/presentation/providers/notifications_provider.dart';

class LawyerDashboardPage extends ConsumerWidget {
  const LawyerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final bookingsAsync = ref.watch(lawyerBookingsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 245,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('لوحة المحامي', style: TextStyle(fontWeight: FontWeight.w700)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.primary, AppColors.primaryDark, AppColors.tertiary], stops: [0, .62, 1]))),
                SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 72, 20, 20), child: Column(children: [
                  Container(width: 78, height: 78, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle), child: CircleAvatar(backgroundColor: AppColors.surfaceVariant, backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null, child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 42, color: AppColors.primary) : null)),
                  const SizedBox(height: 10),
                  Text(user?.fullName?.trim().isNotEmpty == true ? user!.fullName! : 'أستاذ قانون', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  const Text('إدارة الاستشارات والمواعيد من مكان واحد', style: TextStyle(color: Color(0xFFDDE5ED), fontSize: 12)),
                ]))),
                Positioned(top: 8, right: 8, child: _NotificationBell(unreadCount: unread, onTap: () => context.push('/notifications'))),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: FutureBuilder<_SetupState>(future: _loadSetupState(ref), builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 8);
            final setup = snapshot.data;
            if (setup == null || setup.complete) return const SizedBox(height: 8);
            return Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), child: _SetupAlert(setup: setup, onTap: () => context.push('/lawyer-profile-edit')));
          })),
          SliverToBoxAdapter(child: bookingsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.only(top: 70), child: LoadingWidget()),
            error: (_, __) => const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('تعذر تحميل بيانات لوحة المحامي'))),
            data: (bookings) => Padding(padding: const EdgeInsets.fromLTRB(AppSizes.p20, 20, AppSizes.p20, 110), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _buildOverview(bookings),
              const SizedBox(height: 28),
              _sectionHeader('طلبات الاستشارة الواردة', 'عرض الكل', () => context.push('/bookings')),
              const SizedBox(height: 12),
              if (bookings.isEmpty) _emptyState() else ...bookings.take(5).map((booking) => _BookingCard(booking: booking)),
            ])),
          )),
        ],
      ),
    );
  }

  Future<_SetupState> _loadSetupState(WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return const _SetupState(false, false);
    try {
      final profile = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
      final profileId = profile?['id']?.toString();
      if (profileId == null) return const _SetupState(false, false);
      final lawyer = await SupabaseConfig.client.from('lawyer_profiles').select('services, availability, verified').eq('profile_id', profileId).maybeSingle();
      final services = lawyer?['services'];
      final hasPackage = services is List && services.any((item) => item is Map && (item['title']?.toString().trim().isNotEmpty ?? false) && (double.tryParse(item['price']?.toString() ?? '') ?? 0) > 0);
      final slots = await SupabaseConfig.client.from('lawyer_availability_slots').select('id').eq('lawyer_id', profileId).eq('is_available', true).gte('starts_at', DateTime.now().toUtc().toIso8601String()).limit(1);
      final hasSlots = slots is List && slots.isNotEmpty;
      return _SetupState(hasPackage, hasSlots);
    } catch (_) {
      return const _SetupState(false, false);
    }
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary))), TextButton(onPressed: onTap, child: const Text('عرض الكل'))]);

  Widget _buildOverview(List<Booking> bookings) {
    final completed = bookings.where((b) => b.status == 'مكتمل').length;
    final active = bookings.where((b) => ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'قيد مراجعة المحامي', 'مؤكد', 'قيد التنفيذ'].contains(b.status)).length;
    final earnings = bookings.where((b) => b.status == 'مكتمل').fold<double>(0, (sum, b) => sum + b.price);
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .06), blurRadius: 24, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      const Text('ملخص الأداء', style: TextStyle(color: AppColors.goldLight, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 18), Row(children: [_metric('$completed', 'استشارات مكتملة', Icons.gavel_rounded), _metric('$active', 'طلبات نشطة', Icons.timelapse_rounded), _metric('${(earnings / 1000).toStringAsFixed(1)} ألف', 'أرباح د.ع', Icons.payments_rounded)]),
    ]));
  }

  Widget _metric(String value, String label, IconData icon) => Expanded(child: Column(children: [Icon(icon, color: AppColors.gold, size: 24), const SizedBox(height: 6), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDDE5ED), fontSize: 10))]));

  Widget _emptyState() => Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)), child: const Column(children: [Icon(Icons.event_available_rounded, color: AppColors.gold, size: 34), SizedBox(height: 8), Text('لا توجد طلبات استشارة حالياً', style: TextStyle(fontWeight: FontWeight.w600))]));
}

class _SetupState {
  final bool hasPackage;
  final bool hasSlots;
  const _SetupState(this.hasPackage, this.hasSlots);
  bool get complete => hasPackage && hasSlots;
}

class _SetupAlert extends StatelessWidget {
  final _SetupState setup;
  final VoidCallback onTap;
  const _SetupAlert({required this.setup, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final title = !setup.hasPackage ? 'أكمل معلومات استقبال الاستشارات' : 'حدد أوقات التوفر لاستقبال الطلبات';
    final message = !setup.hasPackage ? 'أضف باقات الاستشارات وأسعارها أولاً، ثم انتقل إلى أوقات التوفر.' : 'تم إعداد الباقات. بقي تحديد مواعيد التوفر حتى يتمكن طالب الاستشارة من الحجز.';
    return Card(color: AppColors.secondary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(textDirection: TextDirection.rtl, children: [Container(width: 42, height: 42, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle), child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.secondary)), const SizedBox(width: 12), Expanded(child: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)))]),
      const SizedBox(height: 10), Text(message, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 12)),
      const SizedBox(height: 14), FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.arrow_back_rounded), label: Text(!setup.hasPackage ? 'إكمال المعلومات' : 'تعديل الباقات وإضافة الأوقات'), style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    ])));
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final clientNameAsync = ref.watch(bookingClientNameProvider(booking.id));
    final clientName = clientNameAsync.valueOrNull;
    final displayName = clientName != null && clientName.trim().isNotEmpty ? clientName.trim() : 'اسم العميل غير متوفر';
    return Card(margin: const EdgeInsets.only(bottom: 12), color: scheme.surfaceContainerLowest, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => context.push('/booking-details', extra: booking), child: Padding(padding: const EdgeInsets.all(20), child: Row(textDirection: TextDirection.rtl, children: [CircleAvatar(radius: 24, backgroundColor: AppColors.goldLight.withValues(alpha: .45), child: const Icon(Icons.person_outline, color: AppColors.goldDark)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(displayName, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface))), const SizedBox(width: 8), _StatusChip(status: booking.status)]), const SizedBox(height: 6), Text(booking.consultationType ?? 'استشارة قانونية', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)), const SizedBox(height: 5), Text(_formatDate(booking.scheduledAt), textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11))])), const SizedBox(width: 6), Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant)]))));
  }
  String _formatDate(DateTime date) { final local = date.toLocal(); final day = local.day.toString().padLeft(2, '0'); final month = local.month.toString().padLeft(2, '0'); final hour = local.hour.toString().padLeft(2, '0'); final minute = local.minute.toString().padLeft(2, '0'); return '${local.year}/$month/$day - $hour:$minute'; }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final normalized = status.trim();
    final accepted = normalized == 'مؤكد' || normalized == 'مكتمل' || normalized == 'قيد التنفيذ';
    final cancelled = normalized.contains('إلغاء') || normalized.contains('رفض') || normalized.contains('عدم حضور');
    final background = accepted ? AppColors.acceptedBg : (cancelled ? AppColors.cancelledBg : AppColors.pendingBg);
    final foreground = accepted ? AppColors.acceptedText : (cancelled ? AppColors.cancelledText : AppColors.pendingText);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45))), child: Text(normalized, style: TextStyle(color: foreground, fontSize: 9.5, fontWeight: FontWeight.w700)));
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const _NotificationBell({required this.unreadCount, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: 'التنبيهات', child: Material(color: AppColors.primaryDark.withValues(alpha: .85), shape: const CircleBorder(), child: IconButton(tooltip: 'التنبيهات', onPressed: onTap, icon: Stack(clipBehavior: Clip.none, children: [const Icon(Icons.notifications_none_rounded, size: 26, color: Colors.white), if (unreadCount > 0) Positioned(top: -5, right: -7, child: Container(constraints: const BoxConstraints(minWidth: 17, minHeight: 17), padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.primary, width: 1.5)), child: Text(unreadCount > 99 ? '99+' : '$unreadCount', style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 8, fontWeight: FontWeight.w900, height: 1))))]))));
}
