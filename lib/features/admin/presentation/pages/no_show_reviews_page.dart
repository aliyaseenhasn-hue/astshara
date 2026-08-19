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
  bool _pendingOnly = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _supabase.rpc('admin_list_no_show_reviews');
      final rows = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => _items = rows);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحميل مراجعات عدم الحضور. حاول مرة أخرى.')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _review(Map<String, dynamic> item, String decision) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(decision == 'approved' ? 'تأكيد عدم الحضور' : 'رفض البلاغ'),
        content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(labelText: 'ملاحظة الإدارة (اختياري)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تأكيد')),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    try {
      await _supabase.rpc('admin_review_no_show_request', params: {
        'p_request_id': item['id'],
        'p_decision': decision,
        'p_note': note.isEmpty ? null : note,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decision == 'approved' ? 'تمت الموافقة على البلاغ' : 'تم رفض البلاغ')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ القرار. حاول مرة أخرى.')));
    }
  }

  String _statusLabel(dynamic status) {
    switch (status?.toString()) {
      case 'pending': return 'قيد المراجعة';
      case 'approved': return 'تمت الموافقة';
      case 'rejected': return 'تم الرفض';
      default: return status?.toString() ?? 'غير محدد';
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'غير محدد';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)} - ${two(date.hour)}:${two(date.minute)}';
  }

  String _shortId(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length <= 12) return text;
    return '${text.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _pendingOnly ? _items.where((e) => e['status'] == 'pending').toList() : _items;
    final pendingCount = _items.where((e) => e['status'] == 'pending').length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة عدم الحضور'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(child: ListTile(leading: const Icon(Icons.fact_check_outlined), title: const Text('طلبات عدم الحضور'), subtitle: Text('${_items.length} طلباً إجمالاً'), trailing: Chip(label: Text('معلق: $pendingCount')))),
                    const SizedBox(height: 8),
                    SwitchListTile(value: _pendingOnly, onChanged: (v) => setState(() => _pendingOnly = v), title: const Text('عرض الطلبات المعلقة فقط')),
                    const SizedBox(height: 8),
                    if (visible.isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('لا توجد طلبات في الحالة المحددة')))
                    else
                      ...visible.map((item) {
                        final pending = item['status'] == 'pending';
                        final reason = item['reason']?.toString() ?? 'غير محدد';
                        final evidence = item['evidence_url']?.toString() ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(_statusLabel(item['status']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text(reason))]),
                              const Divider(),
                              Text('رقم الحجز: ${_shortId(item['booking_id'])}'),
                              if (item['created_at'] != null) Text('تاريخ البلاغ: ${_formatDate(item['created_at'])}'),
                              if (item['reported_by'] != null) Text('مقدم البلاغ: ${_shortId(item['reported_by'])}'),
                              if (evidence.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('يوجد دليل مرفق', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(evidence, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                              if (item['review_note'] != null && item['review_note'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('ملاحظة الإدارة: ${item['review_note']}'),
                              ],
                              if (pending) ...[
                                const SizedBox(height: 12),
                                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                  OutlinedButton(onPressed: () => _review(item, 'rejected'), child: const Text('رفض')),
                                  const SizedBox(width: 8),
                                  ElevatedButton(onPressed: () => _review(item, 'approved'), child: const Text('موافقة')),
                                ]),
                              ],
                            ]),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
