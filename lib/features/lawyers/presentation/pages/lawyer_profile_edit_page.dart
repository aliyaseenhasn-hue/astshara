import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../providers/lawyers_provider.dart';

class LawyerProfileEditPage extends ConsumerStatefulWidget {
  const LawyerProfileEditPage({super.key});

  @override
  ConsumerState<LawyerProfileEditPage> createState() =>
      _LawyerProfileEditPageState();
}

class _LawyerProfileEditPageState extends ConsumerState<LawyerProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late List<LawyerService> _services;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _services = [];
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      final profile =
          await ref.read(lawyersRepositoryProvider).getLawyerProfile(user.id);
      if (profile != null) {
        setState(() {
          _services = List.from(profile.services);
        });
      }
    }
  }

  void _addService() {
    setState(() {
      _services.add(const LawyerService(title: '', price: 0));
    });
  }

  void _removeService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;

      final repo = ref.read(lawyersRepositoryProvider);
      final profile = await repo.getLawyerProfile(user.id);

      if (profile != null) {
        final updatedProfile = profile.copyWith(services: _services);
        await repo.updateLawyerProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في الحفظ: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل باقات الاستشارة'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أضف باقات استشارية مخصصة لعملائك (مثال: استشارة سريعة، مراجعة عقد، إلخ)',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        return _buildServiceEditor(index);
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addService,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة باقة جديدة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceEditor(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _services[index].title,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الباقة',
                      hintText: 'مثلاً: استشارة هاتفية 30 دقيقة',
                    ),
                    onSaved: (val) => _services[index] =
                        _services[index].copyWith(title: val ?? ''),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeService(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _services[index].price.toString(),
              decoration: const InputDecoration(
                labelText: 'السعر (د.ع)',
              ),
              keyboardType: TextInputType.number,
              onSaved: (val) => _services[index] = _services[index]
                  .copyWith(price: double.tryParse(val ?? '0') ?? 0),
              validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _services[index].description,
              decoration: const InputDecoration(
                labelText: 'وصف مختصر (اختياري)',
              ),
              maxLines: 2,
              onSaved: (val) => _services[index] =
                  _services[index].copyWith(description: val),
            ),
          ],
        ),
      ),
    );
  }
}
