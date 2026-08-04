import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/payment_management_provider.dart';

class PaymentManagementPage extends ConsumerWidget {
  const PaymentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة الدفعات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        data: (payments) => payments.isEmpty
            ? const Center(child: Text('لا توجد دفعات معلقة للمراجعة'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text('المبلغ: ${payment.amount} د.ع',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الوسيلة: ${payment.paymentMethod}'),
                          trailing: Text(
                            payment.createdAt != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(payment.createdAt!)
                                : '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (payment.transactionNumber != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                                'رقم العملية: ${payment.transactionNumber}',
                                style:
                                    const TextStyle(color: AppColors.primary)),
                          ),
                        const SizedBox(height: 12),
                        if (payment.receiptUrl != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: InkWell(
                              onTap: () =>
                                  _showFullImage(context, payment.receiptUrl!),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.surfaceVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(payment.receiptUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Center(
                                          child: Text('خطأ في تحميل الصورة'))),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => ref
                                      .read(paymentManagementProvider.notifier)
                                      .approvePayment(payment),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white),
                                  child: const Text('تأكيد الدفع'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => ref
                                      .read(paymentManagementProvider.notifier)
                                      .rejectPayment(payment),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error)),
                                  child: const Text('رفض'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
                title: const Text('إيصال الدفع'),
                leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))),
            Image.network(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
