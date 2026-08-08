import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:astshara/features/bookings/domain/entities/booking.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../providers/payments_provider.dart';

class PaymentUploadPage extends ConsumerStatefulWidget {
  final Booking booking;
  const PaymentUploadPage({super.key, required this.booking});

  @override
  ConsumerState<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends ConsumerState<PaymentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _transactionController = TextEditingController();
  String _selectedMethod = 'زين كاش';
  XFile? _receiptImage;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _receiptImage = image);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(paymentsControllerProvider.notifier).submitPayment(
          bookingId: widget.booking.id,
          method: _selectedMethod,
          transactionNumber: _transactionController.text.trim(),
          receiptFile: _receiptImage,
        );

    if (!mounted) return;
    final state = ref.read(paymentsControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الدفع: ${state.error}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال بيانات الدفع، والحجز الآن بانتظار التأكيد')),
    );
    context.go('/bookings');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsControllerProvider);
    final nameAsync = ref.watch(userNameProvider(widget.booking.lawyerId));

    return Scaffold(
      appBar: AppBar(title: const Text('إكمال عملية الدفع'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nameAsync.when(
                data: (name) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('أنت تقوم بالدفع لاستشارة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('المحامي ${name ?? '...'}', style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              _SummaryRow(label: 'الباقة', value: widget.booking.packageName ?? 'استشارة'),
              _SummaryRow(label: 'نوع الاستشارة', value: widget.booking.consultationType ?? 'غير محدد'),
              _SummaryRow(label: 'الموعد', value: '${widget.booking.scheduledAt.day}/${widget.booking.scheduledAt.month}/${widget.booking.scheduledAt.year}'),
              _SummaryRow(label: 'الوقت', value: TimeOfDay.fromDateTime(widget.booking.scheduledAt).format(context)),
              _SummaryRow(label: 'المبلغ', value: '${widget.booking.price.toStringAsFixed(0)} د.ع'),
              const SizedBox(height: AppSizes.p24),
              const Text('اختر وسيلة الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                items: const ['زين كاش', 'آسيا حوالة', 'كي كارد', 'بطاقة مصرفية']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMethod = value ?? _selectedMethod),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _transactionController,
                decoration: InputDecoration(
                  labelText: 'رقم العملية',
                  hintText: 'أدخل الرقم الموجود في رسالة التأكيد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'رقم العملية مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p24),
              const Text('إيصال الدفع (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.p8),
              InkWell(
                onTap: _pickReceipt,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: _receiptImage == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.outline),
                          SizedBox(height: 8),
                          Text('اضغط لرفع صورة الإيصال', style: TextStyle(color: AppColors.textSecondary)),
                        ])
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(_receiptImage!.path, fit: BoxFit.cover, width: double.infinity)
                              : Image.file(File(_receiptImage!.path), fit: BoxFit.cover, width: double.infinity),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              state.isLoading
                  ? const LoadingWidget()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إرسال بيانات الدفع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
