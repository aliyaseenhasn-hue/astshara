import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoShowReviewsPage extends StatefulWidget {
  const NoShowReviewsPage({super.key});
  @override
  State<NoShowReviewsPage> createState() => _NoShowReviewsPageState();
}

class _NoShowReviewsPageState extends State<NoShowReviewsPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _supabase.rpc('admin_list_no_show_reviews');
      _items = List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل مراجعات عدم الحضور: $e')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _review(Map<String, dynamic> item, String decision) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: Text(decision == 'approved' ? 'تأكيد عدم الحضور' : 'رفض البلاغ'),
      content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(labelText: 'ملاحظة الإدارة (اختياري)')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تأكيد'))],
    ));
    if (note == null) return;
    try {
      await _supabase.rpc('admin_review_no_show_request', params: {'p_request_id': item['id'], 'p_decision': decision, 'p_note': note.isEmpty ? null : note});
      await _load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ القرار: $e'))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مراجعة عدم الحضور'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty ? const ListView(children: [SizedBox(height: 180), Center(child: Text('لا توجد طلبات عدم حضور'))]) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: _items.length,
        itemBuilder: (_, i) { final x = _items[i]; final pending = x['status'] == 'pending'; return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pending ? 'قيد المراجعة' : (x['status'] == 'approved' ? 'تمت الموافقة' : 'تم الرفض'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('رقم الحجز: ${x['booking_id']}'), Text('سبب البلاغ: ${x['reason']}'), if ((x['evidence_url'] ?? '').toString().isNotEmpty) Text('يوجد دليل مرفق'),
          if (pending) Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => _review(x, 'rejected'), child: const Text('رفض')), const SizedBox(width: 8), ElevatedButton(onPressed: () => _review(x, 'approved'), child: const Text('موافقة'))])
        ]))); },
      ),
    ),
  );
}
