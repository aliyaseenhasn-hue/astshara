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
  final _customTypeController = TextEditingController();

  int _step = 0;
  LawyerService? _package;
  String _consultationType = 'نصية';
  String _consultationMode = 'عن بعد';
  AvailableBookingSlot? _selectedSlot;
  Uint8List? _fileBytes;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    if (widget.service is LawyerService) {
      _package = widget.service as LawyerService;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'png', 'docx'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
    });
  }

  bool _validateCurrentStep() {
    if (_step == 0 && !widget.isCustom && _package == null) {
      _showMessage('يرجى اختيار باقة الاستشارة أولاً');
      return false;
    }
    if (_step == 1) {
      if (widget.isCustom && _customTypeController.text.trim().isEmpty) {
        _showMessage('يرجى كتابة نوع الاستشارة');
        return false;
      }
      if (!(_formKey.currentState?.validate() ?? false)) return false;
    }
    if (_step == 2 && _selectedSlot == null) {
      _showMessage('يرجى اختيار موعد متاح');
      return false;
    }
    if (_step == 3 && ref.read(currentUserWhatsAppProvider).valueOrNull == null) {
      _showMessage('أضف رقم واتساب من الإعدادات قبل طلب الاستشارة');
      return false;
    }
    return true;
  }

  void _continue() {
    if (!_validateCurrentStep()) return;
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final slot = _selectedSlot;
    final type = widget.isCustom ? _customTypeController.text.trim() : _consultationType;
    final packageName = widget.isCustom ? 'استشارة مختلفة' : _package?.title;
    if (slot == null || packageName == null || type.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
      lawyerId: widget.lawyer.profileId,
      scheduledAt: slot.startsAt,
      slotId: slot.id,
      packageName: packageName,
      consultationType: type,
      consultationMode: _consultationMode,
      description: _descriptionController.text.trim(),
      documentBytes: _fileBytes,
      documentName: _fileName,
    );

    if (!mounted) return;
    if (booking == null) {
      final error = ref.read(bookingsControllerProvider).error;
      _showMessage(error?.toString().replaceFirst('Exception: ', '') ?? 'تعذر إنشاء الحجز');
      return;
    }

    await context.push(
      _consultationMode == 'في المكتب' ? '/booking-details' : '/upload-payment',
      extra: booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(bookingsControllerProvider);
    final slots = ref.watch(availableSlotsProvider(widget.lawyer.profileId));
    final user = ref.watch(authStateChangesProvider).value;
    final whatsapp = ref.watch(currentUserWhatsAppProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('طلب استشارة'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProgressHeader(step: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _LawyerSummary(lawyer: widget.lawyer),
                    const SizedBox(height: 16),
                    _buildStep(slots, user, whatsapp),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Material(
              color: AppColors.surface,
              elevation: 12,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _BottomActions(
                  step: _step,
                  loading: state.isLoading,
                  onContinue: _continue,
                  onBack: _step == 0 ? null : () => setState(() => _step -= 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    AsyncValue<List<AvailableBookingSlot>> slots,
    dynamic user,
    AsyncValue<String?> whatsapp,
  ) {
    if (_step == 0) {
      if (widget.isCustom) {
        return const _StepCard(
          title: 'نوع الاستشارة',
          subtitle: 'سيحدد المحامي السعر بعد مراجعة الطلب.',
          icon: Icons.edit_note_rounded,
          child: _InfoBox(icon: Icons.info_outline_rounded, title: 'استشارة مختلفة', text: 'يمكنك متابعة الطلب وتحديد التفاصيل في الخطوة التالية.'),
        );
      }
      if (widget.lawyer.services.isEmpty) {
        return const _StepCard(
          title: 'الباقات',
          subtitle: 'لا توجد باقات متاحة حالياً.',
          icon: Icons.workspace_premium_outlined,
          child: _InfoBox(icon: Icons.info_outline_rounded, title: 'لا توجد باقات', text: 'لا توجد خدمة متاحة لهذا المحامي حالياً.'),
        );
      }
      return _StepCard(
        title: 'اختر الباقة المناسبة',
        subtitle: 'حدد الخدمة التي تريد طلبها من المحامي.',
        icon: Icons.workspace_premium_outlined,
        child: Column(
          children: widget.lawyer.services.map((service) => _SelectablePackage(
            service: service,
            selected: _package == service,
            onTap: () => setState(() => _package = service),
          )).toList(),
        ),
      );
    }

    if (_step == 1) {
      return _StepCard(
        title: 'نوع الاستشارة',
        subtitle: 'حدد طريقة التواصل وطريقة تنفيذ الموعد.',
        icon: Icons.forum_outlined,
        child: Column(
          children: [
            if (widget.isCustom)
              TextFormField(
                controller: _customTypeController,
                decoration: const InputDecoration(labelText: 'نوع الاستشارة', hintText: 'اكتب نوع الاستشارة المطلوبة'),
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              )
            else
              _SelectField<String>(
                label: 'نوع الاستشارة',
                value: _consultationType,
                items: const ['نصية', 'صوتية', 'فيديو'],
                icon: Icons.chat_bubble_outline_rounded,
                onChanged: (value) => setState(() => _consultationType = value),
              ),
            const SizedBox(height: 14),
            _SelectField<String>(
              label: 'طريقة التنفيذ',
              value: _consultationMode,
              items: const ['عن بعد', 'في المكتب'],
              icon: Icons.video_call_outlined,
              onChanged: (value) => setState(() => _consultationMode = value),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'وصف الطلب', hintText: 'اكتب تفاصيل مختصرة عن استشارتك'),
              validator: (value) => value == null || value.trim().isEmpty ? 'اكتب وصفاً مختصراً للطلب' : null,
            ),
          ],
        ),
      );
    }

    if (_step == 2) {
      return _StepCard(
        title: 'اختر الموعد',
        subtitle: 'اختر وقتاً متاحاً من جدول المحامي.',
        icon: Icons.calendar_month_outlined,
        child: slots.when(
          data: (items) => items.isEmpty
              ? const _InfoBox(icon: Icons.event_busy_outlined, title: 'لا توجد مواعيد متاحة', text: 'جرّب العودة لاحقاً.')
              : Column(children: items.map((slot) => _SelectableSlot(
                  slot: slot,
                  selected: _selectedSlot?.id == slot.id,
                  onTap: () => setState(() => _selectedSlot = slot),
                )).toList()),
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (error, _) => _InfoBox(icon: Icons.error_outline_rounded, title: 'تعذر تحميل المواعيد', text: '$error'),
        ),
      );
    }

    return _StepCard(
      title: 'المراجعة والتأكيد',
      subtitle: 'راجع البيانات قبل إرسال طلب الاستشارة.',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReviewRow(label: 'المحامي', value: widget.lawyer.fullName ?? 'محامي'),
          _ReviewRow(label: 'الباقة', value: widget.isCustom ? 'استشارة مختلفة' : (_package?.title ?? 'غير محددة')),
          _ReviewRow(label: 'نوع الاستشارة', value: widget.isCustom ? _customTypeController.text.trim() : _consultationType),
          _ReviewRow(label: 'طريقة التنفيذ', value: _consultationMode),
          if (_selectedSlot != null) _ReviewRow(label: 'الموعد', value: _formatSlot(_selectedSlot!)),
          const SizedBox(height: 10),
          Text('رقم واتساب: ${whatsapp.valueOrNull ?? 'غير مضاف'}'),
          if (user?.fullName != null) Text('العميل: ${user.fullName}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(_fileName ?? 'إرفاق مستند (اختياري)'),
          ),
        ],
      ),
    );
  }

  String _formatSlot(AvailableBookingSlot slot) {
    final date = '${slot.startsAt.day}/${slot.startsAt.month}/${slot.startsAt.year}';
    final time = TimeOfDay.fromDateTime(slot.startsAt).format(context);
    return '$date $time';
  }
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  const _ProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: List.generate(4, (index) {
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
                if (index < 3)
                  Expanded(child: Divider(color: index < step ? AppColors.ctaGold : scheme.outlineVariant)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lawyer.fullName ?? 'محامي', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(lawyer.specializations.isEmpty ? 'استشارات قانونية' : lawyer.specializations.take(2).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${lawyer.rating.toStringAsFixed(1)} ★  •  ${lawyer.reviewCount} مراجعة'),
              ],
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [CircleAvatar(radius: 20, backgroundColor: AppColors.primaryContainer, foregroundColor: AppColors.goldLight, child: Icon(icon)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 3), Text(subtitle)]))]),
          const SizedBox(height: 18),
          child,
        ],
      ),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.teal), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(text)]))]),
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
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer.withValues(alpha: 0.08) : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.ctaGold : scheme.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.ctaGold : scheme.onSurfaceVariant), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(service.title, style: const TextStyle(fontWeight: FontWeight.w800)), if (service.description?.isNotEmpty == true) Text(service.description!, maxLines: 2, overflow: TextOverflow.ellipsis)])), const SizedBox(width: 8), Text('${service.price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.w800))]),
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
      onChanged: (next) { if (next != null) onChanged(next); },
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
    final date = '${slot.startsAt.day}/${slot.startsAt.month}/${slot.startsAt.year}';
    final time = TimeOfDay.fromDateTime(slot.startsAt).format(context);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [SizedBox(width: 105, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)))]),
    );
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
    return Row(
      children: [
        if (onBack != null) ...[
          SizedBox(width: 54, height: 52, child: OutlinedButton(onPressed: loading ? null : onBack, child: const Icon(Icons.arrow_back_rounded))),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: loading ? null : onContinue,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(last ? 'إرسال طلب الاستشارة' : 'متابعة', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
