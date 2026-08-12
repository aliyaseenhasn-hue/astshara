import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateChangesProvider).value;
    final walletNumber = user?.walletNumber ?? 'لم يتم الربط';
    final connected = walletNumber != 'لم يتم الربط' && walletNumber.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('طرق الدفع', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSizes.p20, 10, AppSizes.p20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [scheme.primaryContainer, scheme.secondaryContainer]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.surface.withValues(alpha: .8), shape: BoxShape.circle), child: Icon(Icons.account_balance_wallet_rounded, color: scheme.primary, size: 27)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('محفظتك الإلكترونية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(connected ? 'جاهزة لاستقبال المدفوعات' : 'اربط محفظتك لتسهيل عمليات الدفع', style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withValues(alpha: .78))),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          Text('المحافظ الإلكترونية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface)),
          const SizedBox(height: 12),
          _buildPaymentCard(context, ref, 'زين كاش', walletNumber, connected, scheme),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .7), borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('رقم المحفظة يستخدم لاستقبال الأرباح للمحامين وتسهيل عمليات الدفع. احرص على إدخال رقم صحيح ومملوك لك.', style: TextStyle(fontSize: 12, height: 1.55, color: scheme.onSurfaceVariant))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, WidgetRef ref, String title, String wallet, bool connected, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.onSurface)),
            const SizedBox(height: 5),
            Text(connected ? wallet : 'لم يتم الربط', style: TextStyle(fontSize: 13, color: connected ? scheme.onSurfaceVariant : scheme.error, fontWeight: connected ? FontWeight.w500 : FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [Icon(connected ? Icons.check_circle_rounded : Icons.link_rounded, size: 14, color: connected ? scheme.primary : scheme.secondary), const SizedBox(width: 5), Text(connected ? 'مرتبطة' : 'ربط المحفظة', style: TextStyle(fontSize: 11, color: connected ? scheme.primary : scheme.secondary, fontWeight: FontWeight.w700))]),
          ])),
          IconButton(onPressed: () => _showEditWalletDialog(context, ref, connected ? wallet : ''), icon: Icon(connected ? Icons.edit_rounded : Icons.add_circle_outline_rounded, color: scheme.primary)),
        ]),
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, WidgetRef ref, String currentWallet) {
    final controller = TextEditingController(text: currentWallet);
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('تعديل رقم المحفظة'),
      content: TextFormField(controller: controller, decoration: const InputDecoration(labelText: 'رقم المحفظة', hintText: '077XXXXXXXX'), keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          final newWallet = controller.text.trim();
          if (newWallet.length != 11) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم هاتف صحيح (11 رقم)')));
            return;
          }
          await ref.read(authRepositoryProvider).updateProfile(walletNumber: newWallet);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        }, child: const Text('حفظ')),
      ],
    ));
  }
}
