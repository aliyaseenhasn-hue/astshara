import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookings_provider.dart';
import '../../domain/entities/booking.dart';

class ManualPaymentPage extends ConsumerStatefulWidget {
  final Booking booking;
  const ManualPaymentPage({super.key, required this.booking});
  @override
  ConsumerState<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends ConsumerState<ManualPaymentPage> {
  final _amount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _amount.dispose(); super.dispose(); }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغاً صحيحاً أكبر من صفر.')));
      return;
    }
    if (amount != widget.booking.price) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('تأكيد المبلغ'), content: Text('المبلغ المدخل ${_formatAmount(amount)} د.ع يختلف عن رسوم الحجز ${_formatAmount(widget.booking.price)} د.ع. هل تريد المتابعة؟'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تعديل')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد'))])) ?? false;
      if (!confirmed || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ref.read(bookingsControllerProvider.notifier).recordManualPayment(bookingId: widget.booking.id, amount: amount);
      if (!mounted) return;
      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(bookingsControllerProvider).error?.toString() ?? 'تعذر تسجيل الدفع')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل المبلغ المستلم وتأكيد الدفع.')));
      Navigator.pop(context, updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatAmount(num value) => value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('تسجيل الدفع اليدوي')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 36), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(24)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.account_balance_wallet_rounded, color: scheme.primary, size: 28)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تأكيد الدفع في المكتب', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)), const SizedBox(height: 6), Text('سجّل المبلغ الذي استلمته فعلياً من العميل قبل بدء الاستشارة.', style: TextStyle(color: scheme.onPrimaryContainer, height: 1.45))]))]),
        const SizedBox(height: 18),
        Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ملخص الحجز', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface)), const SizedBox(height: 16), _row(context, 'رقم الحجز', widget.booking.id.length >= 8 ? '#${widget.booking.id.substring(0, 8)}' : '#${widget.booking.id}'), _row(context, 'رسوم الاستشارة', '${_formatAmount(widget.booking.price)} د.ع'), _row(context, 'حالة الحجز', widget.booking.status)])),
        const SizedBox(height: 16),
        Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المبلغ المستلم فعلياً', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface)), const SizedBox(height: 8), Text('أدخل المبلغ الذي استلمته من العميل. إذا كان مختلفاً عن الرسوم المتوقعة سيطلب التطبيق تأكيداً إضافياً.', style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45)), const SizedBox(height: 14), TextField(controller: _amount, enabled: !_saving, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.done, onSubmitted: (_) => _saving ? null : _save(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: scheme.onSurface), decoration: InputDecoration(hintText: 'مثلاً 75000', suffixText: 'د.ع', filled: true, fillColor: scheme.surfaceContainerHighest, prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)))]))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_outlined, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text('لا تسجّل الدفع إلا بعد استلام المبلغ فعلياً. سيُحفظ وقت الاستلام ويُحدّث الحجز تلقائياً.', style: TextStyle(color: scheme.onSurface, height: 1.5)))])),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline), label: Text(_saving ? 'جاري حفظ الدفع...' : 'تسجيل المبلغ وتأكيد الدفع'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      ])),
    );
  }

  Widget _row(BuildContext context, String label, String value) { final scheme = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$label: ', style: TextStyle(color: scheme.onSurfaceVariant)), Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)))])); }
}
