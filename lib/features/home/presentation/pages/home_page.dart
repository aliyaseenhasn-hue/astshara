import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _categories = <({IconData icon, String title, String value})>[
    (icon: Icons.gavel_rounded, title: 'جنائي', value: 'جنائي'),
    (icon: Icons.family_restroom_rounded, title: 'أحوال شخصية', value: 'أحوال شخصية'),
    (icon: Icons.account_balance_rounded, title: 'مدني', value: 'مدني'),
    (icon: Icons.business_center_rounded, title: 'تجاري', value: 'تجاري'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(lawyersListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppColors.secondaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.secondaryDark, AppColors.secondary, AppColors.primaryDark],
                    stops: [0, .58, 1],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 58, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(13)),
                              child: const Icon(Icons.balance_rounded, color: AppColors.secondaryDark),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('استشارة', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('منصتك القانونية الموثوقة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
                          ],
                        ),
                        const Spacer(),
                        const Text('كيف يمكننا مساعدتك اليوم؟', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.25, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => context.go('/lawyers'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                            child: const Row(children: [Icon(Icons.search_rounded, color: AppColors.gold), SizedBox(width: 10), Text('ابحث عن محامٍ أو تخصص...', style: TextStyle(color: Colors.white60))]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(children: [const Expanded(child: Text('التخصصات القانونية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary))), TextButton(onPressed: () => context.go('/lawyers'), child: const Text('عرض الكل'))]),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return InkWell(
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).setCategory(category.value);
                        context.go('/lawyers');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: Icon(category.icon, color: AppColors.primaryDark)),
                          Text(category.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Row(children: [const Expanded(child: Text('محامون مقترحون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary))), TextButton(onPressed: () => context.go('/lawyers'), child: const Text('عرض الكل'))]),
                const SizedBox(height: 8),
                lawyersAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('تعذر تحميل المحامين'))),
                  data: (lawyers) {
                    if (lawyers.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا يوجد محامون موثقون حالياً')));
                    return Column(children: lawyers.take(3).map((lawyer) => _SuggestedLawyerCard(lawyer: lawyer)).toList());
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedLawyerCard extends StatelessWidget {
  final dynamic lawyer;
  const _SuggestedLawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final avatar = lawyer.avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline)),
      child: InkWell(
        onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceVariant, border: Border.all(color: AppColors.gold, width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: hasAvatar ? null : const Icon(Icons.person, color: AppColors.primaryDark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(lawyer.fullName ?? 'محامي', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary))), if (lawyer.verified) const Icon(Icons.verified_rounded, color: AppColors.primaryDark, size: 17)]),
              const SizedBox(height: 4),
              Text(lawyer.specializations.isNotEmpty ? lawyer.specializations.take(2).join('، ') : 'قانون عام', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 16), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), const Spacer(), Text('${lawyer.reviewCount} تقييم', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
            ])),
          ]),
        ),
      ),
    );
  }
}
