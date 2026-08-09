import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../providers/bookings_provider.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  final LawyerProfile lawyer;
  final dynamic service;
  final bool isCustom;
  const CreateBookingPage({super.key, required this.lawyer, this.service, this.isCustom = false});
  @override ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
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

  @override void initState() { super.initState(); if (widget.service is LawyerService) _package = widget.service as LawyerService; }
  @override void dispose() { _descriptionController.dispose(); _customConsultationTypeController.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','png','docx'], withData: true);
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file?.bytes == null || !mounted) return;
    setState(() { _selectedFileBytes = file!.bytes; _selectedFileName = file.name; });
  }
  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  bool _validateCurrentStep() {
    if (_step == 0 && !widget.isCustom && _package == null) { _showMessage('يرجى اختيار باقة الاستشارة أولاً'); return false; }
    if (_step == 1 && widget.isCustom && _customConsultationTypeController.text.trim().isEmpty) { _showMessage('يرجى كتابة نوع الاستشارة'); return false; }
    if (_step == 2 && _selectedSlot == null) { _showMessage('يرجى اختيار موعد متاح فعليًا'); return false; }
    if (_step == 3 && ref.read(currentUserWhatsAppProvider).valueOrNull == null) { _showMessage('يجب إضافة رقم واتساب في الإعدادات قبل طلب الاستشارة'); return false; }
    return _step < 3 || (_formKey.currentState?.validate() ?? false);
  }
  void _next() { if (!_validateCurrentStep()) return; if (_step < 3) setState(() => _step++); else _submit(); }

  Future<void> _submit() async {
    final slot = _selectedSlot;
    final consultationType = widget.isCustom ? _customConsultationTypeController.text.trim() : _consultationType;
    final packageName = widget.isCustom ? 'استشارة مختلفة' : _package?.title;
    if (slot == null || packageName == null || consultationType.isEmpty || !(_formKey.currentState?.validate() ?? false)) return;
    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
      lawyerId: widget.lawyer.profileId, scheduledAt: slot.startsAt, slotId: slot.id, packageName: packageName,
      consultationType: consultationType, consultationMode: _consultationMode, description: _descriptionController.text.trim(),
      documentBytes: _selectedFileBytes, documentName: _selectedFileName,
    );
    if (!mounted) return;
    if (booking == null) { _showMessage(ref.read(bookingsControllerProvider).error?.toString().replaceFirst('Exception: ', '') ?? 'تعذر إنشاء الحجز'); return; }
    await context.push(_consultationMode == 'في المكتب' ? '/booking-details' : '/upload-payment', extra: booking);
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final slotsAsync = ref.watch(availableSlotsProvider(widget.lawyer.profileId));
    final user = ref.watch(authStateChangesProvider).value;
    final whatsappAsync = ref.watch(currentUserWhatsAppProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('حجز استشارة'), centerTitle: true),
      body: Form(key: _formKey, child: Stepper(
        currentStep: _step,
        onStepContinue: state.isLoading ? null : _next,
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(padding: const EdgeInsets.only(top: 20), child: Row(children: [
          Expanded(child: ElevatedButton(onPressed: details.onStepContinue, child: Text(_step == 3 ? 'إكمال الحجز' : 'متابعة'))),
          if (_step > 0) ...[const SizedBox(width: 10), TextButton(onPressed: details.onStepCancel, child: const Text('رجوع'))],
        ])),
        steps: [
          Step(title: const Text('اختيار الباقة'), isActive: _step >= 0, content: widget.isCustom
            ? Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF81C7F5).withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: const Text('استشارة مختلفة\nسيحدد المحامي السعر وفق نوع الطلب.'))
            : widget.lawyer.services.isEmpty ? const Text('لا توجد باقات متاحة لهذا المحامي.') : DropdownButtonFormField<LawyerService>(
              initialValue: _package, decoration: const InputDecoration(labelText: 'الباقة'),
              items: widget.lawyer.services.map((service) => DropdownMenuItem(value: service, child: Text('${service.title} — ${service.price} د.ع'))).toList(),
              onChanged: (value) => setState(() => _package = value), validator: (value) => value == null ? 'يرجى اختيار باقة الاستشارة' : null,
            )),
          Step(title: const Text('نوع الاستشارة وطريقة التنفيذ'), isActive: _step >= 1, content: Column(children: [
            widget.isCustom ? TextFormField(controller: _customConsultationTypeController, decoration: const InputDecoration(labelText: 'نوع الاستشارة', hintText: 'مثال: قضية تجارية'), validator: (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة نوع الاستشارة' : null)
            : DropdownButtonFormField<String>(initialValue: _consultationType, decoration: const InputDecoration(labelText: 'نوع الاستشارة'), items: const ['نصية','صوتية','فيديو'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _consultationType = v ?? 'نصية')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _consultationMode, decoration: const InputDecoration(labelText: 'طريقة التنفيذ'), items: const ['عن بعد','في المكتب'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _consultationMode = v ?? 'عن بعد')),
            if (_consultationMode == 'في المكتب') const Padding(padding: EdgeInsets.only(top: 10), child: Align(alignment: Alignment.centerRight, child: Text('الدفع في المكتب: يبقى الحجز معلقًا حتى يسجل المحامي المبلغ المستلم.', style: TextStyle(fontWeight: FontWeight.w600)))),
          ])),
          Step(title: const Text('اختيار الموعد المتاح فعليًا'), isActive: _step >= 2, content: slotsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()), error: (e, s) => Text('تعذر تحميل المواعيد المتاحة: $e'),
            data: (items) => items.isEmpty ? const Text('لا توجد مواعيد متاحة حاليًا لهذا المحامي.') : Wrap(spacing: 8, runSpacing: 8, children: items.map((slot) => ChoiceChip(label: Text('${slot.startsAt.day}/${slot.startsAt.month}  ${TimeOfDay.fromDateTime(slot.startsAt).format(context)}'), selected: _selectedSlot?.id == slot.id, onSelected: (_) => setState(() => _selectedSlot = slot))).toList()),
          )),
          Step(title: const Text('مراجعة الحجز'), isActive: _step >= 3, content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('المحامي: ${widget.lawyer.fullName ?? 'محامي'}'),
            Text('الباقة: ${widget.isCustom ? 'استشارة مختلفة' : (_package?.title ?? '-')}'),
            Text('نوع الاستشارة: ${widget.isCustom ? (_customConsultationTypeController.text.trim().isEmpty ? '-' : _customConsultationTypeController.text.trim()) : _consultationType}'),
            Text('طريقة التنفيذ: $_consultationMode'),
            Text('الموعد: ${_selectedSlot == null ? '-' : '${_selectedSlot!.startsAt.day}/${_selectedSlot!.startsAt.month}/${_selectedSlot!.startsAt.year} ${TimeOfDay.fromDateTime(_selectedSlot!.startsAt).format(context)}'}'),
            if (!widget.isCustom) Text('الرسوم: ${_package?.price ?? 0} د.ع'), Text('العميل: ${user?.fullName ?? 'المستخدم'}'),
            const SizedBox(height: 12),
            whatsappAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('تعذر تحميل رقم واتساب.'),
              data: (number) => TextFormField(
                initialValue: number ?? '', readOnly: true, keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'رقم واتساب للتواصل', prefixIcon: const Icon(Icons.chat_outlined), suffixIcon: number == null ? const Icon(Icons.error_outline, color: AppColors.error) : const Icon(Icons.check_circle, color: Colors.green), helperText: number == null ? 'أضف رقم واتساب من الإعدادات قبل إرسال الطلب.' : 'سيتم حفظ هذا الرقم مع طلب الاستشارة.'),
                validator: (v) => v == null || v.trim().isEmpty ? 'رقم واتساب مطلوب' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'تفاصيل الموضوع'), validator: (v) => v == null || v.trim().isEmpty ? 'تفاصيل الموضوع مطلوبة' : null),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file), label: Text(_selectedFileName ?? 'إرفاق مستند (اختياري)')),
            const SizedBox(height: 12),
            Text(_consultationMode == 'في المكتب' ? 'بعد إرسال الطلب سيظهر للمحامي لتسجيل المبلغ المستلم يدويًا قبل بدء الاستشارة.' : 'بعد إكمال الحجز ستفتح صفحة الدفع مباشرة.'),
          ])),
        ],
      )),
    );
  }
}
