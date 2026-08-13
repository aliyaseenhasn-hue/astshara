import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/legal_specializations.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  static const categories = <Map<String, dynamic>>[
    {'icon': Icons.gavel_rounded, 'title': 'جنائي', 'value': 'جنائي'},
    {'icon': Icons.business_center_rounded, 'title': 'مدني', 'value': 'مدني'},
    {'icon': Icons.family_restroom_rounded, 'title': 'أحوال شخصية', 'value': 'أحوال شخصية'},
    {'icon': Icons.storefront_rounded, 'title': 'تجاري', 'value': 'تجاري'},
    {'icon': Icons.admin_panel_settings_outlined, 'title': 'إداري', 'value': 'إداري'},
    {'icon': Icons.security_rounded, 'title': 'قوى الأمن الداخلي', 'value': 'قوى الأمن الداخلي'},
    {'icon': Icons.apartment_rounded, 'title': 'شركات', 'value': 'شركات'},
    {'icon': Icons.home_work_outlined, 'title': 'تسجيل عقاري', 'value': 'تسجيل عقاري'},
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lawyers = ref.watch(lawyersListProvider);
    final metadata = SupabaseConfig.client.auth.currentUser?.userMetadata;
    final name = (metadata?['full_name'] ?? metadata?['name'] ?? 'أحمد').toString();
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 10, 20, 14), child: Row(children: [IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)), const Spacer(), const Text('استشارة', style: TextStyle(color: AppColors.goldDark, fontSize: 22, fontWeight: FontWeight.w800)), const Spacer(), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('أهلاً،', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)), Text(name, style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800))])]))) ,
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), sliver: SliverList(delegate: SliverChildListDelegate([
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.surfaceContainerHighest]), borderRadius: BorderRadius.circular(22)), child: Row(children: [const Icon(Icons.balance_rounded, color: AppColors.goldDark, size: 32), const SizedBox(width: 14), Expanded(child: Text('مرحباً ${name.isEmpty ? '' : name} 👋\nاحصل على الاستشارة القانونية المناسبة بخطوات بسيطة.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 15, height: 1.6, fontWeight: FontWeight.w700)))])),
          const SizedBox(height: 20),
          InkWell(onTap: () => context.go('/lawyers'), borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)), child: Row(children: [Icon(Icons.search_rounded, color: scheme.primary), const SizedBox(width: 12), Expanded(child: Text('ابحث عن تخصص، محامي، أو استشارة...', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant))), const Icon(Icons.tune_rounded)]))),
          const SizedBox(height: 30),
          Row(children: [Expanded(child: Text('التخصصات القانونية', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800))), TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('عرض الكل'))]),
          const SizedBox(height: 12),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: categories.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05), itemBuilder: (_, i) { final c = categories[i]; return InkWell(onTap: () { ref.read(selectedCategoryProvider.notifier).setCategory(c['value'] as String); context.go('/lawyers'); }, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(c['icon'] as IconData, color: AppColors.goldDark)), Text(c['title'] as String, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700))]))); }),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => context.push('/legal-categories'), icon: const Icon(Icons.grid_view_rounded), label: Text('عرض جميع الفئات (${LegalSpecializations.all.length})')),
          const SizedBox(height: 30),
          Row(children: [Expanded(child: Text('محامون مقترحون', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800))), TextButton(onPressed: () => context.go('/lawyers'), child: const Text('عرض الكل'))]),
          const SizedBox(height: 12),
          lawyers.when(loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())), error: (_, __) => const Center(child: Text('تعذر تحميل المحامين حالياً')), data: (items) => items.isEmpty ? const Center(child: Text('لا يوجد محامون موثقون حالياً')) : SizedBox(height: 240, child: ListView.separated(scrollDirection: Axis.horizontal, reverse: true, itemCount: items.take(3).length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) { final l = items[i]; final a = l.avatarUrl; return SizedBox(width: 285, child: InkWell(onTap: () => context.push('/lawyer-details/${l.profileId}'), borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant)), child: Column(children: [CircleAvatar(radius: 34, backgroundColor: scheme.surfaceContainerHighest, backgroundImage: a != null && a.isNotEmpty ? NetworkImage(a) : null, child: a == null || a.isEmpty ? const Icon(Icons.person_rounded, size: 32) : null), const SizedBox(height: 10), Text(l.fullName ?? 'محامي', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(l.specializations.isEmpty ? 'قانون عام' : l.specializations.take(2).join('، '), textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)), const Spacer(), Text('${l.rating.toStringAsFixed(1)} ★  •  ${l.reviewCount} استشارة', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11))])))); }))
        ])))
      ]),
    );
  }
}
