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
        title: const Text('مراقبة الدفعات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        data: (payments) => payments.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 56, color: AppColors.success),
                    SizedBox(height: 12),
                    Text('لا توجد دفعات تحتاج تدخلاً إدارياً', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'يتم التحقق من عمليات كي كارد واعتماد الدفع تلقائياً بعد تأكيد نجاح العملية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync_outlined, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('الدفع قيد التحقق الآلي', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              if (payment.createdAt != null)
                                Text(DateFormat('yyyy-MM-dd').format(payment.createdAt!), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('المبلغ: ${payment.amount.toStringAsFixed(0)} د.ع'),
                          const SizedBox(height: 4),
                          Text('الوسيلة: ${payment.paymentMethod}'),
                          if (payment.transactionNumber != null) ...[
                            const SizedBox(height: 4),
                            Text('رقم العملية: ${payment.transactionNumber}'),
                          ],
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'لن يحتاج هذا الدفع إلى موافقة الإدارة بشكل طبيعي. سيتم تحديث الحالة تلقائياً عند تأكيد نجاح العملية من بوابة الدفع.',
                              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('تعذر تحميل الدفعات: $err')),
      ),
    );
  }
}
