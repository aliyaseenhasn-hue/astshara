import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../providers/bookings_provider.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  final LawyerProfile lawyer;
  final dynamic service;
  final bool isCustom;

  const CreateBookingPage({super.key, required this.lawyer, this.service, this.isCustom = false});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _customConsultationTypeController = TextEditingController();
  int _step = 0;
  LawyerService? _package;
  String _consultationType = 'نصية';
  String _consultationMode = 'عن بعد';
  AvailableBookingSlot? _selectedSlot;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.service is LawyerService) _package = widget.service as LawyerService;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customConsultationTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png', 'docx'], withData: true);
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file?.bytes == null || !mounted) return;
    setState(() {
      _selectedFileBytes = file!.bytes;
      _selectedFileName = file.name;
    });
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  bool _validateStep() {
    if (_step == 0 && !widget.isCustom && _package == null) {
      _message('يرجى اختيار باقة الاستشارة أولاً');
      return false;
    }
    if (_step == 1 && widget.isCustom && _customConsultationTypeController.text.trim().isEmpty) {
      _message('يرجى كتابة نوع الاستشارة');
      return false;
    }
    if (_step == 2 && _selectedSlot == null) {
      _message('يرجى اختيار موعد متاح فعلياً');
      return false;
    }
    if (_step == 3 && ref.read(currentUserWhatsAppProvider).valueOrNull == null) {
      _message('أضف رقم واتساب من الإعدادات قبل طلب الاستشارة');
      return false;
    }
    return _step < 3 || (_formKey.currentState?.validate() ?? false);
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final slot = _selectedSlot;
    final consultationType = widget.isCustom ? _customConsultationTypeController.text.trim() : _consultationType;
    final packageName = widget.isCustom ? 'استشارة مختلفة' : _package?.title;
    if (slot == null || packageName == null || consultationType.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
      lawyerId: widget.lawyer.profileId,
      scheduledAt: slot.startsAt,
      slotId: slot.id,
      packageName: packageName,
      consultationType: consultationType,
      consultationMode: _consultationMode,
      description: _descriptionController.text.trim(),
      documentBytes: _selectedFileBytes,
      documentName: _selectedFileName,
    );
    if (!mounted) return;
    if (booking == null) {
      _message(ref.read(bookingsControllerProvider).error?.toString().replaceFirst('Exception: ', '') ?? 'تعذر إنشاء الحجز');
      return;
    }
    await context.push(_consultationMode == 'في المكتب' ? '/booking-details' : '/upload-payment', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(bookingsControllerProvider);
    final slotsAsync = ref.watch(availableSlotsProvider(widget.lawyer.profileId));
    final user = ref.watch(authStateChangesProvider).value;
    final whatsappAsync = ref.watch(currentUserWhatsAppProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('طلب استشارة'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProgressHeader(step: _step, dark: dark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    _LawyerSummary(lawyer: widget.lawyer),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(key: ValueKey(_step), child: _stepContent(scheme, slotsAsync, user, whatsappAsync)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 82,
              child: Material(
                color: AppColors.surface,
                elevation: 8,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _BottomActions(step: _step, loading: state.isLoading, onContinue: _next, onBack: _step == 0 ? null : () => setState(() => _step--)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent(ColorScheme scheme, AsyncValue<List<AvailableBookingSlot>> slotsAsync, dynamic user, AsyncValue<String?> whatsappAsync) {
    switch (_step) {
      case 0:
        return _StepCard(
          title: 'اختر الباقة المناسبة',
          subtitle: 'حدد الخدمة التي تريد طلبها من المحامي.',
          icon: Icons.workspace_premium_outlined,
          child: widget.isCustom
              ? const _InfoBox(icon: Icons.edit_note_rounded, title: 'استشارة مختلفة', text: 'سيحدد المحامي السعر وفق نوع الطلب بعد مراجعته.')
              : widget.lawyer.services.isEmpty
                  ? const _InfoBox(icon: Icons.info_outline_rounded, title: 'لا توجد باقات متاحة', text: 'يمكنك العودة إلى ملف المحامي لاحقاً أو اختيار محامٍ آخر.')
                  : Column(children: widget.lawyer.services.map((service) => _SelectablePackage(service: service, selected: _package == service, onTap: () => setState(() => _package = service))).toList()),
        );
      case 1:
        return _StepCard(
          title: 'نوع الاستشارة',
          subtitle: 'حدد طريقة التواصل وطريقة تنفيذ الموعد.',
          icon: Icons.forum_outlined,
          child: Column(
            children: [
              if (widget.isCustom)
                TextFormField(
                  controller: _customConsultationTypeController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'نوع الاستشارة', hintText: 'اكتب نوع الاستشارة المطلوبة', prefixIcon: Icon(Icons.edit_note_rounded)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                )
              else
                _SelectField<String>(label: 'نوع الاستشارة', value: _consultationType, items: const ['نصية', 'صوتية', 'فيديو'], icon: Icons.chat_bubble_outline_rounded, onChanged: (value) => setState(() => _consultationType = value)),
              const SizedBox(height: 14),
              _SelectField<String>(label: 'طريقة الموعد', value: _consultationMode, items: const ['عن بعد', 'في المكتب'], icon: _consultationMode == 'في المكتب' ? Icons.business_outlined : Icons.videocam_outlined, onChanged: (value) => setState(() => _consultationMode = value)),
              const SizedBox(height: 14),
              TextFormField(controller: _descriptionController, maxLines: 5, decoration: const InputDecoration(labelText: 'وصف الطلب', hintText: 'اكتب تفاصيل مختصرة عن استشارتك'), validator: (value) => value == null || value.trim().isEmpty ? 'اكتب وصفاً مختصراً للطلب' : null),
            ],
          ),
        );
      case 2:
        return _StepCard(
          title: 'اختر الموعد',
          subtitle: 'اختر وقتاً متاحاً من جدول المحامي.',
          icon: Icons.calendar_month_outlined,
          child: slotsAsync.when(
            data: (slots) {
              if (slots.isEmpty) return const _InfoBox(icon: Icons.event_busy_outlined, title: 'لا توجد مواعيد متاحة', text: 'جرّب العودة لاحقاً.');
              return Column(children: slots.map((slot) => _SelectableSlot(slot: slot, selected: _selectedSlot?.id == slot.id, onTap: () => setState(() => _selectedSlot = slot))).toList());
            },
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (error, _) => _InfoBox(icon: Icons.error_outline_rounded, title: 'تعذر تحميل المواعيد', text: '$error'),
          ),
        );
      case 3:
        return _StepCard(
          title: 'المراجعة والتأكيد',
          subtitle: 'راجع البيانات قبل إرسال طلب الاستشارة.',
          icon: Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(label: 'المحامي', value: widget.lawyer.fullName ?? 'محامي'),
              _ReviewRow(label: 'الباقة', value: widget.isCustom ? 'استشارة مختلفة' : (_package?.title ?? 'غير محددة')),
              _ReviewRow(label: 'نوع الاستشارة', value: widget.isCustom ? _customConsultationTypeController.text.trim() : _consultationType),
              _ReviewRow(label: 'طريقة الموعد', value: _consultationMode),
              if (_selectedSlot != null) _ReviewRow(label: 'الموعد', value: _formatSlot(_selectedSlot!)),
              const SizedBox(height: 12),
              Text('رقم واتساب: ${whatsappAsync.valueOrNull ?? 'غير مضاف'}'),
              if (user?.fullName != null) ...[
                const SizedBox(height: 8),
                Text('العميل: ${user.fullName}'),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file_rounded), label: Text(_selectedFileName ?? 'إرفاق مستند (اختياري)')),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatSlot(AvailableBookingSlot slot) => '${slot.startsAt.day}/${slot.startsAt.month}/${slot.startsAt.year} ${TimeOfDay.fromDateTime(slot.startsAt).format(context)}';
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final bool dark;
  const _ProgressHeader({required this.step, required this.dark});

  @override
  Widget build(BuildContext context) {
    const labels = ['الباقة', 'التفاصيل', 'الموعد', 'التأكيد'];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active ? AppColors.ctaGold : scheme.surfaceContainerHighest,
                  foregroundColor: active ? AppColors.primary : scheme.onSurfaceVariant,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 5),
                Expanded(child: Text(labels[index], style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? scheme.onSurface : scheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                if (index < labels.length - 1) Expanded(child: Divider(color: index < step ? AppColors.ctaGold : scheme.outlineVariant)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LawyerSummary extends StatelessWidget {
  final LawyerProfile lawyer;
  const _LawyerSummary({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: lawyer.avatarUrl == null ? null : NetworkImage(lawyer.avatarUrl!),
            child: lawyer.avatarUrl == null ? const Icon(Icons.person_outline_rounded) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lawyer.fullName ?? 'محامي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(lawyer.specializations.isEmpty ? 'استشارات قانونية' : lawyer.specializations.take(2).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 5),
              Row(children: [const Icon(Icons.star_rounded, size: 16, color: AppColors.ctaGold), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1)), const SizedBox(width: 8), Text('${lawyer.reviewCount} مراجعة', style: Theme.of(context).textTheme.bodySmall)]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _StepCard({required this.title, required this.subtitle, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [CircleAvatar(radius: 20, backgroundColor: AppColors.primaryContainer, foregroundColor: AppColors.goldLight, child: Icon(icon, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)]))]),
        const SizedBox(height: 18),
        child,
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoBox({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.outlineVariant)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.teal), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(text, style: Theme.of(context).textTheme.bodySmall)]))]),
    );
  }
}

class _SelectablePackage extends StatelessWidget {
  final LawyerService service;
  final bool selected;
  final VoidCallback onTap;
  const _SelectablePackage({required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: selected ? AppColors.primaryContainer.withValues(alpha: 0.08) : scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.ctaGold : scheme.outlineVariant, width: selected ? 1.5 : 1)),
        child: Row(children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.ctaGold : scheme.onSurfaceVariant), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(service.title, style: const TextStyle(fontWeight: FontWeight.w800)), if (service.description?.isNotEmpty == true) ...[const SizedBox(height: 3), Text(service.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)]])), const SizedBox(width: 8), Text('${service.price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.w800))]),
      ),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T> onChanged;
  const _SelectField({required this.label, required this.value, required this.items, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text('$item'))).toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _SelectableSlot extends StatelessWidget {
  final AvailableBookingSlot slot;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableSlot({required this.slot, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(slot.startsAt).format(context);
    final date = '${slot.startsAt.day}/${slot.startsAt.month}/${slot.startsAt.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: selected ? AppColors.primaryContainer.withValues(alpha: 0.08) : scheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.ctaGold : scheme.outlineVariant, width: selected ? 1.5 : 1)),
        child: Row(children: [Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? AppColors.ctaGold : scheme.onSurfaceVariant), const SizedBox(width: 10), Expanded(child: Text(date, style: const TextStyle(fontWeight: FontWeight.w700))), Text(time, style: const TextStyle(fontWeight: FontWeight.w800))]),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 105, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)))]));
  }
}

class _BottomActions extends StatelessWidget {
  final int step;
  final bool loading;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  const _BottomActions({required this.step, required this.loading, required this.onContinue, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final last = step == 3;
    return Row(children: [
      if (onBack != null) ...[SizedBox(width: 54, height: 52, child: OutlinedButton(onPressed: loading ? null : onBack, child: const Icon(Icons.arrow_back_rounded))), const SizedBox(width: 10)],
      Expanded(child: SizedBox(height: 52, child: FilledButton.icon(onPressed: loading ? null : onContinue, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded), label: Text(last ? 'إرسال طلب الاستشارة' : 'متابعة')))),
    ]);
  }
}
