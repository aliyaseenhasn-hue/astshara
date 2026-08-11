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
  void initState() {
    super.initState();
    _services = [];
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _differentConsultationPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    final profile = await ref.read(lawyersRepositoryProvider).getLawyerProfile(user.id);
    if (profile != null && mounted) {
      setState(() {
        _services = List.from(profile.services);
        _bioController.text = profile.bio ?? '';
        final consultationPrice = profile.consultationPrice ?? 0;
        _differentConsultationPriceController.text = consultationPrice > 0 ? consultationPrice.toStringAsFixed(0) : '';
        _profileId = profile.profileId;
      });
    }
  }

  void _addService() => setState(() => _services.add(const LawyerService(title: '', price: 0)));
  void _removeService(int index) => setState(() => _services.removeAt(index));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null || _profileId == null) return;
      final services = _services.where((s) => s.title.trim().isNotEmpty && s.price >= 0).toList();
      await ref.read(lawyersRepositoryProvider).updateLawyerProfile(
        profileId: _profileId!,
        bio: _bioController.text.trim(),
        consultationPrice: double.tryParse(_differentConsultationPriceController.text.trim()),
        services: services,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف المهني بنجاح')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ الملف: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('تعديل الملف المهني')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.p20),
          children: [
            TextFormField(controller: _bioController, maxLines: 5, decoration: const InputDecoration(labelText: 'نبذة مهنية'), validator: (v) => v == null || v.trim().isEmpty ? 'النبذة المهنية مطلوبة' : null),
            const SizedBox(height: 20),
            Text('الاستشارة المختلفة', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
            const SizedBox(height: 8),
            TextFormField(controller: _differentConsultationPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر بالدينار العراقي', suffixText: 'د.ع'), validator: (v) { final value = double.tryParse(v?.trim() ?? ''); return value == null || value < 0 ? 'أدخل سعراً صحيحاً' : null; }),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('باقات الاستشارة', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), TextButton.icon(onPressed: _addService, icon: const Icon(Icons.add), label: const Text('إضافة'))]),
            const SizedBox(height: 8),
            ...List.generate(_services.length, (index) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextFormField(initialValue: _services[index].title, decoration: const InputDecoration(labelText: 'اسم الباقة'), onChanged: (value) => _services[index] = _services[index].copyWith(title: value), validator: (v) => v == null || v.trim().isEmpty ? 'اسم الباقة مطلوب' : null)), const SizedBox(width: 10), SizedBox(width: 110, child: TextFormField(initialValue: _services[index].price.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر'), onChanged: (value) => _services[index] = _services[index].copyWith(price: double.tryParse(value) ?? 0))), IconButton(onPressed: () => _removeService(index), icon: const Icon(Icons.delete_outline, color: AppColors.error))]))),
            const SizedBox(height: 12),
            const LawyerAchievementsGalleryEditor(),
            const SizedBox(height: 24),
            SizedBox(height: 52, child: ElevatedButton(onPressed: _isLoading ? null : _save, child: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات'))),
          ],
        ),
      ),
    );
  }
}
