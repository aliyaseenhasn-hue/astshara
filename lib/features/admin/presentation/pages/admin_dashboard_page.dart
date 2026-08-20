import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => ref.read(adminStatsProvider.notifier).refresh(), icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _errorView(ref),
        data: (stats) => _dashboard(context, stats),
      ),
    );
  }

  Widget _errorView(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          const Text('تعذر تحميل الإحصائيات'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(adminStatsProvider), child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  Widget _dashboard(BuildContext context, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('نظرة عامة', textAlign: TextAlign.right, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: AppSizes.p16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('إجمالي المستخدمين', stats['total_users'].toString(), Icons.people, AppColors.primary),
              _buildStatCard('إجمالي المحامين', stats['total_lawyers'].toString(), Icons.gavel, AppColors.secondaryDark),
              _buildStatCard('طلبات التوثيق', stats['pending_verifications'].toString(), Icons.verified_user, AppColors.teal),
              _buildStatCard('الحجوزات النشطة', stats['active_bookings'].toString(), Icons.calendar_today, AppColors.success),
            ],
          ),
          const SizedBox(height: AppSizes.p32),
          _buildRevenueCard((stats['total_revenue'] as num?)?.toDouble() ?? 0),
          const SizedBox(height: AppSizes.p32),
          const Text('إدارة النظام', textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: AppSizes.p16),
          _buildAdminActionCard('إدارة المستخدمين', 'البحث في الحسابات ومراجعة حالتها وبياناتها', Icons.people_alt_outlined, AppColors.primary, () => context.push('/admin/users')),
          _buildAdminActionCard('مركز جميع المراجعات', 'مكان موحد لكل الطلبات التي تحتاج قراراً إدارياً', Icons.fact_check_outlined, AppColors.primary, () => context.push('/admin/reviews')),
          _buildAdminActionCard('طلبات توثيق المحامين', 'الوصول المباشر لطلبات التوثيق المعلقة', Icons.verified_user_outlined, AppColors.secondaryDark, () => context.push('/admin/lawyer-verifications')),
          _buildAdminActionCard('الحجوزات الملغاة', 'مراجعة طلبات الإلغاء والغرامات والتعويضات', Icons.event_busy_outlined, AppColors.secondaryDark, () => context.push('/admin/cancellation-requests')),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .05), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.outline), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildRevenueCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text('إجمالي الإيرادات', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        Text('$amount د.ع', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('القيمة الإجمالية المسجلة في النظام', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildAdminActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: onTap,
        ),
      ),
    );
  }
}
