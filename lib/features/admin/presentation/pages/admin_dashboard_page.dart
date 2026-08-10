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
        elevation: 0,
        actions: [
          IconButton(onPressed: () => ref.read(adminStatsProvider.notifier).refresh(), icon: const Icon(Icons.refresh), tooltip: 'تحديث البيانات'),
          IconButton(onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48), const SizedBox(height: 16), Text('تعذر تحميل الإحصائيات: $err'),
          ElevatedButton(onPressed: () => ref.invalidate(adminStatsProvider), child: const Text('إعادة المحاولة')),
        ])),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('نظرة عامة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSizes.p16),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4, children: [
              _buildStatCard('إجمالي المستخدمين', stats['total_users'].toString(), Icons.people, Colors.blue),
              _buildStatCard('إجمالي المحامين', stats['total_lawyers'].toString(), Icons.gavel, Colors.orange),
              _buildStatCard('طلبات توثيق', stats['pending_verifications'].toString(), Icons.verified_user, Colors.purple),
              _buildStatCard('حجوزات نشطة', stats['active_bookings'].toString(), Icons.calendar_today, Colors.green),
            ]),
            const SizedBox(height: AppSizes.p32),
            _buildRevenueCard((stats['total_revenue'] as num?)?.toDouble() ?? 0),
            const SizedBox(height: AppSizes.p32),
            const Text('إجراءات الإدارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.p16),
            _buildAdminActionCard('مراقبة الدفعات', '${stats['pending_payments']} دفعات قيد التحقق الآلي', Icons.monitor_heart_outlined, AppColors.primary, () => context.push('/admin/payments')),
            _buildAdminActionCard('طلبات تغيير التخصص', 'مراجعة التخصصات وهوية النقابة', Icons.badge_outlined, AppColors.secondary, () => context.push('/admin/specialization-change-requests')),
            _buildAdminActionCard('طلبات انضمام المحامين', '${stats['pending_verifications']} طلبات مراجعة', Icons.person_add, Colors.amber, () => context.push('/admin/lawyer-verifications')),
            _buildAdminActionCard('إدارة جميع المستخدمين', 'تعديل أو حظر حسابات', Icons.manage_accounts, AppColors.primary, () {}),
            _buildAdminActionCard('إحصائيات التقارير', 'بلاغات وتحليلات', Icons.bar_chart, Colors.teal, () {}),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withValues(alpha: .1), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), Text(title, style: const TextStyle(fontSize: 12, color: AppColors.outline), textAlign: TextAlign.center)]),
  );

  Widget _buildRevenueCard(double amount) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.textSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.all(Radius.circular(20))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('إجمالي الأرباح المجمعة', style: TextStyle(color: Colors.white70, fontSize: 14)), Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20)]),
      const SizedBox(height: 12), Text('$amount د.ع', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('تحديث فوري للقيمة الإجمالية', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]),
  );

  Widget _buildAdminActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => _InteractiveAdminCard(title: title, subtitle: subtitle, icon: icon, color: color, onTap: onTap);
}

class _InteractiveAdminCard extends StatefulWidget {
  final String title; final String subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _InteractiveAdminCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  @override State<_InteractiveAdminCard> createState() => _InteractiveAdminCardState();
}

class _InteractiveAdminCardState extends State<_InteractiveAdminCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: _hovered ? [BoxShadow(color: widget.color.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 7))] : const []),
          child: Card(child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _hovered ? widget.color.withValues(alpha: .15) : widget.color.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Icon(widget.icon, color: widget.color)),
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: AnimatedSlide(duration: const Duration(milliseconds: 180), offset: Offset(_hovered ? -0.12 : 0, 0), child: const Icon(Icons.arrow_forward_ios, size: 14)),
            onTap: widget.onTap,
          )),
        ),
      ),
    ),
  );
}
