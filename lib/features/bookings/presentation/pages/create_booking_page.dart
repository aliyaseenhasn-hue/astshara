import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../providers/bookings_provider.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  final LawyerProfile lawyer;
  final dynamic service;
  final bool isCustom;

  const CreateBookingPage({
    super.key,
    required this.lawyer,
    this.service,
    this.isCustom = false,
  });

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  int _step = 0;
  LawyerService? _package;
  String _consultationType = 'نصية';
  AvailableBookingSlot? _selectedSlot;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

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

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_package == null) {
          _showMessage('يرجى اختيار باقة الاستشارة أولاً');
          return false;
        }
        return true;
      case 1:
        if (_consultationType.isEmpty) {
          _showMessage('يرجى اختيار طريقة الاستشارة');
          return false;
        }
        return true;
      case 2:
        if (_selectedSlot == null) {
          _showMessage('يرجى اختيار موعد متاح فعليًا');
          return false;
        }
        return true;
      default:
        return _formKey.currentState?.validate() ?? false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    if (_package == null || slot == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final booking = await ref
        .read(bookingsControllerProvider.notifier)
        .requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: slot.startsAt,
          slotId: slot.id,
          packageName: _package!.title,
          consultationType: _consultationType,
          description: _descriptionController.text.trim(),
          documentBytes: _selectedFileBytes,
          documentName: _selectedFileName,
        );

    if (!mounted) return;

    if (booking == null) {
      final error = ref.read(bookingsControllerProvider).error;
      _showMessage(error?.toString() ?? 'تعذر إنشاء الحجز');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تم إنشاء الحجز'),
        content: const Text(
          'الحجز الآن في حالة «قيد انتظار الدفع». أرسل الدفع من تفاصيل الحجز، ثم يبقى «قيد معالجة الدفع» حتى تعتمد الإدارة العملية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final slotsAsync = ref.watch(availableSlotsProvider(widget.lawyer.profileId));
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز استشارة'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: state.isLoading ? null : _next,
          onStepCancel: _step == 0 ? null : () => setState(() => _step--),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_step == 3 ? 'تأكيد الحجز' : 'متابعة'),
                    ),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('رجوع'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('اختيار الباقة'),
              isActive: _step >= 0,
              content: widget.lawyer.services.isEmpty
                  ? const Text('لا توجد باقات متاحة لهذا المحامي.')
                  : DropdownButtonFormField<LawyerService>(
                      value: _package,
                      decoration: const InputDecoration(labelText: 'الباقة'),
                      items: widget.lawyer.services
                          .map(
                            (service) => DropdownMenuItem<LawyerService>(
                              value: service,
                              child: Text('${service.title} — ${service.price} د.ع'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _package = value),
                      validator: (value) => value == null ? 'يرجى اختيار باقة الاستشارة' : null,
                    ),
            ),
            Step(
              title: const Text('اختيار طريقة الاستشارة'),
              isActive: _step >= 1,
              content: DropdownButtonFormField<String>(
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
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('لا توجد مواعيد متاحة حاليًا لهذا المحامي.');
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((slot) {
                      return ChoiceChip(
                        label: Text(
                          '${slot.startsAt.day}/${slot.startsAt.month}  ${TimeOfDay.fromDateTime(slot.startsAt).format(context)}',
                        ),
                        selected: _selectedSlot?.id == slot.id,
                        onSelected: (_) => setState(() => _selectedSlot = slot),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Step(
              title: const Text('مراجعة الحجز'),
              isActive: _step >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('المحامي: ${widget.lawyer.fullName ?? 'محامي'}'),
                  Text('الباقة: ${_package?.title ?? '-'}'),
                  Text('طريقة الاستشارة: $_consultationType'),
                  Text(
                    'الموعد: ${_selectedSlot == null ? '-' : '${_selectedSlot!.startsAt.day}/${_selectedSlot!.startsAt.month}/${_selectedSlot!.startsAt.year} ${TimeOfDay.fromDateTime(_selectedSlot!.startsAt).format(context)}'}',
                  ),
                  Text('الرسوم: ${_package?.price ?? 0} د.ع'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'وصف الموضوع'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'وصف الموضوع مطلوب' : null,
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
                  const Text(
                    'بعد التأكيد سيصبح الحجز «قيد انتظار الدفع». لا توجد موافقة من المحامي في هذه المرحلة؛ اعتماد الإدارة للدفع هو الذي ينقل الحجز إلى «مؤكد».',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
