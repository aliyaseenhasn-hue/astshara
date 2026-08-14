import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            backgroundColor: AppColors.secondaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('لوحة المحامي', style: TextStyle(fontWeight: FontWeight.w800)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppColors.secondaryDark, AppColors.secondary, AppColors.primaryDark],
                        stops: [0, .62, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
                      child: Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            child: CircleAvatar(
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null,
                              child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 42, color: AppColors.secondary)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.fullName?.trim().isNotEmpty == true ? user!.fullName! : 'أستاذ قانون',
                            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          const Text('إدارة الاستشارات والمواعيد من مكان واحد', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _NotificationBell(
                      unreadCount: unread,
                      onTap: () => context.push('/notifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: bookingsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.only(top: 70), child: LoadingWidget()),
              error: (_, __) => const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('تعذر تحميل بيانات لوحة المحامي'))),
              data: (bookings) => Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.p20, 20, AppSizes.p20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverview(bookings),
                    const SizedBox(height: 28),
                    _sectionHeader('طلبات الاستشارة الواردة', 'عرض الكل', () => context.push('/bookings')),
                    const SizedBox(height: 12),
                    if (bookings.isEmpty) _emptyState() else ...bookings.take(5).map((booking) => _BookingCard(booking: booking)),
                    const SizedBox(height: 24),
                    const Text('الوصول السريع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    const SizedBox(height: 12),
                    _quickActions(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary))),
          TextButton(onPressed: onTap, child: const Text('عرض الكل', style: TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.bold))),
        ],
      );

  Widget _buildOverview(List<Booking> bookings) {
    final completed = bookings.where((b) => b.status == 'مكتمل').length;
    final active = bookings.where((b) => ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'قيد مراجعة المحامي', 'مؤكد', 'قيد التنفيذ'].contains(b.status)).length;
    final earnings = bookings.where((b) => b.status == 'مكتمل').fold<double>(0, (sum, b) => sum + b.price);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .16), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الأداء', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('$completed', 'استشارات مكتملة', Icons.gavel_rounded),
              _metric('$active', 'طلبات نشطة', Icons.timelapse_rounded),
              _metric('${(earnings / 1000).toStringAsFixed(1)} ألف', 'أرباح د.ع', Icons.payments_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, IconData icon) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      );

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            Icon(Icons.event_available_rounded, color: AppColors.gold, size: 34),
            SizedBox(height: 8),
            Text('لا توجد طلبات استشارة حالياً', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _quickActions(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _quickAction(context, Icons.calendar_month_rounded, 'المواعيد', '/bookings'),
          _quickAction(context, Icons.person_rounded, 'ملفي', '/lawyer-profile-edit'),
          _quickAction(context, Icons.schedule_rounded, 'أوقات التوفر', '/lawyer-availability'),
        ],
      );

  Widget _quickAction(BuildContext context, IconData icon, String label, String route) => ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.goldDark),
        label: Text(label),
        onPressed: () => context.push(route),
      );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/booking-details', extra: booking),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.goldLight.withValues(alpha: .45),
                child: const Icon(Icons.person_outline, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(displayName, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface))),
                        const SizedBox(width: 8),
                        _StatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(booking.consultationType ?? 'استشارة قانونية', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(_formatDate(booking.scheduledAt), textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}/$month/$day - $hour:$minute';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45))),
      child: Text(normalized, style: TextStyle(color: foreground, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'التنبيهات',
      child: Material(
        color: AppColors.secondaryDark.withValues(alpha: .72),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'التنبيهات',
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 26, color: Colors.white),
              if (unreadCount > 0)
                Positioned(
                  top: -5,
                  right: -7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.secondaryDark, width: 1.5),
                    ),
                    child: Text(unreadCount > 99 ? '99+' : '$unreadCount', style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 8, fontWeight: FontWeight.w900, height: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
