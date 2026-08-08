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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      withData: true,
    );
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file?.bytes == null || !mounted) return;
    setState(() {
      _selectedFileBytes = file!.bytes;
      _selectedFileName = file.name;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateCurrentStep() {
    if (_step == 0 && !widget.isCustom && _package == null) {
      _showMessage('يرجى اختيار باقة الاستشارة أولاً');
      return false;
    }
    if (_step == 1 && widget.isCustom && _customConsultationTypeController.text.trim().isEmpty) {
      _showMessage('يرجى كتابة نوع الاستشارة');
      return false;
    }
    if (_step == 2 && _selectedSlot == null) {
      _showMessage('يرجى اختيار موعد متاح فعليًا');
      return false;
    }
    return _step < 3 || (_formKey.currentState?.validate() ?? false);
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final slot = _selectedSlot;
    final consultationType = widget.isCustom
        ? _customConsultationTypeController.text.trim()
        : _consultationType;
    final packageName = widget.isCustom ? 'استشارة مختلفة' : _package?.title;

    if (slot == null || packageName == null || consultationType.isEmpty || !(_formKey.currentState?.validate() ?? false)) return;

    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
      lawyerId: widget.lawyer.profileId,
      scheduledAt: slot.startsAt,
      slotId: slot.id,
      packageName: packageName,
      consultationType: consultationType,
      description: _descriptionController.text.trim(),
      documentBytes: _selectedFileBytes,
      documentName: _selectedFileName,
    );

    if (!mounted) return;
    if (booking == null) {
      _showMessage(ref.read(bookingsControllerProvider).error?.toString() ?? 'تعذر إنشاء الحجز');
      return;
    }

    // استخدم push بدل go حتى يبقى المستخدم داخل تدفق الحجز ويفتح الدفع مباشرة.
    await context.push('/upload-payment', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final slotsAsync = ref.watch(availableSlotsProvider(widget.lawyer.profileId));
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('حجز استشارة'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: state.isLoading ? null : _next,
          onStepCancel: _step == 0 ? null : () => setState(() => _step--),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_step == 3 ? 'إكمال الحجز والدفع' : 'متابعة'),
                ),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 10),
                TextButton(onPressed: details.onStepCancel, child: const Text('رجوع')),
              ],
            ]),
          ),
          steps: [
            Step(
              title: const Text('اختيار الباقة'),
              isActive: _step >= 0,
              content: widget.isCustom
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C7F5).withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('استشارة مختلفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('لا تحتاج هذه الاستشارة إلى اختيار كارت. اكتب نوع القضية والتفاصيل في الخطوة التالية، وسيتم إرسال الطلب إلى المحامي للمراجعة.'),
                        ],
                      ),
                    )
                  : widget.lawyer.services.isEmpty
                      ? const Text('لا توجد باقات متاحة لهذا المحامي.')
                      : DropdownButtonFormField<LawyerService>(
                          value: _package,
                          decoration: const InputDecoration(labelText: 'الباقة'),
                          items: widget.lawyer.services
                              .map((service) => DropdownMenuItem<LawyerService>(
                                    value: service,
                                    child: Text('${service.title} — ${service.price} د.ع'),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _package = value),
                          validator: (value) => value == null ? 'يرجى اختيار باقة الاستشارة' : null,
                        ),
            ),
            Step(
              title: const Text('تفاصيل الاستشارة'),
              isActive: _step >= 1,
              content: widget.isCustom
                  ? TextFormField(
                      controller: _customConsultationTypeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'نوع الاستشارة',
                        hintText: 'مثال: قضية إدارية أو قضية تجارية',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'يرجى كتابة نوع الاستشارة'
                          : null,
                    )
                  : DropdownButtonFormField<String>(
                      value: _consultationType,
                      decoration: const InputDecoration(labelText: 'طريقة الاستشارة'),
                      items: const ['نصية', 'صوتية', 'فيديو']
                          .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) => setState(() => _consultationType = value ?? 'نصية'),
                    ),
            ),
            Step(
              title: const Text('اختيار الموعد المتاح فعليًا'),
              isActive: _step >= 2,
              content: slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('تعذر تحميل المواعيد المتاحة: $error'),
                data: (items) => items.isEmpty
                    ? const Text('لا توجد مواعيد متاحة حاليًا لهذا المحامي.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items
                            .map((slot) => ChoiceChip(
                                  label: Text('${slot.startsAt.day}/${slot.startsAt.month}  ${TimeOfDay.fromDateTime(slot.startsAt).format(context)}'),
                                  selected: _selectedSlot?.id == slot.id,
                                  onSelected: (_) => setState(() => _selectedSlot = slot),
                                ))
                            .toList(),
                      ),
              ),
            ),
            Step(
              title: const Text('مراجعة الحجز'),
              isActive: _step >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('المحامي: ${widget.lawyer.fullName ?? 'محامي'}'),
                  Text('الباقة: ${widget.isCustom ? 'استشارة مختلفة' : (_package?.title ?? '-')}'),
                  Text('نوع الاستشارة: ${widget.isCustom ? (_customConsultationTypeController.text.trim().isEmpty ? '-' : _customConsultationTypeController.text.trim()) : _consultationType}'),
                  Text('الموعد: ${_selectedSlot == null ? '-' : '${_selectedSlot!.startsAt.day}/${_selectedSlot!.startsAt.month}/${_selectedSlot!.startsAt.year} ${TimeOfDay.fromDateTime(_selectedSlot!.startsAt).format(context)}'}'),
                  if (!widget.isCustom) Text('الرسوم: ${_package?.price ?? 0} د.ع'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'تفاصيل الموضوع'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'تفاصيل الموضوع مطلوبة' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_selectedFileName ?? 'إرفاق مستند (اختياري)'),
                  ),
                  const SizedBox(height: 12),
                  Text('العميل: ${user?.fullName ?? 'المستخدم'}'),
                  const SizedBox(height: 12),
                  const Text('بعد إكمال الحجز ستفتح صفحة الدفع مباشرة. لن يتم اعتبار الحجز مؤكدًا قبل إكمال الدفع واعتماده.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
