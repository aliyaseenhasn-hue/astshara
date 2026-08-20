import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_time_format.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class LawyerAvailabilityPage extends ConsumerStatefulWidget {
  const LawyerAvailabilityPage({super.key});
  @override
  ConsumerState<LawyerAvailabilityPage> createState() => _LawyerAvailabilityPageState();
}

class _LawyerAvailabilityPageState extends ConsumerState<LawyerAvailabilityPage> {
  late Future<List<Map<String, dynamic>>> _slotsFuture;
  final Set<String> _pendingCancellationBookings = <String>{};
  final Set<String> _submittingCancellationBookings = <String>{};

  @override
  void initState() {
    super.initState();
    _slotsFuture = _loadSlots();
  }

  Future<String?> _profileId() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return null;
    final row = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
    return row?['id']?.toString();
  }

  Future<List<Map<String, dynamic>>> _loadSlots() async {
    final lawyerId = await _profileId();
    if (lawyerId == null) return <Map<String, dynamic>>[];

    final rawSlots = await SupabaseConfig.client
        .from('lawyer_availability_slots')
        .select('id, starts_at, ends_at, is_available')
        .eq('lawyer_id', lawyerId)
        .order('starts_at', ascending: false);
    final slots = (rawSlots as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();

    _pendingCancellationBookings.clear();
    try {
      final requests = await SupabaseConfig.client.rpc('get_my_cancellation_requests');
      final list = requests is List ? requests : const <dynamic>[];
      _pendingCancellationBookings.addAll(
        list.whereType<Map>().where((row) => row['status']?.toString() == 'بانتظار مراجعة الإدارة').map((row) => row['booking_id'].toString()),
      );
    } catch (_) {}

    if (slots.isEmpty) return slots;

    final starts = slots.map((s) => DateTime.tryParse(s['starts_at']?.toString() ?? '')).whereType<DateTime>().toList();
    if (starts.isEmpty) return slots;

    final minStart = starts.reduce((a, b) => a.isBefore(b) ? a : b).subtract(const Duration(minutes: 2)).toUtc().toIso8601String();
    final maxStart = starts.reduce((a, b) => a.isAfter(b) ? a : b).add(const Duration(minutes: 2)).toUtc().toIso8601String();

    try {
      final rawBookings = await SupabaseConfig.client
          .from('bookings')
          .select('id, scheduled_at, status, consultation_status')
          .eq('lawyer_id', lawyerId)
          .gte('scheduled_at', minStart)
          .lte('scheduled_at', maxStart)
          .order('scheduled_at', ascending: true);
      final bookings = (rawBookings as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
      const terminalStatuses = {'ملغي', 'ملغى', 'مسترد', 'مكتمل'};

      for (final slot in slots) {
        final slotStart = DateTime.tryParse(slot['starts_at']?.toString() ?? '');
        if (slotStart == null) continue;
        Map<String, dynamic>? best;
        var bestSeconds = double.infinity;
        for (final booking in bookings) {
          if (terminalStatuses.contains(booking['status']?.toString())) continue;
          final bookingStart = DateTime.tryParse(booking['scheduled_at']?.toString() ?? '');
          if (bookingStart == null) continue;
          final seconds = bookingStart.difference(slotStart).inSeconds.abs().toDouble();
          if (seconds <= 120 && seconds < bestSeconds) {
            best = booking;
            bestSeconds = seconds;
          }
        }
        if (best != null) {
          slot['booking_id'] = best['id']?.toString();
          slot['booking_status'] = best['status']?.toString();
          slot['consultation_status'] = best['consultation_status']?.toString();
        }
      }
    } catch (e) {
      debugPrint('تعذر تحميل الحجوزات المرتبطة بالمواعيد: $e');
    }

    return slots;
  }

  void _refresh() => setState(() => _slotsFuture = _loadSlots());

  Future<void> _requestCancellation(Map<String, dynamic> slot) async {
    final bookingId = slot['booking_id']?.toString();
    if (!mounted || bookingId == null || bookingId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد حجز فعلي مرتبط بهذا الموعد.'), backgroundColor: AppColors.error));
      return;
    }
    if (_pendingCancellationBookings.contains(bookingId) || _submittingCancellationBookings.contains(bookingId)) return;

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب إلغاء الحجز'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('يرجى توضيح سبب إلغاء الحجز. سيتم إرسال الطلب إلى الإدارة للمراجعة.'),
          const SizedBox(height: 14),
          TextField(controller: controller, maxLines: 5, autofocus: true, decoration: const InputDecoration(labelText: 'سبب الإلغاء', hintText: 'اكتب سبب الإلغاء هنا')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('سبب الإلغاء إلزامي')));
                return;
              }
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('إرسال طلب الإلغاء'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;

    setState(() => _submittingCancellationBookings.add(bookingId));
    try {
      await SupabaseConfig.client.rpc('request_booking_cancellation', params: {'p_booking_id': bookingId, 'p_reason': reason});
      if (!mounted) return;
      setState(() => _pendingCancellationBookings.add(bookingId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب إلغاء الحجز إلى الإدارة للمراجعة.')));
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submittingCancellationBookings.remove(bookingId));
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await SupabaseConfig.client.from('lawyer_availability_slots').delete().eq('id', id);
      if (mounted) _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الموعد: $e'), backgroundColor: AppColors.error));
    }
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
      if (mounted) _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إضافة الموعد: $e'), backgroundColor: AppColors.error));
    }
  }

  Widget _slotCard(Map<String, dynamic> slot) {
    final scheme = Theme.of(context).colorScheme;
    final start = DateTime.tryParse(slot['starts_at']?.toString() ?? '')?.toLocal();
    if (start == null) return const SizedBox.shrink();
    final isPast = start.isBefore(DateTime.now());
    final available = slot['is_available'] == true;
    final bookingId = slot['booking_id']?.toString();
    final isBooked = !isPast && !available && bookingId != null && bookingId.isNotEmpty;
    final isBlocked = !isPast && !available && !isBooked;
    final pending = isBooked && _pendingCancellationBookings.contains(bookingId);
    final submitting = isBooked && _submittingCancellationBookings.contains(bookingId);
    final statusText = isPast ? 'موعد سابق' : (isBooked ? 'محجوز' : (isBlocked ? 'غير متاح' : 'متاح للحجز'));
    final statusColor = isPast ? scheme.onSurfaceVariant : (isBooked ? AppColors.warning : (isBlocked ? scheme.onSurfaceVariant : AppColors.success));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(isPast ? Icons.history_rounded : (isBooked ? Icons.event_busy_rounded : Icons.event_available_rounded), color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(start), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('${AppTimeFormat.time12(start)} • مدة الاستشارة 30 دقيقة', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 6),
              Text(statusText, textAlign: TextAlign.right, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
            if (!isBooked && (isPast || available)) IconButton(tooltip: 'حذف الموعد', onPressed: () => _deleteSlot(slot['id'].toString()), icon: Icon(Icons.delete_outline_rounded, color: scheme.error)),
          ]),
          if (isBooked)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: pending
                    ? Container(padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: const Text('طلب الإلغاء بانتظار مراجعة الإدارة', style: TextStyle(fontWeight: FontWeight.w700)))
                    : OutlinedButton.icon(onPressed: submitting ? null : () => _requestCancellation(slot), icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.event_busy_outlined), label: const Text('طلب إلغاء الحجز')),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخطوة ٢ من ٢: أوقات التوفر'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addSlot, icon: const Icon(Icons.add_rounded), label: const Text('إضافة موعد')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المواعيد: ${snapshot.error}', textAlign: TextAlign.center));
          final slots = snapshot.data ?? const <Map<String, dynamic>>[];
          if (slots.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('أضف موعداً واحداً على الأقل حتى تتمكن من استقبال الطلبات.', textAlign: TextAlign.center)));
          return RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 130), children: slots.map(_slotCard).toList());
        },
      ),
      bottomNavigationBar: FutureBuilder<List<Map<String, dynamic>>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          final slots = snapshot.data ?? const <Map<String, dynamic>>[];
          final hasFutureAvailable = slots.any((slot) {
            final start = DateTime.tryParse(slot['starts_at']?.toString() ?? '');
            return start != null && start.isAfter(DateTime.now()) && slot['is_available'] == true;
          });
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: FilledButton.icon(
                onPressed: hasFutureAvailable ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إكمال إعداد استقبال الاستشارات بنجاح'))); Navigator.pop(context); } : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('حفظ وإكمال', style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          );
        },
      ),
    );
  }
}
