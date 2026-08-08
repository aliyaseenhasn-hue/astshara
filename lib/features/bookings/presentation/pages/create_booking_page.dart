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
  final LawyerService? service;
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
  int _step = 0;
  LawyerService? _selectedPackage;
  String _consultationType = 'نصية';
  DateTime? _selectedSlot;
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.service;
    if (_selectedPackage != null &&
        !_selectedPackage!.consultationTypes.contains(_consultationType)) {
      _consultationType = _selectedPackage!.consultationTypes.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      withData: true,
    );
    if (result?.files.first.bytes == null) return;
    setState(() {
      _selectedFileBytes = result!.files.first.bytes;
      _selectedFileName = result.files.first.name;
    });
  }

  Future<void> _loadSlots() async {
    if (_selectedPackage == null) return;
    setState(() => _step = 2);
    final from = DateTime.now();
    final to = from.add(const Duration(days: 30));
    ref.invalidate(availableBookingSlotsProvider((
      lawyerId: widget.lawyer.profileId,
      from: from,
      to: to,
    )));
  }

  Future<void> _submit() async {
    final package = _selectedPackage;
    final slot = _selectedSlot;
    if (package == null || slot == null) return;

    final booking = await ref.read(bookingsControllerProvider.notifier).requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: slot,
          packageName: package.title,
          consultationType: _consultationType,
          description: _descriptionController.text.trim(),
          documentBytes: _selectedFileBytes,
          documentName: _selectedFileName,
          whatsappNumber: _whatsappController.text.trim(),
        );

    if (!mounted) return;
    if (booking == null) {
      final error = ref.read(bookingsControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء الحجز: ${error ?? 'حاول مرة أخرى'}')),
      );
      return;
    }
    context.push('/upload-payment', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('حجز استشارة'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: _step),
            const SizedBox(height: 20),
            Text(
              widget.isCustom ? 'طلب استشارة مخصصة' : 'حجز باقة استشارية',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text('المهني: ${widget.lawyer.fullName ?? 'غير محدد'}', style: const TextStyle(color: AppColors.secondary)),
            const SizedBox(height: 20),
            if (_step == 0) _buildPackageStep(),
            if (_step == 1) _buildTypeStep(),
            if (_step == 2) _buildSlotStep(),
            if (_step == 3) _buildReviewStep(user),
            if (state.isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageStep() {
    if (widget.lawyer.services.isEmpty) {
      return const _MessageCard(message: 'لا توجد باقات متاحة للحجز حالياً.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('اختر الباقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...widget.lawyer.services.map((service) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<LawyerService>(
                value: service,
                groupValue: _selectedPackage,
                onChanged: (value) => setState(() => _selectedPackage = value),
                title: Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${service.price.toStringAsFixed(0)} د.ع • ${service.durationMinutes} دقيقة'),
                secondary: const Icon(Icons.arrow_back_ios_new, size: 16),
              ),
            )),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _selectedPackage == null ? null : () => setState(() => _step = 1),
          child: Text(_selectedPackage == null ? 'اختر باقة أولاً' : 'متابعة الحجز'),
        ),
      ],
    );
  }

  Widget _buildTypeStep() {
    final types = _selectedPackage?.consultationTypes ?? const ['نصية', 'صوتية', 'فيديو'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('طريقة الاستشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...types.map((type) => Card(
              child: RadioListTile<String>(
                value: type,
                groupValue: _consultationType,
                onChanged: (value) => setState(() => _consultationType = value ?? type),
                title: Text(type),
              ),
            )),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'وصف مختصر للموضوع',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'رقم واتسابك للتواصل',
            hintText: '077XXXXXXXX',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(_selectedFileName ?? 'إرفاق مستند اختياري'),
        ),
        const SizedBox(height: 16),
        _NavigationButtons(
          onBack: () => setState(() => _step = 0),
          onNext: _loadSlots,
          nextLabel: 'اختيار الموعد',
        ),
      ],
    );
  }

  Widget _buildSlotStep() {
    final from = DateTime.now();
    final to = from.add(const Duration(days: 30));
    final slotsAsync = ref.watch(availableBookingSlotsProvider((
      lawyerId: widget.lawyer.profileId,
      from: from,
      to: to,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('اختر الموعد المتاح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        slotsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('تعذر تحميل المواعيد: $error'),
          data: (slots) => slots.isEmpty
              ? const _MessageCard(message: 'لا توجد مواعيد متاحة حالياً.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((slot) {
                    final selected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text('${slot.day}/${slot.month} • ${TimeOfDay.fromDateTime(slot).format(context)}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _NavigationButtons(
          onBack: () => setState(() => _step = 1),
          onNext: _selectedSlot == null ? null : () => setState(() => _step = 3),
          nextLabel: 'مراجعة الحجز',
        ),
      ],
    );
  }

  Widget _buildReviewStep(dynamic user) {
    final package = _selectedPackage!;
    final slot = _selectedSlot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('مراجعة الحجز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _ReviewRow('المهني', widget.lawyer.fullName ?? 'غير محدد'),
        _ReviewRow('الباقة', package.title),
        _ReviewRow('طريقة الاستشارة', _consultationType),
        _ReviewRow('المدة', '${package.durationMinutes} دقيقة'),
        _ReviewRow('التاريخ', '${slot.day}/${slot.month}/${slot.year}'),
        _ReviewRow('الوقت', TimeOfDay.fromDateTime(slot).format(context)),
        _ReviewRow('المبلغ', '${package.price.toStringAsFixed(0)} د.ع'),
        if (user != null) _ReviewRow('طالب الخدمة', user.fullName ?? 'المستخدم'),
        const SizedBox(height: 20),
        const _MessageCard(message: 'سيبقى الحجز غير مؤكد حتى يتم التحقق من الدفع.'),
        const SizedBox(height: 16),
        _NavigationButtons(
          onBack: () => setState(() => _step = 2),
          onNext: _submit,
          nextLabel: 'الدفع وتأكيد الحجز',
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(4, (index) {
          final active = index <= current;
          return Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      );
}

class _NavigationButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  const _NavigationButtons({required this.onBack, required this.onNext, required this.nextLabel});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('رجوع'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: onNext, child: Text(nextLabel))),
        ],
      );
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _MessageCard extends StatelessWidget {
  final String message;
  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
