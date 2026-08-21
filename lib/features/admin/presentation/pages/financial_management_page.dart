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
  List<Map<String, dynamic>> financials = [];
  bool loading = true;
  final rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    rateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      settings = await SupabaseConfig.client
          .from('platform_financial_settings')
          .select()
          .eq('id', true)
          .single();
      rateController.text = '${settings?['commission_rate'] ?? 10}';
      payouts = List<Map<String, dynamic>>.from(
        await SupabaseConfig.client
            .from('lawyer_payout_requests')
            .select('id,lawyer_id,amount,currency,status,wallet_number,created_at,processed_at,provider_reference,rejection_reason')
            .order('created_at', ascending: false)
            .limit(100),
      );
      financials = List<Map<String, dynamic>>.from(
        await SupabaseConfig.client
            .from('payment_financials')
            .select('payment_id,booking_id,gross_amount,commission_rate,platform_commission,penalty_amount,client_credit_amount,lawyer_net_amount,currency,status,created_at,updated_at')
            .order('created_at', ascending: false)
            .limit(200),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveRate() async {
    final rate = double.tryParse(rateController.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل نسبة بين 0 و100')),
      );
      return;
    }
    try {
      await SupabaseConfig.client.rpc('admin_set_commission_rate', params: {'p_rate': rate});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ نسبة العمولة للدفعات الجديدة')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    }
  }

  Future<void> _status(Map<String, dynamic> row, String status) async {
    String? reference;
    String? reason;
    if (status == 'processing' || status == 'paid') {
      final controller = TextEditingController(text: '${row['provider_reference'] ?? ''}');
      reference = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'paid' ? 'تأكيد التحويل' : 'بدء التحويل'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'مرجع التحويل (اختياري)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تأكيد')),
          ],
        ),
      );
      controller.dispose();
      if (reference == null) return;
    } else if (status == 'rejected' || status == 'failed') {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'rejected' ? 'رفض طلب السحب' : 'فشل التحويل'),
          content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'السبب')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تأكيد')),
          ],
        ),
      );
      controller.dispose();
      if (reason == null) return;
    }
    try {
      await SupabaseConfig.client.rpc(
        'admin_complete_payout',
        params: {
          'p_payout_id': row['id'],
          'p_status': status,
          'p_provider_reference': reference,
          'p_rejection_reason': reason,
        },
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الطلب: $e')));
    }
  }

  String money(dynamic value) => '${(num.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(0)} د.ع';

  String statusLabel(String status) => {
        'pending_review': 'بانتظار المراجعة',
        'approved': 'تمت الموافقة',
        'processing': 'قيد التحويل',
        'paid': 'تم التحويل',
        'rejected': 'مرفوض',
        'failed': 'فشل التحويل',
      }[status] ?? status;

  String financialStatus(String status) => {
        'pending': 'قيد التسوية',
        'settled': 'تمت التسوية',
        'refunded': 'مسترد',
        'cancelled': 'ملغى',
      }[status] ?? status;

  num _sum(String key, {String? status}) {
    return financials
        .where((r) => status == null || '${r['status']}' == status)
        .fold<num>(0, (sum, r) => sum + (num.tryParse('${r[key] ?? 0}') ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة المالية')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? ListView(children: const [SizedBox(height: 300), Center(child: CircularProgressIndicator())])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ملخص الدورة المالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _metric('إجمالي المدفوعات', money(_sum('gross_amount'))),
                              _metric('عمولة المنصة', money(_sum('platform_commission'))),
                              _metric('مستحقات المحامين', money(_sum('lawyer_net_amount'))),
                              _metric('قيد التسوية', money(_sum('lawyer_net_amount', status: 'pending'))),
                              _metric('تمت التسوية', money(_sum('lawyer_net_amount', status: 'settled'))),
                              _metric('الغرامات', money(_sum('penalty_amount'))),
                              _metric('تعويضات العملاء', money(_sum('client_credit_amount'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إعدادات المنصة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'نسبة العمولة للدفعات الجديدة (%)', suffixText: '%'),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(onPressed: _saveRate, child: const Text('حفظ النسبة')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('آخر السجلات المالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (financials.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد سجلات مالية.'))),
                  ...financials.take(50).map(
                    (row) => Card(
                      child: ListTile(
                        title: Text('الإجمالي: ${money(row['gross_amount'])}'),
                        subtitle: Text('عمولة: ${money(row['platform_commission'])} • المحامي: ${money(row['lawyer_net_amount'])}\nالحالة: ${financialStatus('${row['status']}')}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('طلبات سحب المحامين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (payouts.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب.'))),
                  ...payouts.map(
                    (row) => Card(
                      child: ListTile(
                        title: Text(money(row['amount'])),
                        subtitle: Text('${statusLabel('${row['status']}')} • ${row['wallet_number'] ?? ''}\nمرجع: ${row['provider_reference'] ?? '—'}${row['rejection_reason'] == null ? '' : '\nالسبب: ${row['rejection_reason']}'}'),
                        trailing: row['status'] == 'pending_review'
                            ? PopupMenuButton<String>(
                                onSelected: (value) => _status(row, value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'approved', child: Text('موافقة')),
                                  PopupMenuItem(value: 'processing', child: Text('بدء التحويل')),
                                  PopupMenuItem(value: 'paid', child: Text('تم التحويل')),
                                  PopupMenuItem(value: 'rejected', child: Text('رفض')),
                                ],
                              )
                            : row['status'] == 'approved'
                                ? PopupMenuButton<String>(
                                    onSelected: (value) => _status(row, value),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'processing', child: Text('بدء التحويل')),
                                      PopupMenuItem(value: 'rejected', child: Text('رفض')),
                                    ],
                                  )
                                : row['status'] == 'processing'
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) => _status(row, value),
                                        itemBuilder: (_) => const [PopupMenuItem(value: 'paid', child: Text('تأكيد تم التحويل')), PopupMenuItem(value: 'failed', child: Text('فشل التحويل'))],
                                      )
                                    : Text(statusLabel('${row['status']}')),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _metric(String title, String value) => Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
      );
}
