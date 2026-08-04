import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/lawyers/domain/entities/lawyer_profile.dart';
import '../providers/bookings_provider.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  final LawyerProfile lawyer;
  const CreateBookingPage({super.key, required this.lawyer});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _consultationType = 'audio';
  String _paymentMethod = 'zaincash';
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
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

  Future<void> _submit() async {
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await ref.read(bookingsControllerProvider.notifier).requestBooking(
          lawyerId: widget.lawyer.profileId,
          scheduledAt: scheduledAt,
          price: widget.lawyer.consultationPrice ?? 0,
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

    return Scaffold(
      appBar: AppBar(title: const Text('حجز استشارة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'استشارة جديدة',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const Text('الرجاء إكمال التفاصيل أدناه لحجز استشارتك القانونية.'),
            const SizedBox(height: AppSizes.p24),

            // Consultation Type
            _buildSectionTitle('نوع الاستشارة'),
            Row(
              children: [
                _buildTypeCard(Icons.chat, 'نصية', 'text'),
                const SizedBox(width: 8),
                _buildTypeCard(Icons.call, 'صوتية', 'audio'),
                const SizedBox(width: 8),
                _buildTypeCard(Icons.videocam, 'فيديو', 'video'),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // Date & Time
            _buildSectionTitle('الموعد'),
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
            const SizedBox(height: AppSizes.p24),

            // Description
            _buildSectionTitle('تفاصيل المشكلة القانونية'),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'يرجى كتابة وصف مختصر لمشكلتك...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Payment Summary
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow('رسوم الاستشارة',
                      '${widget.lawyer.consultationPrice} د.ع'),
                  _buildSummaryRow('رسوم الخدمة', '2,500 د.ع'),
                  const Divider(height: 32),
                  _buildSummaryRow('المجموع',
                      '${(widget.lawyer.consultationPrice ?? 0) + 2500} د.ع',
                      isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Payment Method
            _buildSectionTitle('طريقة الدفع'),
            _buildPaymentMethodTile('زين كاش (ZainCash)', 'zaincash'),
            _buildPaymentMethodTile('آسيا حوالة (AsiaPay)', 'asiapay'),
            _buildPaymentMethodTile('بطاقة ائتمان', 'card'),

            const SizedBox(height: AppSizes.p32),
            state.isLoading
                ? const LoadingWidget()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('تأكيد ودفع'),
                  ),
          ],
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
    final isSelected = _consultationType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _consultationType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.surfaceVariant),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? AppColors.primary : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title, String method) {
    return RadioListTile<String>(
      title: Text(title),
      value: method,
      // ignore: deprecated_member_use
      groupValue: _paymentMethod,
      // ignore: deprecated_member_use
      onChanged: (val) =>
          val != null ? setState(() => _paymentMethod = val) : null,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }
}
