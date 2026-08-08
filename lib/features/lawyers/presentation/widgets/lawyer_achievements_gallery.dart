import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';

class LawyerAchievementsGallery extends ConsumerStatefulWidget {
  final String lawyerId;
  final bool editable;
  const LawyerAchievementsGallery({super.key, required this.lawyerId, this.editable = false});

  @override
  ConsumerState<LawyerAchievementsGallery> createState() => _LawyerAchievementsGalleryState();
}

class _LawyerAchievementsGalleryState extends ConsumerState<LawyerAchievementsGallery> {
  late Future<List<Map<String, dynamic>>> _items;
  bool _uploading = false;

  @override
  void initState() { super.initState(); _reload(); }
  void _reload() {
    _items = SupabaseConfig.client.from('lawyer_achievements').select('id, image_url, image_path, title, description, created_at').eq('lawyer_id', widget.lawyerId).order('created_at', ascending: false).then((rows) => (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  Future<void> _addAchievement() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file?.bytes == null) return;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('إضافة إنجاز'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان القرار أو الإنجاز')),
        const SizedBox(height: 12),
        TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'تعليق / وصف')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
      ],
    ));
    titleController.dispose();
    descriptionController.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _uploading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول');
      final safeName = file!.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      await SupabaseConfig.client.storage.from('lawyer_achievements').uploadBinary(path, file.bytes!);
      final publicUrl = SupabaseConfig.client.storage.from('lawyer_achievements').getPublicUrl(path);
      await SupabaseConfig.client.from('lawyer_achievements').insert({
        'lawyer_id': widget.lawyerId,
        'image_url': publicUrl,
        'image_path': path,
        'title': titleController.text.trim().isEmpty ? null : titleController.text.trim(),
        'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      });
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر رفع الإنجاز: $e'), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => _uploading = false); }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await SupabaseConfig.client.storage.from('lawyer_achievements').remove([item['image_path'] as String]);
      await SupabaseConfig.client.from('lawyer_achievements').delete().eq('id', item['id']);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الإنجاز: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _items,
    builder: (context, snapshot) {
      final items = snapshot.data ?? const <Map<String, dynamic>>[];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('القرارات والإنجازات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary))),
          if (widget.editable) IconButton(onPressed: _uploading ? null : _addAchievement, icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary), tooltip: 'إضافة إنجاز'),
        ]),
        if (_uploading) const LinearProgressIndicator(),
        if (snapshot.connectionState == ConnectionState.waiting) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
        else if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('لم تتم إضافة قرارات أو إنجازات بعد.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
        else GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .78),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: Image.network(item['image_url'] as String, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)))),
                Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (item['title'] != null) Text(item['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (item['description'] != null) ...[const SizedBox(height: 4), Text(item['description'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey))],
                  if (widget.editable) Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20))),
                ])),
              ]),
            );
          },
        ),
      ]);
    },
  );
}
