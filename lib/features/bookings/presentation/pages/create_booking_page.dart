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
    setState(() { _selectedFileBytes = file!.bytes; _selectedFileName = file.name; });
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  bool _validateStep() {
    if (_step == 0 && !widget.isCustom && _package == null) { _message('يرجى اختيار باقة الاستشارة أولاً'); return false; }
    if (_step == 1 && widget.isCustom && _customConsultationTypeController.text.trim().isEmpty) { _message('يرجى كتابة نوع الاستشارة'); return false; }
    if (_step == 2 && _selectedSlot == null) { _message('يرجى اختيار موعد متاح فعلياً'); return false; }
    if (_step == 3 && ref.read(currentUserWhatsAppProvider).valueOrNull == null) { _message('أضف رقم واتساب من الإعدادات قبل طلب الاستشارة'); return false; }
    return _step < 3 || (_formKey.currentState?.validate() ?? false);
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 3) setState(() => _step++); else _submit();
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
      appBar: AppBar(title: const Text('طلب استشارة'), leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded))),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProgressHeader(step: _step, dark: dark),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), child: Column(children: [
              _LawyerSummary(lawyer: widget.lawyer),
              const SizedBox(height: 18),
              AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(_step), child: _stepContent(scheme, slotsAsync, user, whatsappAsync))),
            ]))),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(step: _step, loading: state.isLoading, onContinue: _next, onBack: _step == 0 ? null : () => setState(() => _step--)),
    );
  }

  Widget _stepContent(ColorScheme scheme, AsyncValue<List<AvailableBookingSlot>> slotsAsync, dynamic user, AsyncValue<String?> whatsappAsync) {
    switch (_step) {
      case 0:
        return _StepCard(title: 'اختر الباقة المناسبة', subtitle: 'حدد الخدمة التي تريد طلبها من المحامي.', icon: Icons.workspace_premium_outlined, child: widget.isCustom ? const _InfoBox(icon: Icons.edit_note_rounded, title: 'استشارة مختلفة', text: 'سيحدد المحامي السعر وفق نوع الطلب بعد مراجعته.') : widget.lawyer.services.isEmpty ? const _InfoBox(icon: Icons.info_outline_rounded, title: 'لا توجد باقات متاحة', text: 'يمكنك العودة إلى ملف المحامي لاحقاً أو اختيار محامٍ آخر.') : Column(children: widget.lawyer.services.map((service) => _SelectablePackage(service: service, selected: _package == service, onTap: () => setState(() => _package = service))).toList()));
      case 1:
        return _StepCard(title: 'نوع الاستشارة', subtitle: 'حدد طريقة التواصل وطريقة تنفيذ الموعد.', icon: Icons.forum_outlined, child: Column(children: [
          if (widget.isCustom) TextFormField(controller: _customConsultationTypeController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'نوع الاستشارة', hintText: 'مثال: قضية تجارية أو صياغة عقد', prefixIcon: Icon(Icons.edit_note_rounded)), validator: (value) => value == null || value.trim().isEmpty ? 'يرجى كتابة نوع الاستشارة' : null)
          else _SelectField<String>(label: 'نوع الاستشارة', value: _consultationType, items: const ['نصية', 'صوتية', 'فيديو'], icon: Icons.chat_bubble_outline_rounded, onChanged: (value) => setState(() => _consultationType = value)),
          const SizedBox(height: 14),
          _SelectField<String>(label: 'طريقة التنفيذ', value: _consultationMode, items: const ['عن بعد', 'في المكتب'], icon: _consultationMode == 'في المكتب' ? Icons.business_outlined : Icons.videocam_outlined, onChanged: (value) => setState(() => _consultationMode = value)),
          if (_consultationMode == 'في المكتب') ...[const SizedBox(height: 12), const _InfoBox(icon: Icons.payments_outlined, title: 'الدفع في المكتب', text: 'يبقى الحجز معلقاً حتى يسجل المحامي المبلغ المستلم. لن يبدأ رقم التواصل بالظهور قبل تأكيد الحجز.')],
        ]));
      case 2:
        return _StepCard(title: 'اختر موعداً متاحاً', subtitle: 'المواعيد المعروضة مأخوذة من جدول المحامي الفعلي.', icon: Icons.calendar_month_outlined, child: slotsAsync.when(loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())), error: (error, _) => _InfoBox(icon: Icons.error_outline_rounded, title: 'تعذر تحميل المواعيد', text: error.toString()), data: (items) => items.isEmpty ? const _InfoBox(icon: Icons.event_busy_outlined, title: 'لا توجد مواعيد متاحة حالياً', text: 'يمكنك العودة لاحقاً أو اختيار محامٍ آخر.') : Wrap(spacing: 10, runSpacing: 10, children: items.map((slot) => _SlotChip(slot: slot, selected: _selectedSlot?.id == slot.id, onTap: () => setState(() => _selectedSlot = slot))).toList())));
      default:
        return _StepCard(title: 'راجع طلبك', subtitle: 'تأكد من التفاصيل قبل إرسال الطلب.', icon: Icons.fact_check_outlined, child: Column(children: [
          _ReviewRow(label: 'المحامي', value: widget.lawyer.fullName ?? 'محامي'),
          _ReviewRow(label: 'الباقة', value: widget.isCustom ? 'استشارة مختلفة' : (_package?.title ?? '-')),
          _ReviewRow(label: 'نوع الاستشارة', value: widget.isCustom ? (_customConsultationTypeController.text.trim().isEmpty ? '-' : _customConsultationTypeController.text.trim()) : _consultationType),
          _ReviewRow(label: 'طريقة التنفيذ', value: _consultationMode),
          _ReviewRow(label: 'الموعد', value: _selectedSlot == null ? '-' : '${_selectedSlot!.startsAt.day}/${_selectedSlot!.startsAt.month}/${_selectedSlot!.startsAt.year}  ${TimeOfDay.fromDateTime(_selectedSlot!.startsAt).format(context)}'),
          if (!widget.isCustom) _ReviewRow(label: 'الرسوم', value: '${_package?.price ?? 0} د.ع'),
          if (user?.fullName != null) _ReviewRow(label: 'العميل', value: user.fullName),
          const SizedBox(height: 14),
          whatsappAsync.when(loading: () => const LinearProgressIndicator(), error: (_, __) => const _InfoBox(icon: Icons.warning_amber_rounded, title: 'تعذر تحميل رقم واتساب', text: 'أعد المحاولة بعد التأكد من حفظ رقمك في الإعدادات.'), data: (number) => TextFormField(initialValue: number ?? '', readOnly: true, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'رقم واتساب للتواصل', prefixIcon: const Icon(Icons.chat_outlined), suffixIcon: number == null ? const Icon(Icons.error_outline, color: AppColors.error) : const Icon(Icons.check_circle, color: AppColors.success), helperText: number == null ? 'أضف رقم واتساب من الإعدادات قبل إرسال الطلب.' : 'سيتم حفظ الرقم مع طلب الاستشارة.'), validator: (value) => value == null || value.trim().isEmpty ? 'رقم واتساب مطلوب' : null)),
          const SizedBox(height: 14),
          TextFormField(controller: _descriptionController, maxLines: 4, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'تفاصيل الموضوع', hintText: 'اكتب ملخصاً واضحاً لموضوع الاستشارة...', prefixIcon: Icon(Icons.notes_rounded), alignLabelWithHint: true), validator: (value) => value == null || value.trim().isEmpty ? 'تفاصيل الموضوع مطلوبة' : null),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file_rounded), label: Text(_selectedFileName ?? 'إرفاق مستند اختياري')),
          if (_selectedFileName != null) ...[const SizedBox(height: 7), Align(alignment: Alignment.centerRight, child: Text('تم اختيار: $_selectedFileName', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)))],
          const SizedBox(height: 12),
          _InfoBox(icon: _consultationMode == 'في المكتب' ? Icons.storefront_outlined : Icons.lock_outline_rounded, title: 'بعد الإرسال', text: _consultationMode == 'في المكتب' ? 'سيظهر الطلب للمحامي لتسجيل المبلغ المستلم يدوياً قبل بدء الاستشارة.' : 'بعد إنشاء الطلب ستنتقل مباشرة إلى صفحة الدفع، ولن تظهر بيانات التواصل قبل تأكيد الحجز.'),
        ]));
    }
  }
}

class _ProgressHeader extends StatelessWidget { final int step; final bool dark; const _ProgressHeader({required this.step, required this.dark}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 10), child: Row(textDirection: TextDirection.rtl, children: List.generate(4, (index) { final active = index <= step; return Expanded(child: Row(children: [Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.ctaGold : AppColors.surfaceContainerHighest, border: Border.all(color: active ? Colors.transparent : AppColors.outlineVariant)), child: Text('${index + 1}', style: TextStyle(color: active ? AppColors.primary : AppColors.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))), if (index < 3) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 6), color: index < step ? AppColors.ctaGold : AppColors.outlineVariant))])); }))); }

class _LawyerSummary extends StatelessWidget { final LawyerProfile lawyer; const _LawyerSummary({required this.lawyer}); @override Widget build(BuildContext context) { final avatar = lawyer.avatarUrl; final hasAvatar = avatar != null && avatar.isNotEmpty; return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)), child: Row(textDirection: TextDirection.rtl, children: [Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerLow, border: Border.all(color: AppColors.ctaGold, width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: hasAvatar ? null : const Icon(Icons.person_rounded, color: AppColors.onSurfaceVariant, size: 30)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(mainAxisAlignment: MainAxisAlignment.end, children: [Flexible(child: Text(lawyer.fullName ?? 'محامي', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.onSurface, fontSize: 17, fontWeight: FontWeight.w600))), if (lawyer.verified) ...[const SizedBox(width: 5), const Icon(Icons.verified_rounded, color: AppColors.ctaGold, size: 17)]]), const SizedBox(height: 3), Text(lawyer.specializations.isEmpty ? 'محامي ومستشار قانوني' : lawyer.specializations.take(2).join('، '), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12))]))]); } }

class _StepCard extends StatelessWidget { final String title; final String subtitle; final IconData icon; final Widget child; const _StepCard({required this.title, required this.subtitle, required this.icon, required this.child}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.outlineVariant), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .04), blurRadius: 20, offset: const Offset(0, 7))]), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(textDirection: TextDirection.rtl, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tertiaryLight.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.tertiaryLight)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(title, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurface, fontSize: 20, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.45))]))]), const SizedBox(height: 20), child])); }

class _SelectablePackage extends StatelessWidget { final LawyerService service; final bool selected; final VoidCallback onTap; const _SelectablePackage({required this.service, required this.selected, required this.onTap}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Ink(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? AppColors.secondaryContainer.withValues(alpha: .30) : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.ctaGold : AppColors.outlineVariant, width: selected ? 1.5 : 1)), child: Row(textDirection: TextDirection.rtl, children: [Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? AppColors.secondaryDark : AppColors.onSurfaceVariant), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(service.title, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600)), if (service.description?.isNotEmpty == true) ...[const SizedBox(height: 3), Text(service.description!, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12))]])), const SizedBox(width: 10), Text('${service.price.toStringAsFixed(0)} د.ع', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))]))))); }

class _SelectField<T> extends StatelessWidget { final String label; final T value; final List<T> items; final IconData icon; final ValueChanged<T> onChanged; const _SelectField({required this.label, required this.value, required this.items, required this.icon, required this.onChanged}); @override Widget build(BuildContext context) => DropdownButtonFormField<T>(initialValue: value, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)), items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(), onChanged: (value) { if (value != null) onChanged(value); }); }

class _SlotChip extends StatelessWidget { final AvailableBookingSlot slot; final bool selected; final VoidCallback onTap; const _SlotChip({required this.slot, required this.selected, required this.onTap}); @override Widget build(BuildContext context) { final dt = slot.startsAt; return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), decoration: BoxDecoration(color: selected ? AppColors.secondaryContainer : AppColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? AppColors.ctaGold : AppColors.outlineVariant)), child: Text('${dt.day}/${dt.month} • ${TimeOfDay.fromDateTime(dt).format(context)}', style: TextStyle(color: selected ? AppColors.primary : AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 13)))); } }

class _ReviewRow extends StatelessWidget { final String label; final String value; const _ReviewRow({required this.label, required this.value}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(textDirection: TextDirection.rtl, crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 108, child: Text(label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13))), const SizedBox(width: 10), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)))])); }

class _InfoBox extends StatelessWidget { final IconData icon; final String title; final String text; const _InfoBox({required this.icon, required this.title, required this.text}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant)), child: Row(textDirection: TextDirection.rtl, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.tertiaryLight, size: 21), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(title, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 3), Text(text, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.5))]))])); }

class _BottomActions extends StatelessWidget {
  final int step;
  final bool loading;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  const _BottomActions({required this.step, required this.loading, required this.onContinue, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1))),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaGold,
                    foregroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.ctaGold.withValues(alpha: 0.45),
                    disabledForegroundColor: AppColors.primary.withValues(alpha: 0.55),
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: Icon(step == 3 ? Icons.check_circle_outline_rounded : Icons.arrow_back_rounded, size: 21),
                  label: Text(step == 3 ? 'إرسال طلب الاستشارة' : 'متابعة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              if (onBack != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: loading ? null : onBack,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface, side: BorderSide(color: AppColors.outlineVariant, width: 1.2), padding: const EdgeInsets.symmetric(horizontal: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('رجوع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
