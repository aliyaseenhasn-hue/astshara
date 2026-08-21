import 'package:flutter/material.dart';
import 'package:astshara/core/config/supabase_config.dart';

class FinancialManagementPage extends StatefulWidget {
  const FinancialManagementPage({super.key});
  @override
  State<FinancialManagementPage> createState() => _FinancialManagementPageState();
}

class _FinancialManagementPageState extends State<FinancialManagementPage> {
  Map<String, dynamic>? settings;
  List<Map<String, dynamic>> payouts = [];
  bool loading = true;
  final rateController = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { rateController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      settings = await SupabaseConfig.client.from('platform_financial_settings').select().eq('id', true).single();
      rateController.text = '${settings?['commission_rate'] ?? 0}';
      payouts = List<Map<String, dynamic>>.from(await SupabaseConfig.client.from('lawyer_payout_requests').select('id,lawyer_id,amount,currency,status,wallet_number,created_at').order('created_at', ascending: false).limit(50));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل البيانات: $e')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _saveRate() async {
    final rate = double.tryParse(rateController.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل نسبة بين 0 و100')));
      return;
    }
    try {
      await SupabaseConfig.client.rpc('admin_set_commission_rate', params: {'p_rate': rate});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ نسبة العمولة للدفعات الجديدة')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    }
  }

  Future<void> _status(Map<String, dynamic> row, String status) async {
    try {
      await SupabaseConfig.client.rpc('admin_complete_payout', params: {'p_payout_id': row['id'], 'p_status': status});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الطلب: $e')));
    }
  }

  String money(dynamic x) => '${(num.tryParse('${x ?? 0}') ?? 0).toStringAsFixed(0)} د.ع';
  String statusLabel(String s) => {'pending_review':'بانتظار المراجعة','approved':'تمت الموافقة','processing':'قيد التنفيذ','paid':'تم التحويل','rejected':'مرفوض','failed':'فشل'}[s] ?? s;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة المالية')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const ListView(children: [SizedBox(height: 300), Center(child: CircularProgressIndicator())])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إعدادات المنصة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(controller: rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة العمولة للدفعات الجديدة (%)', suffixText: '%')),
                          const SizedBox(height: 10),
                          FilledButton(onPressed: _saveRate, child: const Text('حفظ النسبة')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('طلبات سحب المحامين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (payouts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب.'))),
                  ...payouts.map((r) => Card(
                    child: ListTile(
                      title: Text(money(r['amount'])),
                      subtitle: Text('${statusLabel('${r['status']}')} • ${r['wallet_number'] ?? ''}'),
                      trailing: r['status'] == 'pending_review'
                          ? PopupMenuButton<String>(
                              onSelected: (value) => _status(r, value),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'approved', child: Text('موافقة')),
                                PopupMenuItem(value: 'processing', child: Text('بدء التحويل')),
                                PopupMenuItem(value: 'paid', child: Text('تم التحويل')),
                                PopupMenuItem(value: 'rejected', child: Text('رفض')),
                              ],
                            )
                          : Text(statusLabel('${r['status']}')),
                    ),
                  )),
                ],
              ),
      ),
    );
  }
}
