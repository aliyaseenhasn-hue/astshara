import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';

class LawyerAvailabilityPage extends ConsumerStatefulWidget {
  const LawyerAvailabilityPage({super.key});

  @override
  ConsumerState<LawyerAvailabilityPage> createState() => _LawyerAvailabilityPageState();
}

class _LawyerAvailabilityPageState extends ConsumerState<LawyerAvailabilityPage> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 30;
  bool _loading = false;

  Future<String?> _profileId() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', uid).maybeSingle();
    return row?['id'] as String?;
  }

  Future<void> _addSlot() async {
    final profileId = await _profileId();
    if (profileId == null) return;
    setState(() => _loading = true);
    try {
      final starts = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      final ends = starts.add(Duration(minutes: _duration));
      await SupabaseConfig.client.from('lawyer_availability_slots').insert({
        'lawyer_id': profileId,
        'starts_at': starts.toUtc().toIso8601String(),
        'ends_at': ends.toUtc().toIso8601String(),
        'is_available': true,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الموعد بنجاح')));
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إضافة الموعد: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadSlots() async {
    final profileId = await _profileId();
    if (profileId == null) return [];
    final response = await SupabaseConfig.client
        .from('lawyer_availability_slots')
        .select('id,starts_at,ends_at,is_available')
        .eq('lawyer_id', profileId)
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at');
    return (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await SupabaseConfig.client.from('lawyer_availability_slots').delete().eq('id', id);
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الموعد: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المواعيد')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadSlots(),
          builder: (context, snapshot) {
            final slots = snapshot.data ?? const <Map<String, dynamic>>[];
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('إضافة موعد متاح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final value = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90))); if (value != null) setState(() => _date = value); }, icon: const Icon(Icons.calendar_today), label: Text('${_date.day}/${_date.month}/${_date.year}'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final value = await showTimePicker(context: context, initialTime: _time); if (value != null) setState(() => _time = value); }, icon: const Icon(Icons.access_time), label: Text(_time.format(context)))),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(value: _duration, items: const [15, 30, 45, 60].map((v) => DropdownMenuItem(value: v, child: Text('$v دقيقة'))).toList(), onChanged: (v) => setState(() => _duration = v ?? 30), decoration: const InputDecoration(labelText: 'مدة الموعد', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _loading ? null : _addSlot, child: Text(_loading ? 'جاري الإضافة...' : 'إضافة الموعد')),
              ]))),
              const SizedBox(height: 20),
              const Text('المواعيد القادمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting) const Center(child: CircularProgressIndicator())
              else if (slots.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد مواعيد مضافة بعد'))))
              else ...slots.map((slot) {
                final starts = DateTime.parse(slot['starts_at'] as String).toLocal();
                final ends = DateTime.parse(slot['ends_at'] as String).toLocal();
                return Card(child: ListTile(title: Text('${starts.day}/${starts.month}/${starts.year}'), subtitle: Text('${TimeOfDay.fromDateTime(starts).format(context)} - ${TimeOfDay.fromDateTime(ends).format(context)}'), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteSlot(slot['id'] as String))));
              }),
            ]);
          },
        ),
      ),
    );
  }
}
