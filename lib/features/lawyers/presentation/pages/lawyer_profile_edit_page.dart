import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String? _lawyerProfileId;

  @override
  void initState() { super.initState(); _services = []; _loadProfile(); }
  @override
  void dispose() { _bioController.dispose(); _differentConsultationPriceController.dispose(); super.dispose(); }

  Future<void> _loadProfile() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    final profile = await ref.read(lawyersRepositoryProvider).getLawyerProfile(user.id);
    if (profile != null && mounted) {
      setState(() {
        _services = List<LawyerService>.from(profile.services);
        _bioController.text = profile.bio ?? '';
        final price = profile.consultationPrice ?? 0;
        _differentConsultationPriceController.text = price > 0 ? price.toStringAsFixed(0) : '';
        // lawyer_achievements.lawyer_id references lawyer_profiles.id,
        // not profiles.id (profile.profileId).
        _lawyerProfileId = profile.id;
      });
    }
  }

  void _addService() => setState(() => _services.add(const LawyerService(title: '', price: 0)));
  void _removeService(int index) => setState(() => _services.removeAt(index));

  Future<bool> _persist() async {
    if (!_formKey.currentState!.validate()) return false;
    _formKey.currentState!.save();
    final price = double.tryParse(_differentConsultationPriceController.text.trim()) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد سعر الاستشارة المختلفة بشكل صحيح'), backgroundColor: AppColors.error));
      return false;
    }
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف باقة استشارة واحدة على الأقل قبل المتابعة'), backgroundColor: AppColors.error));
      return false;
    }
    for (final service in _services) {
      if (service.title.trim().isEmpty || service.price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأكد من أن كل باقة تحتوي على اسم وسعر صحيحين'), backgroundColor: AppColors.error));
        return false;
      }
    }
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return false;
      final repo = ref.read(lawyersRepositoryProvider);
      final profile = await repo.getLawyerProfile(user.id);
      if (profile == null) return false;
      await repo.updateLawyerProfile(profile.copyWith(bio: _bioController.text.trim(), services: _services, consultationPrice: price));
      ref.invalidate(lawyerProfileProvider(profile.profileId));
      return true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في حفظ الباقات: $e'), backgroundColor: AppColors.error));
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!await _persist() || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الباقات والتعديلات بنجاح')));
    Navigator.pop(context);
  }

  Future<void> _saveAndContinue() async {
    if (!await _persist() || !mounted) return;
    context.push('/lawyer-availability');
  }

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint, filled: true, fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.outline)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الخطوة ١ من ٢: باقات الاستشارات', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [if (!_isLoading) IconButton(tooltip: 'حفظ', icon: const Icon(Icons.check_rounded), onPressed: _save)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSizes.p20, 20, AppSizes.p20, 130),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(24)),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('أكمل إعداد استقبال الاستشارات', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 7),
                        Text('أضف باقاتك وأسعارك ومدة الاستشارة. بعد إكمال هذه الخطوة اضغط التالي لتحديد أوقات التوفر.', style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    const Text('السيرة الذاتية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    const SizedBox(height: 10),
                    TextFormField(controller: _bioController, maxLines: 6, maxLength: 1000, decoration: _input('نبذة مهنية', hint: 'اكتب نبذة عن خبرتك وتخصصك وإنجازاتك...'), validator: (v) => v == null || v.trim().isEmpty ? 'السيرة الذاتية مطلوبة' : null),
                    const SizedBox(height: 24),
                    if (_lawyerProfileId != null) ...[
                      const Text('الإنجازات المهنية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                      const SizedBox(height: 10),
                      LawyerAchievementsGallery(lawyerId: _lawyerProfileId!, editable: true),
                      const SizedBox(height: 24),
                    ],
                    const Text('سعر الاستشارة المختلفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    const SizedBox(height: 8),
                    const Text('السعر المستخدم عند اختيار العميل استشارة مختلفة.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    TextFormField(controller: _differentConsultationPriceController, decoration: _input('السعر (د.ع)', hint: 'مثلاً: 50000'), keyboardType: TextInputType.number, validator: (v) { final p = double.tryParse(v?.trim() ?? ''); return p == null || p <= 0 ? 'حدد سعرًا أكبر من صفر' : null; }),
                    const SizedBox(height: 24),
                    const Text('باقات الاستشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                    const SizedBox(height: 8),
                    const Text('يمكنك إضافة أكثر من باقة وتعديلها أو حذفها في أي وقت.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _services.length, itemBuilder: (context, index) => _buildServiceEditor(index)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: _addService, icon: const Icon(Icons.add_rounded), label: const Text('إضافة باقة جديدة'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _saveAndContinue,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('التالي: أوقات التوفر', style: TextStyle(fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceEditor(int index) => Card(
    margin: const EdgeInsets.only(bottom: 14), elevation: 0, color: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.outline)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextFormField(initialValue: _services[index].title, decoration: _input('عنوان الباقة', hint: 'مثلاً: استشارة هاتفية 30 دقيقة'), onSaved: (v) => _services[index] = _services[index].copyWith(title: v ?? ''), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null)),
          IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: () => _removeService(index)),
        ]),
        const SizedBox(height: 12),
        TextFormField(initialValue: _services[index].price.toString(), decoration: _input('السعر (د.ع)'), keyboardType: TextInputType.number, onSaved: (v) => _services[index] = _services[index].copyWith(price: double.tryParse(v ?? '0') ?? 0), validator: (v) { final p = double.tryParse(v ?? ''); return p == null || p <= 0 ? 'حدد سعراً صحيحاً' : null; }),
        const SizedBox(height: 12),
        TextFormField(initialValue: _services[index].description, decoration: _input('وصف مختصر (اختياري)'), maxLines: 2, onSaved: (v) => _services[index] = _services[index].copyWith(description: v)),
      ]),
    ),
  );
}
