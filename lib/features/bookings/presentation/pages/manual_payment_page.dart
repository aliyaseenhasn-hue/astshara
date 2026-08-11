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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('تسجيل الدفع اليدوي')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        Text('تسجيل المبلغ المستلم', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 8),
        Text('أكد المبلغ الذي تم استلامه فعلياً من العميل قبل بدء الاستشارة.', style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 20),
        Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.payments_outlined, color: scheme.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الدفع في المكتب', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 4), Text('الحجز #${widget.booking.id.length >= 8 ? widget.booking.id.substring(0, 8) : widget.booking.id}', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))]))]),
          const SizedBox(height: 18),
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Row(children: [Expanded(child: Text('المبلغ المطلوب حسب الحجز', style: TextStyle(color: scheme.onSurfaceVariant))), Text('${widget.booking.price} د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface))])),
        ]))),
        const SizedBox(height: 20),
        Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المبلغ المستلم فعلياً', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 10),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface), decoration: InputDecoration(hintText: 'مثلاً 75000', suffixText: 'د.ع', filled: true, fillColor: scheme.surfaceContainerHighest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.primary, width: 2)))),
        ]))),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .45), borderRadius: BorderRadius.circular(14)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20), const SizedBox(width: 10), Expanded(child: Text('لن يُعتبر الحجز مدفوعاً ولن تصبح الاستشارة جاهزة للبدء إلا بعد تسجيل المبلغ المستلم فعلياً.', style: TextStyle(color: scheme.onSurface, height: 1.5, fontSize: 12)))])),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.check_circle_outline), label: Text(_saving ? 'جاري الحفظ...' : 'تسجيل المبلغ وتأكيد الدفع'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)))),
      ])),
    );
  }
}
