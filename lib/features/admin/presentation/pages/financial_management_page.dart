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
  bool processing = false;
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
      rateController.text = '${settings?['commission_rate'] ?? 0}';

      payouts = List<Map<String, dynamic>>.from(
        await SupabaseConfig.client
            .from('lawyer_payout_requests')
            .select(
              'id,lawyer_id,amount,currency,status,wallet_type,wallet_number,'
              'wallet_holder_name,created_at,rejection_reason,provider_reference',
            )
            .order('created_at', ascending: false)
            .limit(50),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل البيانات: ${_errorText(e)}')),
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
      await SupabaseConfig.client.rpc(
        'admin_set_commission_rate',
        params: {'p_rate': rate},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ نسبة العمولة للدفعات الجديدة')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: ${_errorText(e)}')),
        );
      }
    }
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض طلب السحب'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض',
            hintText: 'اكتب سبب رفض طلب السحب',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('رفض الطلب'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _askProviderReference() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد التحويل'),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'رقم مرجع التحويل (اختياري)',
            hintText: 'مثال: رقم العملية في تطبيق Qi Card',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('تم التحويل'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _markPaid(Map<String, dynamic> row) async {
    final reference = await _askProviderReference();
    if (!mounted || reference == null) return;

    setState(() => processing = true);
    try {
      await SupabaseConfig.client.rpc(
        'admin_complete_payout',
        params: {
          'p_payout_id': row['id'],
          'p_status': 'paid',
          'p_provider_reference': reference.isEmpty ? null : reference,
          'p_rejection_reason': null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل التحويل وتحديث مستحقات المحامي')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل التحويل: ${_errorText(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final reason = await _askRejectionReason();
    if (!mounted || reason == null) return;

    setState(() => processing = true);
    try {
      await SupabaseConfig.client.rpc(
        'admin_complete_payout',
        params: {
          'p_payout_id': row['id'],
          'p_status': 'rejected',
          'p_provider_reference': null,
          'p_rejection_reason': reason,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض الطلب وإعادة المبلغ إلى الرصيد المتاح')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر رفض الطلب: ${_errorText(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  String money(dynamic value) =>
      '${(num.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(0)} د.ع';

  String statusLabel(String status) => {
        'pending_review': 'بانتظار التحويل اليدوي',
        'approved': 'تمت الموافقة',
        'processing': 'قيد التنفيذ',
        'paid': 'تم التحويل',
        'rejected': 'مرفوض',
        'failed': 'فشل التحويل',
      }[status] ?? status;

  String walletLabel(String? type) => {
        'zain_cash': 'زين كاش',
        'asia_hawala': 'آسيا حوالة',
        'qi_card': 'Qi Card',
      }[type] ?? type ?? '—';

  String date(dynamic value) {
    final parsed = DateTime.tryParse('${value ?? ''}');
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final pending = payouts.where((row) => row['status'] == 'pending_review').length;

    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة المالية')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات المنصة',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'نسبة العمولة للدفعات الجديدة (%)',
                              suffixText: '%',
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: _saveRate,
                            child: const Text('حفظ النسبة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: const Text('نظام السحب اليدوي'),
                      subtitle: Text(
                        'طلبات بانتظار التحويل: $pending\n'
                        'يتم التحويل فعلياً خارج التطبيق ثم الضغط على «تم التحويل».',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'طلبات سحب المحامين',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (payouts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد طلبات سحب.'),
                      ),
                    ),
                  ...payouts.map(
                    (row) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    money(row['amount']),
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Chip(label: Text(statusLabel('${row['status']}'))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('الوسيلة: ${walletLabel(row['wallet_type']?.toString())}'),
                            Text('رقم الاستلام: ${row['wallet_number'] ?? '—'}'),
                            Text('اسم صاحب الوسيلة: ${row['wallet_holder_name'] ?? '—'}'),
                            Text('تاريخ الطلب: ${date(row['created_at'])}'),
                            if (row['provider_reference'] != null)
                              Text('مرجع التحويل: ${row['provider_reference']}'),
                            if (row['rejection_reason'] != null)
                              Text('سبب الرفض: ${row['rejection_reason']}'),
                            if (row['status'] == 'pending_review') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: processing ? null : () => _reject(row),
                                      icon: const Icon(Icons.close),
                                      label: const Text('رفض وإعادة الرصيد'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: processing ? null : () => _markPaid(row),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('تم التحويل'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
