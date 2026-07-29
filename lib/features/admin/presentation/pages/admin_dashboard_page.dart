import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحكم (Admin)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نظرة عامة',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.p16),

            // Statistics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('إجمالي المستخدمين',
                    stats['total_users'].toString(), Icons.people, Colors.blue),
                _buildStatCard(
                    'إجمالي المحامين',
                    stats['total_lawyers'].toString(),
                    Icons.gavel,
                    Colors.orange),
                _buildStatCard(
                    'طلبات توثيق',
                    stats['pending_verifications'].toString(),
                    Icons.verified_user,
                    Colors.purple),
                _buildStatCard(
                    'حجوزات نشطة',
                    stats['active_bookings'].toString(),
                    Icons.calendar_today,
                    Colors.green),
              ],
            ),

            const SizedBox(height: AppSizes.p32),

            // Revenue Section
            _buildRevenueCard(stats['total_revenue']),

            const SizedBox(height: AppSizes.p32),

            // Quick Actions
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p16),
            _buildAdminActionTile(
                'مراجعة الدفعات المعلقة',
                '${stats['pending_payments']} دفعات جديدة',
                Icons.payment,
                Colors.red,
                () => context.push('/admin/payments')),
            _buildAdminActionTile(
                'طلبات انضمام المحامين',
                '${stats['pending_verifications']} طلبات مراجعة',
                Icons.person_add,
                Colors.amber,
                () => context.push('/admin/lawyer-verifications')),
            _buildAdminActionTile(
                'إدارة جميع المستخدمين',
                'تعديل أو حظر حسابات',
                Icons.manage_accounts,
                AppColors.primary,
                () {}),
            _buildAdminActionTile('إحصائيات التقارير', 'بلاغات وتحليلات',
                Icons.bar_chart, Colors.teal, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text(title,
              style: const TextStyle(fontSize: 12, color: AppColors.outline),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الأرباح المجمعة',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$amount د.ع',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          const Text('تحديث فوري للقيمة الصافية',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
