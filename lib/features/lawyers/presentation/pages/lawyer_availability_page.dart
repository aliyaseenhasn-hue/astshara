import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_time_format.dart';

class LawyerAvailabilityPage extends ConsumerStatefulWidget {
  const LawyerAvailabilityPage({super.key});
  @override
  ConsumerState<LawyerAvailabilityPage> createState() => _LawyerAvailabilityPageState();
}

class _LawyerAvailabilityPageState extends ConsumerState<LawyerAvailabilityPage> {
  Future<String?> _profileId() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return null;
    final row = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
    return row?['id'] as String?;
  }

  Future<void> _addSlot() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)), initialDate: DateTime.now().add(const Duration(days: 1)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (time == null) return;
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final lawyerId = await _profileId();
    if (lawyerId == null) return;
    try {
      await SupabaseConfig.client.from('lawyer_availability_slots').insert({'lawyer_id': lawyerId, 'starts_at': start.toUtc().toIso8601String(), 'ends_at': start.add(const Duration(minutes: 30)).toUtc().toIso8601String(), 'is_available': true});
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<List<Map<String, dynamic>>> _slots() async {
    final lawyerId = await _profileId();
    if (lawyerId == null) return [];
    final rows = await SupabaseConfig.client.from('lawyer_availability_slots').select('id, starts_at, ends_at, is_available').eq('lawyer_id', lawyerId).order('starts_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _delete(String id) async {
    try {
      await SupabaseConfig.client.from('lawyer_availability_slots').delete().eq('id', id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الموعد: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context);
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('إدارة المواعيد', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: true, elevation: 0, scrolledUnderElevation: 0),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addSlot, icon: const Icon(Icons.add_rounded), label: const Text('إضافة موعد', style: TextStyle(fontWeight: FontWeight.w800))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _slots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المواعيد', style: TextStyle(color: scheme.onSurfaceVariant)));
          final slots = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [scheme.primaryContainer, scheme.surfaceContainerHighest]), borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55))),
                  child: Row(textDirection: rtl, children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: dark ? AppColors.gold.withValues(alpha: .16) : scheme.primary.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(Icons.calendar_month_rounded, color: dark ? AppColors.gold : scheme.primary, size: 27)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('مواعيدك المتاحة', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('أضف أوقاتاً متاحة لتظهر لطالبي الاستشارة عند الحجز.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.45))])),
                  ]),
                ),
                const SizedBox(height: 26),
                Row(textDirection: rtl, children: [Expanded(child: Text('المواعيد المنشورة', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 19, fontWeight: FontWeight.w800))), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Text('${slots.length}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)))]),
                const SizedBox(height: 14),
                if (slots.isEmpty)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42), decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(22), border: Border.all(color: scheme.outlineVariant)), child: Column(children: [Icon(Icons.event_available_rounded, size: 44, color: scheme.onSurfaceVariant), const SizedBox(height: 14), Text('لا توجد مواعيد منشورة', style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text('أضف أول موعد ليظهر لطالبي الاستشارة.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, height: 1.5))]))
                else
                  ...slots.map((slot) {
                    final start = DateTime.parse(slot['starts_at'] as String).toLocal();
                    final isPast = start.isBefore(DateTime.now());
                    final available = slot['is_available'] == true;
                    final statusColor = isPast ? scheme.onSurfaceVariant : (available ? AppColors.success : AppColors.warning);
                    final statusText = isPast ? 'موعد سابق' : (available ? 'متاح للحجز' : 'محجوز');
                    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant), boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 16, offset: const Offset(0, 5))]), child: Row(textDirection: rtl, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(15)), child: Icon(isPast ? Icons.history_rounded : (available ? Icons.event_available_rounded : Icons.event_busy_rounded), color: statusColor, size: 25)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(start), textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('${AppTimeFormat.time12(start)} • مدة الاستشارة 30 دقيقة', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)), const SizedBox(height: 7), Row(mainAxisAlignment: MainAxisAlignment.end, children: [Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)), const SizedBox(width: 5), Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700))])])), isPast || available ? IconButton(tooltip: 'حذف الموعد', onPressed: () => _delete(slot['id'] as String), icon: Icon(Icons.delete_outline_rounded, color: scheme.error)) : Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant)]));
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
