import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/lawyers_repository_impl.dart';

class SpecializationChangePage extends ConsumerStatefulWidget {
  const SpecializationChangePage({super.key});
  @override
  ConsumerState<SpecializationChangePage> createState() => _SpecializationChangePageState();
}

class _SpecializationChangePageState extends ConsumerState<SpecializationChangePage> {
  final _options = const ['مدني', 'جنائي', 'تجاري', 'أحوال شخصية', 'عمالي', 'إداري', 'عقاري', 'دولي'];
  final _selected = <String>{};
  PlatformFile? _idCard;
  bool _saving = false;

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'], withData: true);
    if (r?.files.isNotEmpty == true && mounted) setState(() => _idCard = r!.files.first);
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _idCard?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر تخصصاً وأرفق صورة هوية النقابة.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = LawyersRepositoryImpl(SupabaseConfig.client);
      final url = await repo.uploadFile(_idCard!.bytes!, _idCard!.name, 'lawyer_documents');
      await repo.requestSpecializationChange(_selected.toList(), unionIdCardUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب إلى الإدارة للمراجعة.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب تغيير التخصص')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('التخصصات المطلوبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((s) => FilterChip(label: Text(s), selected: _selected.contains(s), onSelected: (v) => setState(() => v ? _selected.add(s) : _selected.remove(s))).toList(),
          ),
          const SizedBox(height: 24),
          const Text('هوية النقابة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('يجب إرفاق صورة واضحة لهوية النقابة حتى يتمكن الأدمن من مراجعة الطلب.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _saving ? null : _pick, icon: const Icon(Icons.badge_outlined), label: Text(_idCard?.name ?? 'إرفاق هوية النقابة')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saving ? null : _submit, child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إرسال الطلب للمراجعة')),
        ],
      ),
    );
  }
}
