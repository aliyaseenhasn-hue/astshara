import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final walletNumber = user?.walletNumber ?? 'لم يتم الربط';

    return Scaffold(
      appBar: AppBar(title: const Text('طرق الدفع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المحافظ الإلكترونية المتاحة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildPaymentCard(
              context,
              ref,
              'زين كاش (Zain Cash)',
              walletNumber,
              Colors.red,
            ),
            const SizedBox(height: 32),
            const Text(
              'ملاحظة: رقم المحفظة هذا سيستخدم لاستقبال الأرباح (للمحامين) أو لتسهيل عمليات الدفع.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, WidgetRef ref, String title,
      String wallet, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('رقم المحفظة: $wallet'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: AppColors.primary, size: 20),
          onPressed: () => _showEditWalletDialog(
              context, ref, wallet == 'لم يتم الربط' ? '' : wallet),
        ),
      ),
    );
  }

  void _showEditWalletDialog(
      BuildContext context, WidgetRef ref, String currentWallet) {
    final controller = TextEditingController(text: currentWallet);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل رقم المحفظة'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'رقم المحفظة (مثلاً: 077XXXXXXXX)',
            hintText: 'أدخل 11 رقماً',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newWallet = controller.text.trim();
              if (newWallet.length != 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى إدخال رقم هاتف صحيح (11 رقم)')),
                );
                return;
              }
              // سأستخدم updateProfile مباشرة من الـ Repository لتجنب تعديل الـ Controller حالياً
              await ref.read(authRepositoryProvider).updateProfile(
                    walletNumber: newWallet,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
