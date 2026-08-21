import 'package:flutter/material.dart';
import 'package:astshara/core/config/supabase_config.dart';

class LawyerWalletPage extends StatefulWidget {
  const LawyerWalletPage({super.key});
  @override
  State<LawyerWalletPage> createState() => _LawyerWalletPageState();
}

class _LawyerWalletPageState extends State<LawyerWalletPage> {
  Map<String, dynamic>? wallet;
  String? walletNumber;
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> payments = [];
  bool loading = true;
  bool submitting = false;
  bool savingWallet = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول');
      final profile = await SupabaseConfig.client.from('profiles').select('id,wallet_number').eq('auth_id', user.id).maybeSingle();
      if (profile == null) throw Exception('ملف المحامي غير موجود');
      final lawyerId = profile['id'];
      walletNumber = profile['wallet_number']?.toString().trim();
      if (walletNumber?.isEmpty == true) walletNumber = null;
      wallet = await SupabaseConfig.client.from('lawyer_wallets').select().eq('lawyer_id', lawyerId).maybeSingle();
      requests = List<Map<String, dynamic>>.from(await SupabaseConfig.client.from('lawyer_payout_requests').select('id,amount,currency,status,wallet_number,created_at,processed_at,rejection_reason,provider_reference,completed_at').eq('lawyer_id', lawyerId).order('created_at', ascending: false).limit(20));

      final bookingRows = await SupabaseConfig.client
          .from('bookings')
          .select('id,price,consultation_type,scheduled_at,user_id')
          .eq('lawyer_id', lawyerId)
          .order('created_at', ascending: false)
          .limit(100);
      final bookingIds = bookingRows.map((row) => row['id']).whereType<String>().toList();
      payments = [];
      if (bookingIds.isNotEmpty) {
        payments = List<Map<String, dynamic>>.from(await SupabaseConfig.client
            .from('payments')
            .select('id,booking_id,amount,payment_method,transaction_number,status,created_at,verified_at,qicard_payment_id,qicard_raw_status')
            .inFilter('booking_id', bookingIds)
            .order('created_at', ascending: false)
            .limit(100));
        final bookingById = {for (final row in bookingRows) '${row['id']}': row};
        payments = payments.map((payment) {
          final booking = bookingById['${payment['booking_id']}'];
          return {...payment, 'booking': booking};
        }).toList();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _editWalletNumber() async {
    final controller = TextEditingController(text: walletNumber ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رقم محفظة الاستلام'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'رقم المحفظة', hintText: 'مثال: 07xxxxxxxxx', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    if (value.length < 5 || value.length > 32) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم المحفظة غير صالح')));
      return;
    }
    setState(() => savingWallet = true);
    try {
      await SupabaseConfig.client.rpc('update_own_lawyer_wallet_number', params: {'p_wallet_number': value});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ رقم المحفظة')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ رقم المحفظة: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally { if (mounted) setState(() => savingWallet = false); }
  }

  Future<void> _requestPayout() async {
    if (walletNumber == null || walletNumber!.isEmpty) {
      await _editWalletNumber();
      if (walletNumber == null || walletNumber!.isEmpty) return;
    }
    final available = num.tryParse('${wallet?['available_balance'] ?? 0}') ?? 0;
    if (available <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رصيد متاح للسحب حالياً')));
      return;
    }
    final controller = TextEditingController();
    final amount = await showDialog<double>(context: context, builder: (context) => AlertDialog(
      title: const Text('طلب سحب'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('المتاح للسحب: ${money(available)}'),
        const SizedBox(height: 12),
        TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ بالدينار العراقي')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: const Text('إرسال الطلب'))],
    ));
    controller.dispose();
    if (amount == null || amount <= 0) return;
    if (amount > available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المبلغ المطلوب أكبر من الرصيد المتاح')));
      return;
    }
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
  String paymentStatus(String value) => {
    'pending': 'قيد الانتظار', 'قيد معالجة الدفع': 'قيد معالجة الدفع', 'تم الدفع': 'تم الدفع', 'paid': 'تم الدفع',
    'failed': 'فشل الدفع', 'فشل الدفع': 'فشل الدفع', 'cancelled': 'ملغاة', 'refunded': 'تم رد المبلغ', 'rejected': 'مرفوضة',
  }[value] ?? value;
  String payoutStatus(String value) => {'pending_review':'بانتظار مراجعة الإدارة','approved':'تمت الموافقة','processing':'قيد التنفيذ','paid':'تم التحويل','rejected':'مرفوض','failed':'فشل التحويل'}[value] ?? value;

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
                  Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('الرصيد المتاح', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(money(w['available_balance']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    Row(children: [Expanded(child: _stat('معلق', money(w['pending_balance']))), Expanded(child: _stat('إجمالي الأرباح', money(w['lifetime_earned']))), Expanded(child: _stat('المسحوبات', money(w['lifetime_paid_out'])))]),
                    const SizedBox(height: 18),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: submitting ? null : _requestPayout, icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.account_balance_wallet_outlined), label: const Text('طلب سحب'))),
                  ]))),
                  const SizedBox(height: 16),
                  Card(child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
                    title: const Text('محفظة الاستلام', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(walletNumber == null ? 'لم تتم إضافة رقم محفظة الاستلام بعد' : 'رقم المحفظة: $walletNumber'),
                    trailing: savingWallet ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(tooltip: 'تعديل رقم المحفظة', onPressed: _editWalletNumber, icon: const Icon(Icons.edit_outlined)),
                  )),
                  const SizedBox(height: 22),
                  const Text('سجل عمليات الدفع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('جميع عمليات الدفع المرتبطة باستشاراتك، مهما كانت حالتها.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  if (payments.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد عمليات دفع مسجلة حتى الآن.'))),
                  ...payments.map((p) {
                    final booking = p['booking'] as Map<String, dynamic>?;
                    final rawStatus = '${p['status'] ?? ''}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                        title: Text(money(p['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('الحالة: ${paymentStatus(rawStatus)}'),
                          if (booking?['consultation_type'] != null) Text('نوع الاستشارة: ${booking!['consultation_type']}'),
                          Text('التاريخ: ${_date(p['created_at'])}'),
                          if (p['transaction_number'] != null) Text('رقم العملية: ${p['transaction_number']}'),
                          if (p['qicard_payment_id'] != null) Text('Qi Card: ${p['qicard_payment_id']}'),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 22),
                  const Text('طلبات السحب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (requests.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب حتى الآن.'))),
                  ...requests.map((r) => Card(child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
                    title: Text(money(r['amount'])),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(payoutStatus('${r['status']}')),
                      Text('التاريخ: ${_date(r['created_at'])}'),
                      if (r['rejection_reason'] != null) Text('السبب: ${r['rejection_reason']}'),
                      if (r['provider_reference'] != null) Text('مرجع التحويل: ${r['provider_reference']}'),
                    ]),
                    trailing: Text('${r['wallet_number'] ?? ''}'),
                  ))),
                ],
              ),
      ),
    );
  }

  Widget _stat(String title, String value) => Padding(padding: const EdgeInsets.only(right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}
