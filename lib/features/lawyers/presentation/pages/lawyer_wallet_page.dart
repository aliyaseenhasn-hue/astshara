import 'package:flutter/material.dart';
import 'package:astshara/core/config/supabase_config.dart';

class LawyerWalletPage extends StatefulWidget {
  const LawyerWalletPage({super.key});
  @override
  State<LawyerWalletPage> createState() => _LawyerWalletPageState();
}

class _LawyerWalletPageState extends State<LawyerWalletPage> {
  Map<String, dynamic>? wallet;
  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  bool submitting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول');
      final profile = await SupabaseConfig.client.from('profiles').select('id,wallet_number').eq('auth_id', user.id).maybeSingle();
      if (profile == null) throw Exception('ملف المحامي غير موجود');
      wallet = await SupabaseConfig.client.from('lawyer_wallets').select().eq('lawyer_id', profile['id']).maybeSingle();
      requests = List<Map<String, dynamic>>.from(await SupabaseConfig.client.from('lawyer_payout_requests').select('id,amount,currency,status,wallet_number,created_at,processed_at').eq('lawyer_id', profile['id']).order('created_at', ascending: false).limit(20));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _requestPayout() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(context: context, builder: (context) => AlertDialog(
      title: const Text('طلب سحب'),
      content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ بالدينار العراقي')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: const Text('متابعة'))],
    ));
    controller.dispose();
    if (amount == null || amount <= 0) return;
    setState(() => submitting = true);
    try {
      await SupabaseConfig.client.rpc('request_lawyer_payout', params: {'p_amount': amount});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب السحب إلى الإدارة')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', 'تعذر تنفيذ الطلب: '))));
    } finally { if (mounted) setState(() => submitting = false); }
  }

  String money(dynamic value) => '${(num.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(0)} د.ع';
  String status(String value) => {'pending_review':'بانتظار مراجعة الإدارة','approved':'تمت الموافقة','processing':'قيد التنفيذ','paid':'تم التحويل','rejected':'مرفوض','failed':'فشل التحويل'}[value] ?? value;

  @override
  Widget build(BuildContext context) {
    final w = wallet ?? const {};
    return Scaffold(
      appBar: AppBar(title: const Text('محفظتي المالية')),
      body: RefreshIndicator(onRefresh: _load, child: loading ? const ListView(children: [SizedBox(height: 300), Center(child: CircularProgressIndicator())]) : ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الرصيد المتاح', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6), Text(money(w['available_balance']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18), Row(children: [Expanded(child: _stat('معلق', money(w['pending_balance']))), Expanded(child: _stat('إجمالي الأرباح', money(w['lifetime_earned']))), Expanded(child: _stat('المسحوبات', money(w['lifetime_paid_out'])))]),
          const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: submitting ? null : _requestPayout, icon: submitting ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.account_balance_wallet_outlined), label: const Text('طلب سحب'))),
        ]))),
        const SizedBox(height: 22), const Text('طلبات السحب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), if (requests.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب حتى الآن.'))),
        ...requests.map((r) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.payments_outlined)), title: Text(money(r['amount'])), subtitle: Text(status('${r['status']}')), trailing: Text('${r['wallet_number']}')))),
      ])),
    );
  }

  Widget _stat(String title, String value) => Padding(padding: const EdgeInsets.only(right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}
