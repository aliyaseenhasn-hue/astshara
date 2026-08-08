import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  late String _consultationType;
  final _descriptionController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _consultationType = widget.service.title;
    } else {
      _consultationType = 'نصية';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final packageName = widget.service?.title ??
        (widget.lawyer.services.isNotEmpty
            ? widget.lawyer.services.first.title
            : 'استشارة مخصصة');

    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: scheduledAt,
          packageName: packageName,
          consultationType: _consultationType,
          description: _descriptionController.text.trim(),
          documentBytes: _selectedFileBytes,
          documentName: _selectedFileName,
        );

    if (!mounted) return;

    if (booking == null) {
      final error = ref.read(bookingsControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'تعذر إنشاء طلب الاستشارة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // الدفع جزء من رحلة الطلب: لا نعتبر الحجز مؤكداً بمجرد إنشائه.
    context.push('/upload-payment', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final user = ref.watch(authStateChangesProvider).value;
    final price = widget.service?.price ??
        (widget.lawyer.services.isNotEmpty
            ? widget.lawyer.services.first.price
            : widget.lawyer.consultationPrice ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب استشارة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isCustom ? 'طلب استشارة مخصصة' : 'حجز باقة استشارية',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text('المحامي ${widget.lawyer.fullName}', style: const TextStyle(fontSize: 16, color: AppColors.secondary)),
              const SizedBox(height: 24),
              _buildSectionTitle('اسم العميل'),
              TextFormField(
                initialValue: user?.fullName ?? '...',
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('نوع الاستشارة'),
              DropdownButtonFormField<String>(
                value: _consultationType,
                items: const ['نصية', 'صوتية', 'فيديو']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _consultationType = val ?? 'نصية'),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('وصف الموضوع'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اشرح باختصار المشكلة القانونية...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'وصف الموضوع مطلوب' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('مستندات إضافية (اختياري)'),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_selectedFileName ?? 'اضغط لرفع مستندات أو صور تخص الموضوع')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('اختيار الموعد'),
              Row(
                children: [
                  Expanded(child: _buildPickerTile(
                    label: 'التاريخ',
                    value: '${_selectedDate.toLocal()}'.split(' ')[0],
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPickerTile(
                    label: 'الوقت',
                    value: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: () => _selectTime(context),
                  )),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رسوم الاستشارة:', style: TextStyle(color: Colors.white70)),
                    Text('$price د.ع', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم تحويلك إلى صفحة الدفع بعد إنشاء الطلب. لا يصبح الحجز مؤكداً إلا بعد التحقق من الدفع وموافقة المحامي.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('متابعة إلى الدفع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
      );

  Widget _buildPickerTile({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.surfaceVariant), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(value), Icon(icon, size: 18, color: AppColors.primary)],
            ),
          ),
        ),
      ],
    );
  }
}
