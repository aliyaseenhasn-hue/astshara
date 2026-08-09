import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_time_format.dart';

class LawyerAvailabilityPage extends ConsumerStatefulWidget {
  const LawyerAvailabilityPage({super.key});
  @override ConsumerState<LawyerAvailabilityPage> createState() => _LawyerAvailabilityPageState();
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
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المواعيد المتاحة')),
      floatingActionButton: FloatingActionButton(onPressed: _addSlot, child: const Icon(Icons.add)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _slots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final slots = snapshot.data!;
          if (slots.isEmpty) return const Center(child: Text('لا توجد مواعيد منشورة. أضف موعدًا ليظهر لطالبي الاستشارة.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final start = DateTime.parse(slot['starts_at'] as String).toLocal();
              final isPast = start.isBefore(DateTime.now());
              final canDelete = isPast || slot['is_available'] == true;
              return Card(
                child: ListTile(
                  leading: Icon(isPast ? Icons.history : (slot['is_available'] == true ? Icons.event_available : Icons.event_busy), color: isPast ? AppColors.outline : (slot['is_available'] == true ? AppColors.success : AppColors.outline)),
                  title: Text(DateFormat('yyyy-MM-dd').format(start)),
                  subtitle: Text('${AppTimeFormat.time12(start)}${isPast ? ' • موعد سابق' : (slot['is_available'] == true ? ' • متاح' : ' • محجوز')}'),
                  trailing: canDelete ? IconButton(tooltip: isPast ? 'حذف الموعد السابق' : 'حذف الموعد', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(slot['id'] as String)) : const Icon(Icons.lock_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
