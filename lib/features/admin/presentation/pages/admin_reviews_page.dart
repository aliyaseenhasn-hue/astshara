import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});
  @override State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  late Future<Map<String, int>> _future;
  @override void initState() { super.initState(); _future = _counts(); }
  Future<Map<String, int>> _counts() async {
    final c = SupabaseConfig.client;
    final results = await Future.wait([
      c.from('lawyer_profiles').select('id').eq('verified', false),
      c.from('cancellation_requests').select('id').eq('status', 'بانتظار مراجعة الإدارة'),
      c.from('specialization_change_requests').select('id').eq('status', 'pending'),
      c.from('payments').select('id').eq('status', 'pending'),
    ]);
    return {'verifications': (results[0] as List).length, 'cancellations': (results[1] as List).length, 'specializations': (results[2] as List).length, 'payments': (results[3] as List).length};
  }
  void _refresh() => setState(() => _future = _counts());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('جميع المراجعات'), backgroundColor: AppColors.primary, foregroundColor: Colors.white, actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]),
    body: FutureBuilder<Map<String, int>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('تعذر تحميل المراجعات: ${snapshot.error}'));
      final c = snapshot.data!;
      final items = [
        ('طلبات توثيق المحامين', 'مراجعة واعتماد بيانات المحامين', Icons.verified_user_outlined, c['verifications']!, '/admin/lawyer-verifications'),
        ('طلبات إلغاء الحجوزات', 'مراجعة الإلغاء والغرامات والتعويضات', Icons.event_busy_outlined, c['cancellations']!, '/admin/cancellation-requests'),
        ('طلبات تغيير التخصص', 'مراجعة طلبات تغيير التخصص والوثائق', Icons.badge_outlined, c['specializations']!, '/admin/specialization-change-requests'),
        ('مراجعة الدفعات', 'مراجعة الدفعات المعلقة والتحقق منها', Icons.payments_outlined, c['payments']!, '/admin/payments'),
      ];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('المراجعات التي تتطلب إجراءً إدارياً', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('تجمع هذه الصفحة جميع العمليات التي تحتاج إلى قرار من الإدارة.'), const SizedBox(height: 20),
        ...items.map((item) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.all(14), leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), child: Icon(item.$3, color: AppColors.primary)), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(item.$2), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (item.$4 > 0) Chip(label: Text('${item.$4}')), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 15)]), onTap: () => context.push(item.$5))),
      ]);
    }),
  );
}
