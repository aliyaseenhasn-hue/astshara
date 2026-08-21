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
                  Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('إعدادات المنصة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة العمولة للدفعات الجديدة (%)', suffixText: '%')),
                    const SizedBox(height: 10),
                    FilledButton(onPressed: _saveRate, child: const Text('حفظ النسبة')),
                  ])),),
                  const SizedBox(height: 22),
                  const Text('طلبات سحب المحامين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (payouts.isEmpty) Card(child: const Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات سحب.'))),
                  ...payouts.map((r) => Card(child: ListTile(
                    title: Text(money(r['amount'])),
                    subtitle: Text('${statusLabel('${r['status']}')} • ${r['wallet_number'] ?? ''}'),
                    trailing: r['status'] == 'pending_review'
                        ? PopupMenuButton<String>(
                            onSelected: (value) => _status(r, value),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'approved', child: Text('موافقة')),
                              const PopupMenuItem(value: 'processing', child: Text('بدء التحويل')),
                              const PopupMenuItem(value: 'paid', child: Text('تم التحويل')),
                              const PopupMenuItem(value: 'rejected', child: Text('رفض')),
                            ],
                          )
                        : Text(statusLabel('${r['status']}')),
                  ))),
                ],
              ),
      ),
    );
  }
}