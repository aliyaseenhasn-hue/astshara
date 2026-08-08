import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../providers/lawyers_provider.dart';
import '../widgets/lawyer_achievements_gallery.dart';

class LawyerProfileEditPage extends ConsumerStatefulWidget {
  const LawyerProfileEditPage({super.key});
  @override
  ConsumerState<LawyerProfileEditPage> createState() => _LawyerProfileEditPageState();
}

class _LawyerProfileEditPageState extends ConsumerState<LawyerProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _differentConsultationPriceController = TextEditingController();
  late List<LawyerService> _services;
  bool _isLoading = false;
  String? _profileId;

  @override
  void initState() { super.initState(); _services = []; _loadProfile(); }
  @override
  void dispose() { _bioController.dispose(); _differentConsultationPriceController.dispose(); super.dispose(); }

  Future<void> _loadProfile() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    final profile = await ref.read(lawyersRepositoryProvider).getLawyerProfile(user.id);
    if (profile != null && mounted) setState(() {
      _services = List.from(profile.services);
      _bioController.text = profile.bio ?? '';
      final consultationPrice = profile.consultationPrice ?? 0;
      _differentConsultationPriceController.text = consultationPrice > 0 ? consultationPrice.toStringAsFixed(0) : '';
      _profileId = profile.profileId;
    });
  }

  void _addService() => setState(() => _services.add(const LawyerService(title: '', price: 0)));
  void _removeService(int index) => setState(() => _services.removeAt(index));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final differentPrice = double.tryParse(_differentConsultationPriceController.text.trim()) ?? 0;
    if (differentPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد سعر الاستشارة المختلفة بشكل صحيح'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;
      final repo = ref.read(lawyersRepositoryProvider);
      final profile = await repo.getLawyerProfile(user.id);
      if (profile == null) return;
      await repo.updateLawyerProfile(profile.copyWith(
        bio: _bioController.text.trim(),
        services: _services,
        consultationPrice: differentPrice,
      ));
      ref.invalidate(lawyerProfileProvider(profile.profileId));
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح'))); Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي'), actions: [if (!_isLoading) IconButton(icon: const Icon(Icons.check), onPressed: _save)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('السيرة الذاتية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(controller: _bioController, maxLines: 6, maxLength: 1000, decoration: const InputDecoration(hintText: 'اكتب نبذة مهنية عن خبرتك وتخصصك والإنجازات التي تود تعريف العملاء بها...', border: OutlineInputBorder()), validator: (value) => value == null || value.trim().isEmpty ? 'السيرة الذاتية مطلوبة' : null),
          const SizedBox(height: 28),
          if (_profileId != null) ...[LawyerAchievementsGallery(lawyerId: _profileId!, editable: true), const SizedBox(height: 28)],
          const Text('سعر الاستشارة المختلفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('هذا هو السعر الذي سيدفعه العميل عند اختيار «استشارة مختلفة».', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextFormField(controller: _differentConsultationPriceController, decoration: const InputDecoration(labelText: 'السعر (د.ع)', hintText: 'مثلاً: 50000', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (val) { final price = double.tryParse(val?.trim() ?? ''); return price == null || price <= 0 ? 'حدد سعرًا أكبر من صفر' : null; }),
          const SizedBox(height: 28),
          const Text('باقات الاستشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('أضف باقات استشارية مخصصة لعملائك.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _services.length, itemBuilder: (context, index) => _buildServiceEditor(index)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _addService, icon: const Icon(Icons.add), label: const Text('إضافة باقة جديدة'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 40),
        ])),
      ),
    );
  }

  Widget _buildServiceEditor(int index) => Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Row(children: [Expanded(child: TextFormField(initialValue: _services[index].title, decoration: const InputDecoration(labelText: 'عنوان الباقة', hintText: 'مثلاً: استشارة هاتفية 30 دقيقة'), onSaved: (val) => _services[index] = _services[index].copyWith(title: val ?? ''), validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null)), IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => _removeService(index))]),
    const SizedBox(height: 12),
    TextFormField(initialValue: _services[index].price.toString(), decoration: const InputDecoration(labelText: 'السعر (د.ع)'), keyboardType: TextInputType.number, onSaved: (val) => _services[index] = _services[index].copyWith(price: double.tryParse(val ?? '0') ?? 0), validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null),
    const SizedBox(height: 12),
    TextFormField(initialValue: _services[index].description, decoration: const InputDecoration(labelText: 'وصف مختصر (اختياري)'), maxLines: 2, onSaved: (val) => _services[index] = _services[index].copyWith(description: val)),
  ])));
}
