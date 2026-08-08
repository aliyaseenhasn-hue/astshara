import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../providers/bookings_provider.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  final LawyerProfile lawyer;
  final LawyerService? service;
  final bool isCustom;

  const CreateBookingPage({super.key, required this.lawyer, this.service, this.isCustom = false});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  int _step = 0;
  LawyerService? _selectedPackage;
  String _consultationType = 'نصية';
  DateTime? _selectedSlot;
  List<DateTime> _availableSlots = const [];
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.service;
    if (_selectedPackage != null && !_selectedPackage!.consultationTypes.contains(_consultationType)) {
      _consultationType = _selectedPackage!.consultationTypes.first;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
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
    setState(() => _loadingSlots = true);
    try {
      final now = DateTime.now().toUtc();
      final response = await SupabaseConfig.client
          .from('lawyer_availability_slots')
          .select('starts_at')
          .eq('lawyer_id', widget.lawyer.profileId)
          .eq('is_available', true)
          .gte('starts_at', now.toIso8601String())
          .lte('starts_at', now.add(const Duration(days: 30)).toIso8601String())
          .order('starts_at');
      _availableSlots = (response as List)
          .map((row) => DateTime.parse(row['starts_at'] as String).toLocal())
          .toList();
      if (mounted) setState(() => _step = 2);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحميل المواعيد المتاحة')));
      }
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submitBooking() async {
    final package = _selectedPackage;
    final slot = _selectedSlot;
    if (package == null || slot == null) return;

    await ref.read(bookingsControllerProvider.notifier).requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: slot,
          price: package.price,
          consultationType: '${package.title}::$_consultationType',
          description: _descriptionController.text.trim(),
          documentBytes: _selectedFileBytes,
          documentName: _selectedFileName,
          whatsappNumber: _whatsappController.text.trim(),
        );

    if (!mounted) return;
    final state = ref.read(bookingsControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الحجز: ${state.error}')));
      return;
    }

    try {
      final bookings = await ref.read(userBookingsProvider.future);
      final booking = bookings.where((b) => b.lawyerId == widget.lawyer.profileId && b.scheduledAt.toUtc().difference(slot.toUtc()).inSeconds.abs() < 2).firstOrNull;
      if (booking != null && mounted) {
        context.push('/upload-payment', extra: booking);
        return;
      }
    } catch (_) {}

    if (mounted) context.go('/bookings');
  }

  Future<void> _submitCustomRequest() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.length < 3 || description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال موضوع ووصف واضحين للطلب')));
      return;
    }

    await ref.read(bookingsControllerProvider.notifier).requestCustomConsultation(
          lawyerId: widget.lawyer.profileId,
          subject: subject,
          description: description,
          consultationType: _consultationType,
        );

    if (!mounted) return;
    final state = ref.read(bookingsControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: ${state.error}')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الاستشارة المخصص إلى المهني')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsControllerProvider);
    final user = ref.watch(authStateChangesProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isCustom ? 'طلب استشارة مخصص' : 'حجز استشارة'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!widget.isCustom) ...[_StepIndicator(current: _step), const SizedBox(height: 20)],
          Text(
            widget.isCustom ? 'لم تجد نوع الاستشارة المناسب؟' : 'حجز باقة استشارية',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text('المهني: ${widget.lawyer.fullName ?? 'غير محدد'}', style: const TextStyle(color: AppColors.secondary)),
          const SizedBox(height: 20),
          if (widget.isCustom) _buildCustomRequestStep() else ...[
            if (_step == 0) _buildPackageStep(),
            if (_step == 1) _buildTypeStep(),
            if (_step == 2) _buildSlotStep(),
            if (_step == 3) _buildReviewStep(user),
          ],
          if (state.isLoading) ...[const SizedBox(height: 20), const Center(child: CircularProgressIndicator())],
        ]),
      ),
    );
  }

  Widget _buildCustomRequestStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('أرسل طلب استشارة مخصص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'اكتب موضوع الاستشارة وتفاصيل المشكلة، ثم اختر طريقة التواصل المطلوبة. سيقوم المهني بمراجعة الطلب وفق النظام.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _subjectController,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'موضوع الاستشارة', hintText: 'مثال: أحتاج استشارة في عقد تجاري', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            maxLength: 5000,
            decoration: const InputDecoration(labelText: 'وصف المشكلة', hintText: 'اشرح موضوعك والمعلومات المهمة باختصار ووضوح', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          const Text('طريقة التواصل المطلوبة', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['نصية', 'صوتية', 'فيديو'].map((type) => ChoiceChip(
              label: Text(type),
              selected: _consultationType == type,
              onSelected: (_) => setState(() => _consultationType = type),
            )).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitCustomRequest,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('إرسال الطلب للمهني'),
          ),
        ],
      );

  Widget _buildPackageStep() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('اختر الباقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.lawyer.services.isEmpty)
          const _MessageCard(message: 'لا توجد باقات متاحة للحجز حالياً.')
        else
          ...widget.lawyer.services.map((service) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: RadioListTile<LawyerService>(
              value: service,
              groupValue: _selectedPackage,
              onChanged: (value) => setState(() => _selectedPackage = value),
              title: Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${service.price.toStringAsFixed(0)} د.ع • ${service.durationMinutes} دقيقة'),
            ),
          )),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _selectedPackage == null ? null : () => setState(() => _step = 1), child: Text(_selectedPackage == null ? 'اختر باقة أولاً' : 'متابعة الحجز')),
      ]);

  Widget _buildTypeStep() {
    final types = _selectedPackage?.consultationTypes ?? const ['نصية', 'صوتية', 'فيديو'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('طريقة الاستشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...types.map((type) => Card(child: RadioListTile<String>(value: type, groupValue: _consultationType, onChanged: (value) => setState(() => _consultationType = value ?? type), title: Text(type)))),
      const SizedBox(height: 12),
      TextFormField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'وصف مختصر للموضوع', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextFormField(controller: _whatsappController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم واتسابك للتواصل', hintText: '077XXXXXXXX', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file), label: Text(_selectedFileName ?? 'إرفاق مستند اختياري')),
      const SizedBox(height: 16),
      _NavigationButtons(onBack: () => setState(() => _step = 0), onNext: _loadingSlots ? null : _loadSlots, nextLabel: _loadingSlots ? 'جاري تحميل المواعيد...' : 'اختيار الموعد'),
    ]);
  }

  Widget _buildSlotStep() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('اختر الموعد المتاح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    if (_availableSlots.isEmpty)
      const _MessageCard(message: 'لا توجد مواعيد متاحة حالياً.')
    else
      Wrap(spacing: 8, runSpacing: 8, children: _availableSlots.map((slot) => ChoiceChip(label: Text('${slot.day}/${slot.month} • ${TimeOfDay.fromDateTime(slot).format(context)}'), selected: _selectedSlot == slot, onSelected: (_) => setState(() => _selectedSlot = slot))).toList()),
    const SizedBox(height: 16),
    _NavigationButtons(onBack: () => setState(() => _step = 1), onNext: _selectedSlot == null ? null : () => setState(() => _step = 3), nextLabel: 'مراجعة الحجز'),
  ]);

  Widget _buildReviewStep(dynamic user) {
    final package = _selectedPackage!;
    final slot = _selectedSlot!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      _NavigationButtons(onBack: () => setState(() => _step = 2), onNext: _submitBooking, nextLabel: 'متابعة إلى الدفع'),
    ]);
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(4, (index) => Expanded(child: Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: index <= current ? AppColors.primary : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10))))));
}

class _NavigationButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  const _NavigationButtons({required this.onBack, required this.onNext, required this.nextLabel});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('رجوع'))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: onNext, child: Text(nextLabel)))]);
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));
}

class _MessageCard extends StatelessWidget {
  final String message;
  const _MessageCard({required this.message});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(message, textAlign: TextAlign.center)));
}
