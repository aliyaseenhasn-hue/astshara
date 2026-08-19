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
  final Set<String> _pendingCancellationBookings = <String>{};
  final Set<String> _submittingCancellationBookings = <String>{};

  Future<String?> _profileId() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return null;
    final row = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<Map<String, dynamic>>> _slots() async {
    final lawyerId = await _profileId();
    if (lawyerId == null) return <Map<String, dynamic>>[];

    final rows = await SupabaseConfig.client
        .from('lawyer_availability_slots')
        .select('id, starts_at, ends_at, is_available')
        .eq('lawyer_id', lawyerId)
        .order('starts_at', ascending: false);
    final slots = (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();

    try {
      final requests = await SupabaseConfig.client.rpc('get_my_cancellation_requests');
      _pendingCancellationBookings
        ..clear()
        ..addAll(
          (requests is List ? requests : const <dynamic>[])
              .whereType<Map>()
              .where((row) => row['status']?.toString() == 'بانتظار مراجعة الإدارة')
              .map((row) => row['booking_id'].toString()),
        );
    } catch (_) {
      _pendingCancellationBookings.clear();
    }

    // لا نعتمد على RPC عام لتحديد الحجز. نحدد الحجز مباشرة عند الضغط على زر الإلغاء.
    return slots;
  }

  Future<String?> _resolveBookingId(Map<String, dynamic> slot) async {
    final existing = slot['booking_id']?.toString();
    if (existing != null && existing.isNotEmpty) return existing;

    final slotId = slot['id']?.toString();
    final startsAtRaw = slot['starts_at']?.toString();
    if (slotId == null || slotId.isEmpty || startsAtRaw == null || startsAtRaw.isEmpty) return null;

    // المسار الأساسي: استعلام مباشر إلى bookings من جهة المحامي.
    // توجد RLS صريحة تسمح للمحامي بقراءة الحجوزات التي يكون lawyer_id فيها ملفه.
    try {
      final lawyerId = await _profileId();
      if (lawyerId != null) {
        final startsAt = DateTime.tryParse(startsAtRaw);
        if (startsAt != null) {
          final from = startsAt.subtract(const Duration(seconds: 120)).toUtc().toIso8601String();
          final to = startsAt.add(const Duration(seconds: 120)).toUtc().toIso8601String();
          final rows = await SupabaseConfig.client
              .from('bookings')
              .select('id, scheduled_at, status, consultation_status')
              .eq('lawyer_id', lawyerId)
              .gte('scheduled_at', from)
              .lte('scheduled_at', to)
              .not('status', 'in', '(ملغي,ملغى,مسترد,مكتمل)')
              .order('scheduled_at', ascending: true)
              .limit(1);
          if (rows is List && rows.isNotEmpty && rows.first is Map) {
            final id = (rows.first as Map)['id']?.toString();
            if (id != null && id.isNotEmpty) return id;
          }
        }
      }
    } catch (_) {}

    // مسار خادم مباشر بالـslot_id للتوافق مع النسخ السابقة.
    try {
      final result = await SupabaseConfig.client.rpc(
        'get_booking_id_for_slot',
        params: {'p_slot_id': slotId},
      );
      if (result is String && result.isNotEmpty) return result;
      if (result is Map) return result['booking_id']?.toString();
      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is String && first.isNotEmpty) return first;
        if (first is Map) return first['booking_id']?.toString();
      }
    } catch (_) {}

    return null;
  }

  Future<void> _requestCancellation(Map<String, dynamic> slot) async {
    final bookingId = await _resolveBookingId(slot);
    if (!mounted) return;
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر العثور على الحجز المرتبط بهذا الموعد. حدّث الصفحة وحاول مرة أخرى.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_pendingCancellationBookings.contains(bookingId) || _submittingCancellationBookings.contains(bookingId)) return;

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب إلغاء الحجز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('يرجى توضيح سبب إلغاء الحجز. سيتم إرسال الطلب إلى الإدارة للمراجعة.'),
            const SizedBox(height: 14),
            TextField(controller: controller, maxLines: 5, autofocus: true, decoration: const InputDecoration(labelText: 'سبب الإلغاء', hintText: 'اكتب سبب الإلغاء هنا')),
          ],
        ),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submittingCancellationBookings.remove(bookingId));
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await SupabaseConfig.client.from('lawyer_availability_slots').delete().eq('id', id);
      if (mounted) setState(() {});
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
      if (mounted) setState(() {});
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
    final isBooked = !isPast && !available;
    final pending = isBooked && bookingId != null && _pendingCancellationBookings.contains(bookingId);
    final submitting = isBooked && bookingId != null && _submittingCancellationBookings.contains(bookingId);
    final statusText = isPast ? 'موعد سابق' : (isBooked ? 'محجوز' : 'متاح للحجز');
    final statusColor = isPast ? scheme.onSurfaceVariant : (isBooked ? AppColors.warning : AppColors.success);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(isPast ? Icons.history_rounded : (isBooked ? Icons.event_busy_rounded : Icons.event_available_rounded), color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(start), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text('${AppTimeFormat.time12(start)} • مدة الاستشارة 30 دقيقة', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                if (!isBooked && (isPast || available))
                  IconButton(tooltip: 'حذف الموعد', onPressed: () => _deleteSlot(slot['id'].toString()), icon: Icon(Icons.delete_outline_rounded, color: scheme.error)),
              ],
            ),
            if (isBooked)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: pending
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                          child: const Text('طلب الإلغاء بانتظار مراجعة الإدارة', style: TextStyle(fontWeight: FontWeight.w700)),
                        )
                      : OutlinedButton.icon(
                          onPressed: submitting ? null : () => _requestCancellation(slot),
                          icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.event_busy_outlined),
                          label: const Text('طلب إلغاء الحجز'),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المواعيد'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addSlot, icon: const Icon(Icons.add_rounded), label: const Text('إضافة موعد')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _slots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المواعيد: ${snapshot.error}'));
          final slots = snapshot.data ?? const <Map<String, dynamic>>[];
          if (slots.isEmpty) return const Center(child: Text('لا توجد مواعيد منشورة'));
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: slots.map(_slotCard).toList()),
          );
        },
      ),
    );
  }
}
