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
  static const _options = <String>[
    'مدني', 'جنائي', 'تجاري', 'أحوال شخصية', 'عمالي', 'إداري', 'عقاري', 'دولي',
  ];

  final Set<String> _selected = <String>{};
  PlatformFile? _idCard;
  bool _saving = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قراءة الملف المختار.')),
      );
      return;
    }
    setState(() => _idCard = file);
  }

  Future<void> _submit() async {
    final idCard = _idCard;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تخصصاً واحداً على الأقل.')),
      );
      return;
    }
    if (idCard == null || idCard.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أرفق صورة هوية النقابة.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = LawyersRepositoryImpl(SupabaseConfig.client);
      final url = await repo.uploadFile(idCard.bytes!, idCard.name, 'lawyer_documents');
      await repo.requestSpecializationChange(
        _selected.toList(growable: false),
        unionIdCardUrl: url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب إلى الإدارة للمراجعة.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
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
          const Text(
            'التخصصات المطلوبة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((specialization) {
              return FilterChip(
                label: Text(specialization),
                selected: _selected.contains(specialization),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(specialization);
                    } else {
                      _selected.remove(specialization);
                    }
                  });
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 24),
          const Text(
            'هوية النقابة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'يجب إرفاق صورة واضحة لهوية النقابة حتى يتمكن الأدمن من مراجعة الطلب.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pick,
            icon: const Icon(Icons.badge_outlined),
            label: Text(_idCard?.name ?? 'إرفاق هوية النقابة'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إرسال الطلب للمراجعة'),
          ),
        ],
      ),
    );
  }
}
