import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
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
      appBar: AppBar(
        title: const Text('طلب تغيير التخصص'),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.brandGradient,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حدّث تخصصك المهني',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'اختر المجالات التي ترغب بممارستها وأرسل المستندات للمراجعة.',
                            style: TextStyle(color: Color(0xE6FFFFFF), height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                number: '01',
                title: 'التخصصات المطلوبة',
                subtitle: 'يمكنك اختيار أكثر من تخصص.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _options.map((specialization) {
                    final selected = _selected.contains(specialization);
                    return FilterChip(
                      label: Text(specialization),
                      selected: selected,
                      showCheckmark: true,
                      checkmarkColor: AppColors.textOnPrimary,
                      selectedColor: AppColors.primaryLight,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selected.add(specialization);
                          } else {
                            _selected.remove(specialization);
                          }
                        });
                      },
                    );
                  }).toList(growable: false),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                number: '02',
                title: 'وثيقة التحقق',
                subtitle: 'مطلوبة للتأكد من صلاحية التخصص الجديد.',
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _saving ? null : _pick,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _idCard == null ? AppColors.outline : AppColors.primary,
                      width: _idCard == null ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _idCard == null ? Icons.badge_outlined : Icons.check_circle_rounded,
                          color: _idCard == null ? AppColors.primaryDark : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _idCard?.name ?? 'إرفاق هوية النقابة',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _idCard == null ? 'JPG أو PNG أو PDF' : 'تم اختيار المستند بنجاح',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primaryDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تستخدم الوثيقة لغرض التحقق والمراجعة فقط، ولا تظهر لطالبي الاستشارة.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'جارٍ إرسال الطلب...' : 'إرسال الطلب للمراجعة'),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'ستراجع الإدارة طلبك قبل اعتماد التخصص الجديد.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title, required this.subtitle});

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
