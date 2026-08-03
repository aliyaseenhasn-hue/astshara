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
  String _selectedMethod = 'ZainCash';
  XFile? _receiptImage;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = image;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(paymentsControllerProvider.notifier).submitPayment(
            bookingId: widget.booking.id,
            amount: widget.booking.price,
            method: _selectedMethod,
            transactionNumber: _transactionController.text,
            receiptFile: _receiptImage,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('تم رفع إيصال الدفع بنجاح، سيتم التحقق منه قريباً')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('رفع إيصال الدفع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المبلغ المطلوب: ${widget.booking.price} د.ع',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.p24),
              const Text('اختر وسيلة الدفع:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                items: ['ZainCash', 'Asia Hawala', 'Qi Card', 'MasterCard']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    val != null ? setState(() => _selectedMethod = val) : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _transactionController,
                decoration: const InputDecoration(
                  labelText: 'رقم العملية (Transaction ID)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: AppSizes.p24),
              const Text('إيصال الدفع (صورة):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.p8),
              InkWell(
                onTap: _pickReceipt,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                  ),
                  child: _receiptImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 50),
                            Text('اضغط لاختيار صورة الإيصال')
                          ],
                        )
                      : _receiptImage != null
                          ? (kIsWeb
                              ? Image.network(_receiptImage!.path,
                                  fit: BoxFit.contain)
                              : Image.file(File(_receiptImage!.path),
                                  fit: BoxFit.contain))
                          : const SizedBox(),
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              state.isLoading
                  ? const LoadingWidget()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSizes.p16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إرسال الإيصال'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
