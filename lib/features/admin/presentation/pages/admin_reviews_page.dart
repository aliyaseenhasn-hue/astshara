import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  late Future<Map<String, int>> _future;

  @override
  void initState() {
    super.initState();
    _future = _counts();
  }

  Future<Map<String, int>> _counts() async {
    final c = SupabaseConfig.client;
    final results = await Future.wait([
      c.from('lawyer_profiles').select('id').eq('verified', false),
      c.from('cancellation_requests').select('id').eq('status', 'بانتظار مراجعة الإدارة'),
      c.from('specialization_change_requests').select('id').eq('status', 'pending'),
      c.from('payments').select('id').eq('status', 'pending'),
      c.rpc('admin_list_no_show_reviews'),
    ]);
    final noShowRows = List<Map<String, dynamic>>.from(results[4] as List);
    return {
      'verifications': (results[0] as List).length,
      'cancellations': (results[1] as List).length,
      'specializations': (results[2] as List).length,
      'payments': (results[3] as List).length,
      'noShow': noShowRows.where((row) => row['status'] == 'pending').length,
    };
  }

  void _refresh() => setState(() => _future = _counts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع المراجعات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المراجعات: ${snapshot.error}'));
          final counts = snapshot.data ?? const <String, int>{};
          final items = <({String title, String subtitle, IconData icon, int count, String route})>[
            (title: 'طلبات توثيق المحامين', subtitle: 'مراجعة واعتماد بيانات المحامين', icon: Icons.verified_user_outlined, count: counts['verifications'] ?? 0, route: '/admin/lawyer-verifications'),
            (title: 'طلبات إلغاء الحجوزات', subtitle: 'مراجعة الإلغاء والغرامات والتعويضات', icon: Icons.event_busy_outlined, count: counts['cancellations'] ?? 0, route: '/admin/cancellation-requests'),
            (title: 'طلبات تغيير التخصص', subtitle: 'مراجعة طلبات تغيير التخصص والوثائق', icon: Icons.badge_outlined, count: counts['specializations'] ?? 0, route: '/admin/specialization-change-requests'),
            (title: 'مراجعة الدفعات', subtitle: 'مراجعة الدفعات المعلقة والتحقق منها', icon: Icons.payments_outlined, count: counts['payments'] ?? 0, route: '/admin/payments'),
            (title: 'مراجعة عدم الحضور', subtitle: 'التحقق من بلاغات عدم حضور الاستشارة واتخاذ القرار', icon: Icons.person_off_outlined, count: counts['noShow'] ?? 0, route: '/admin/no-show-reviews'),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('المراجعات التي تتطلب إجراءً إدارياً', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('تجمع هذه الصفحة جميع العمليات التي تحتاج إلى قرار من الإدارة.'),
              const SizedBox(height: 20),
              ...items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), child: Icon(item.icon, color: AppColors.primary)),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.subtitle),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (item.count > 0) Chip(label: Text('${item.count}')), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 15)]),
                      onTap: () => context.push(item.route),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
