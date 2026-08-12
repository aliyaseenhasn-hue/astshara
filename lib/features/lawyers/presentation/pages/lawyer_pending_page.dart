import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class LawyerPendingPage extends ConsumerWidget {
  const LawyerPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authControllerProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حالة الحساب', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: auth.logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSizes.p20, 18, AppSizes.p20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: AppColors.secondary.withValues(alpha: .14), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: .14),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
                      ),
                      child: const Icon(Icons.verified_user_rounded, size: 40, color: AppColors.gold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'حسابك قيد المراجعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'وصلت معلوماتك بنجاح. يقوم فريقنا الآن بمراجعة بيانات المحامي قبل تفعيل الحساب.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('ماذا يحدث الآن؟', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.secondary)),
              const SizedBox(height: 12),
              _StatusStep(icon: Icons.check_circle_rounded, title: 'تم استلام الطلب', subtitle: 'تم حفظ بياناتك بنجاح.', active: true),
              _StatusStep(icon: Icons.manage_search_rounded, title: 'مراجعة المعلومات', subtitle: 'يتم التحقق من بياناتك ووثائقك.', active: true),
              _StatusStep(icon: Icons.verified_rounded, title: 'تفعيل الحساب', subtitle: 'ستتمكن من استقبال الاستشارات بعد الموافقة.', active: false, last: true),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لا تحتاج إلى إعادة التسجيل. عند اكتمال المراجعة ستتغير حالة حسابك تلقائيًا.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: auth.logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('العودة لتسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool last;

  const _StatusStep({required this.icon, required this.title, required this.subtitle, required this.active, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Icon(icon, size: 27, color: active ? AppColors.primary : AppColors.outline),
              if (!last) Container(width: 2, height: 48, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.outline),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: active ? AppColors.secondary : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.outline, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
