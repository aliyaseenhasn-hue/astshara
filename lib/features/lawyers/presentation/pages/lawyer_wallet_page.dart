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
  List<Map<String, dynamic>> payments = [];
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول');
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('id,wallet_number')
          .eq('auth_id', user.id)
          .maybeSingle();
      if (profile == null) throw Exception('ملف المحامي غير موجود');
      final lawyerId = profile['id'];

      wallet = await SupabaseConfig.client
          .from('lawyer_wallets')
          .select()
          .eq('lawyer_id', lawyerId)
          .maybeSingle();

      requests = List<Map<String, dynamic>>.from(
        await SupabaseConfig.client
            .from('lawyer_payout_requests')
            .select('id,amount,currency,status,wallet_number,created_at,processed_at,provider_reference,rejection_reason')
            .eq('lawyer_id', lawyerId)
            .order('created_at', ascending: false)
            .limit(50),
      );

      final bookingRows = await SupabaseConfig.client
          .from('bookings')
          .select('id,price,consultation_type,scheduled_at,user_id')
          .eq('lawyer_id', lawyerId)
          .order('created_at', ascending: false)
          .limit(100);
      final bookingIds = bookingRows.map((row) => row['id']).whereType<String>().toList();
      payments = [];
      if (bookingIds.isNotEmpty) {
        final rawPayments = List<Map<String, dynamic>>.from(
          await SupabaseConfig.client
              .from('payments')
              .select('id,booking_id,amount,payment_method,transaction_number,status,created_at,verified_at,qicard_payment_id,qicard_raw_status')
              .inFilter('booking_id', bookingIds)
              .order('created_at', ascending: false)
              .limit(100),
        );
        final paymentIds = rawPayments.map((p) => p['id']).whereType<String>().toList();
        final financials = paymentIds.isEmpty
            ? <Map<String, dynamic>>[]
            : List<Map<String, dynamic>>.from(
                await SupabaseConfig.client
                    .from('payment_financials')
                    .select('payment_id,gross_amount,commission_rate,platform_commission,penalty_amount,client_credit_amount,lawyer_net_amount,currency,status')
                    .inFilter('payment_id', paymentIds),
              );
        final financialByPayment = {for (final row in financials) '${row['payment_id']}': row};
        final bookingById = {for (final row in bookingRows) '${row['id']}': row};
        payments = rawPayments.map((payment) {
          return {
            ...payment,
            'booking': bookingById['${payment['booking_id']}'],
            'financial': financialByPayment['${payment['id']}'],
          };
        }).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _requestPayout() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طلب سحب'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'المبلغ بالدينار العراقي'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    if (mounted) setState(() => submitting = true);
    try {
      await SupabaseConfig.client.rpc('request_lawyer_payout', params: {'p_amount': amount});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب السحب إلى الإدارة')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', 'تعذر تنفيذ الطلب: '))),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String money(dynamic value) =>
      '${(num.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(0)} د.ع';

  String paymentStatus(String value) => {
        'pending': 'قيد الانتظار',
        'قيد معالجة الدفع': 'قيد معالجة الدفع',
        'تم الدفع': 'تم الدفع',
        'paid': 'تم الدفع',
        'failed': 'فشل الدفع',
        'فشل الدفع': 'فشل الدفع',
        'cancelled': 'ملغاة',
        'refunded': 'تم رد المبلغ',
        'تم استرداد المبلغ': 'تم رد المبلغ',
        'rejected': 'مرفوضة',
      }[value] ?? value;

  String financialStatus(String value) => {
        'pending': 'قيد التسوية',
        'settled': 'متاح ضمن الرصيد المستحق',
        'refunded': 'مسترد',
        'cancelled': 'ملغى',
      }[value] ?? value;

  String payoutStatus(String value) => {
        'pending_review': 'بانتظار مراجعة الإدارة',
        'approved': 'تمت الموافقة',
        'processing': 'قيد التحويل',
        'paid': 'تم التحويل',
        'rejected': 'مرفوض',
        'failed': 'فشل التحويل',
      }[value] ?? value;

  String _date(dynamic value) {
    if (value == null) return '—';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final w = wallet ?? <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: const Text('محفظتي المالية')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? ListView(children: const [SizedBox(height: 300), Center(child: CircularProgressIndicator())])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الرصيد المتاح للسحب', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(money(w['available_balance']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(child: _stat('قيد التسوية', money(w['pending_balance']))),
                            Expanded(child: _stat('إجمالي الأرباح', money(w['lifetime_earned']))),
                            Expanded(child: _stat('المسحوبات', money(w['lifetime_paid_out']))),
                          ]),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: submitting ? null : _requestPayout,
                              icon: submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.account_balance_wallet_outlined),
                              label: const Text('طلب سحب'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('سجل عمليات الدفع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('تظهر هنا جميع العمليات السابقة، بما فيها المعلقة والفاشلة والمكتملة.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  if (payments.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد عمليات دفع مسجلة حتى الآن.'))),
                  ...payments.map((p) {
                    final booking = p['booking'] as Map<String, dynamic>?;
                    final financial = p['financial'] as Map<String, dynamic>?;
                    final rawStatus = '${p['status'] ?? ''}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                        title: Text(money(p['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حالة الدفع: ${paymentStatus(rawStatus)}'),
                            if (financial != null) ...[
                              Text('عمولة المنصة: ${money(financial['platform_commission'])} (${financial['commission_rate'] ?? 0}%)'),
                              Text('الغرامة: ${money(financial['penalty_amount'])}'),
                              Text('صافي المحامي: ${money(financial['lawyer_net_amount'])}'),
                              Text('الحالة المالية: ${financialStatus('${financial['status']}')}'),
                            ],
                            if (booking?['consultation_type'] != null) Text('نوع الاستشارة: ${booking!['consultation_type']}'),
                            Text('التاريخ: ${_date(p['created_at'])}'),
                            if (p['transaction_number'] != null) Text('رقم العملية: ${p['transaction_number']}'),
                            if (p['qicard_payment_id'] != null) Text('Qi Card: ${p['qicard_payment_id']}'),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 22),
                  const Text('طلبات السحب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (requests.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب حتى الآن.'))),
                  ...requests.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
                        title: Text(money(r['amount'])),
                        subtitle: Text('${payoutStatus('${r['status']}')}\n${r['provider_reference'] ?? ''}'),
                        trailing: Text('${r['wallet_number'] ?? ''}'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stat(String title, String value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
