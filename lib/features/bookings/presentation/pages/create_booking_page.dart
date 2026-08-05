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
  final dynamic service; // LawyerService optional
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
  final _whatsappController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _consultationType = widget.service.title;
    } else {
      _consultationType = widget.lawyer.specializations.isNotEmpty
          ? widget.lawyer.specializations.first
          : 'عام';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
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

    final double price =
        widget.service?.price ?? widget.lawyer.consultationPrice ?? 0;

    await ref.read(bookingsControllerProvider.notifier).requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: scheduledAt,
          price: price,
          consultationType: _consultationType,
          description: _descriptionController.text.trim(),
          documentBytes: _selectedFileBytes,
          documentName: _selectedFileName,
          whatsappNumber: _whatsappController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الحجز بنجاح')),
      );
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('حجز استشارة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isCustom ? 'طلب استشارة مخصصة' : 'حجز باقة استشارية',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'المحامي ${widget.lawyer.fullName}',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
              const SizedBox(height: 24),

              // Client Name (Auto-filled, Read-only)
              _buildSectionTitle('اسم العميل'),
              TextFormField(
                initialValue: user?.fullName ?? '...',
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Consultation Type
              _buildSectionTitle('نوع الاستشارة'),
              if (widget.service != null)
                TextFormField(
                  initialValue: _consultationType,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _consultationType,
                  items: [
                    'جنائي',
                    'أحوال شخصية',
                    'مدني',
                    'تجاري',
                    'عقارات',
                    'أخرى'
                  ]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _consultationType = val ?? 'أخرى'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 20),

              // WhatsApp Number (Mandatory)
              _buildSectionTitle('رقم الواتساب للتواصل (إجباري)'),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'مثلاً: 077XXXXXXXX',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'رقم الواتساب مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              // Description (Mandatory)
              _buildSectionTitle('نبذة مختصرة عن الموضوع (إجباري)'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اشرح باختصار المشكلة القانونية...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'هذا الحقل مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              // Document Upload (Optional)
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
                      Expanded(
                        child: Text(
                          _selectedFileName ??
                              'اضغط لرفع مستندات أو صور تخص الموضوع',
                          style: TextStyle(
                            color: _selectedFileName != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date & Time
              _buildSectionTitle('اختيار موعد'),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: 'التاريخ',
                      value: '${_selectedDate.toLocal()}'.split(' ')[0],
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      label: 'الوقت',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time,
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Price Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رسوم الاستشارة:',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                      '${widget.service?.price ?? widget.lawyer.consultationPrice ?? 0} د.ع',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('تأكيد وإرسال الطلب',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)),
    );
  }

  Widget _buildTypeCard(IconData icon, String label, String type) {
    // This is no longer used in the new UI but kept for compatibility if needed
    return const SizedBox.shrink();
  }

  Widget _buildPickerTile(
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.outline)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value),
                Icon(icon, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String title, String method) {
    return const SizedBox.shrink(); // Using unified summary now
  }
}
