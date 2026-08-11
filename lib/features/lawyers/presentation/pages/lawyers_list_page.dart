import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

class LawyersListPage extends ConsumerWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(lawyersListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: AppColors.secondaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.secondaryDark, AppColors.secondary, AppColors.primaryDark], stops: [0, .62, 1])),
                child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 54, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.balance_rounded, color: AppColors.secondaryDark)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('استشارة', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)), Text('منصتك القانونية الموثوقة', style: TextStyle(color: Colors.white70, fontSize: 11))])),
                    IconButton(onPressed: () => context.push('/notifications'), tooltip: 'التنبيهات', icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
                  ]),
                  const SizedBox(height: 24),
                  const Text('كيف يمكننا مساعدتك اليوم؟', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .12))), child: TextField(onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value, style: const TextStyle(color: Colors.white), cursorColor: AppColors.gold, decoration: const InputDecoration(hintText: 'ابحث عن محامٍ أو تخصص...', hintStyle: TextStyle(color: Colors.white60), prefixIcon: Icon(Icons.search_rounded, color: AppColors.gold), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)))),
                ]))),
              ),
            ),
          ),
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 110), sliver: SliverList(delegate: SliverChildListDelegate([
            const Text('التخصصات القانونية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
            const SizedBox(height: 12),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.65, children: [
              _CategoryCard(icon: Icons.gavel_rounded, label: 'جنائي', isSelected: selectedCategory == 'جنائي', onTap: () => ref.read(selectedCategoryProvider.notifier).setCategory('جنائي')),
              _CategoryCard(icon: Icons.account_balance_rounded, label: 'مدني', isSelected: selectedCategory == 'مدني', onTap: () => ref.read(selectedCategoryProvider.notifier).setCategory('مدني')),
              _CategoryCard(icon: Icons.family_restroom_rounded, label: 'أحوال شخصية', isSelected: selectedCategory == 'أحوال شخصية', onTap: () => ref.read(selectedCategoryProvider.notifier).setCategory('أحوال شخصية')),
              _CategoryCard(icon: Icons.business_center_rounded, label: 'تجاري', isSelected: selectedCategory == 'تجاري', onTap: () => ref.read(selectedCategoryProvider.notifier).setCategory('تجاري')),
            ]),
            const SizedBox(height: 26),
            Row(children: [const Expanded(child: Text('محامون مقترحون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary))), if (selectedCategory != null) TextButton(onPressed: () => ref.read(selectedCategoryProvider.notifier).setCategory(null), child: const Text('عرض الكل', style: TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 8),
            lawyersAsync.when(
              data: (lawyers) => lawyers.isEmpty ? const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: Column(children: [Icon(Icons.person_search_outlined, size: 60, color: AppColors.outline), SizedBox(height: 14), Text('لا يوجد محامون موثقون حالياً', style: TextStyle(color: AppColors.textSecondary))]))) : Column(children: lawyers.map((lawyer) => _LawyerCard(lawyer: lawyer)).toList()),
              loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: LoadingWidget())),
              error: (_, __) => const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('تعذر تحميل المحامين'))),
            ),
          ]))),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryCard({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isSelected ? AppColors.secondary : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppColors.gold : AppColors.outline), boxShadow: [if (!isSelected) BoxShadow(color: AppColors.secondary.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: isSelected ? AppColors.gold.withValues(alpha: .16) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isSelected ? AppColors.gold : AppColors.primaryDark)),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.secondary)),
      ]),
    ),
  );
}

class _LawyerCard extends StatelessWidget {
  final dynamic lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final avatar = lawyer.avatarUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outline), boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))]),
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => context.push('/lawyer-details/${lawyer.profileId}'), child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceVariant, border: Border.all(color: AppColors.gold, width: 2), image: avatar != null && avatar.isNotEmpty ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: avatar == null || avatar.isEmpty ? Center(child: Text((lawyer.fullName ?? 'م').toString().substring(0, 1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary))) : null),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(lawyer.fullName ?? 'محامي', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary))), if (lawyer.verified) const Icon(Icons.verified_rounded, color: AppColors.primaryDark, size: 18)]),
          const SizedBox(height: 4),
          Text(lawyer.specializations.isNotEmpty ? lawyer.specializations.join('، ') : 'قانون عام', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 17), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 5), Text('(${lawyer.reviewCount})', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), const Spacer(), if (lawyer.consultationPrice != null) Text('${lawyer.consultationPrice!.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary))]),
          const SizedBox(height: 10),
          Align(alignment: AlignmentDirectional.centerEnd, child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7), decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)), child: const Text('عرض الملف', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryDark)))),
        ])),
      ]))),
    );
  }
}
