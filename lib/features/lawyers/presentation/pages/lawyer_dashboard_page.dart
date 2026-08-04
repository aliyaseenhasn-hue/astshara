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
          _buildSliverAppBar(user),
          SliverToBoxAdapter(
            child: bookingsAsync.when(
              data: (bookings) => Padding(
                padding: const EdgeInsets.all(AppSizes.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(bookings),
                    const SizedBox(height: AppSizes.p32),
                    const Text(
                      'الاستشارات الأخيرة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                    if (bookings.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookings.length > 5 ? 5 : bookings.length,
                        itemBuilder: (context, index) {
                          return _BookingTile(booking: bookings[index]);
                        },
                      ),
                    const SizedBox(height: AppSizes.p24),
                    _buildQuickActions(context, ref),
                  ],
                ),
              ),
              loading: () => const Center(child: LoadingWidget()),
              error: (err, stack) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.loginGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      width: 25,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: user?.avatarUrl != null &&
                                  user!.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null ||
                                  user!.avatarUrl!.isEmpty
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'مرحباً بك دكتور،',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user?.fullName ?? 'أستاذ قانون',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<Booking> bookings) {
    final totalEarnings = bookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.price);
    final pendingCount = bookings
        .where((b) => b.status == 'pending' || b.status == 'accepted')
        .length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatCard(
            title: 'الاستشارات',
            value: bookings.length.toString(),
            icon: Icons.gavel),
        _StatCard(
            title: 'نشطة',
            value: pendingCount.toString(),
            icon: Icons.timer,
            color: AppColors.secondary),
        _StatCard(
            title: 'الأرباح',
            value: '${(totalEarnings / 1000).toStringAsFixed(0)}k',
            icon: Icons.payments,
            color: Colors.green),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.assignment_late_outlined,
              size: 64, color: AppColors.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('لا توجد استشارات حالية',
              style: TextStyle(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          title: 'جدول المواعيد',
          subtitle: 'عرض كافة الحجوزات المؤكدة',
          icon: Icons.calendar_month,
          onTap: () => context.push('/bookings'),
        ),
        _ActionTile(
          title: 'المحفظة المالية',
          subtitle: 'تتبع مستحقاتك وسحب الأرباح',
          icon: Icons.account_balance_wallet,
          onTap: () {},
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('تسجيل الخروج',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.bold)),
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.grey),
          title: const Text('حذف الحساب نهائياً',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          onTap: () => _showDeleteConfirmation(context, ref),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text(
            'هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء وسيتم حذف كافة بياناتك وحجوزاتك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).deleteAccount();
            },
            child: const Text('نعم، احذف نهائياً',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text(title,
              style: const TextStyle(fontSize: 10, color: AppColors.outline)),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: const Text('استشارة قانونية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          intl.DateFormat('yyyy/MM/dd - HH:mm').format(booking.scheduledAt),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${booking.price.toInt()} د.ع',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12)),
            const SizedBox(height: 4),
            _StatusChip(status: booking.status),
          ],
        ),
        onTap: () => context.push('/bookings'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String text = status;
    if (status == 'pending') {
      color = Colors.orange;
      text = 'معلق';
    }
    if (status == 'accepted') {
      color = Colors.blue;
      text = 'مؤكد';
    }
    if (status == 'completed') {
      color = Colors.green;
      text = 'مكتمل';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
