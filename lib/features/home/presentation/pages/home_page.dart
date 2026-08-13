import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/legal_specializations.dart';
import '../../../lawyers/data/models/lawyer_model.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lawyers = ref.watch(featuredLawyersProvider);
    final categories = LegalSpecializations.all.take(8).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          children: [
            Row(children: [
              Expanded(child: Text('استشارة', style: TextStyle(color: scheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900))),
              IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
            ]),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .42), borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('استشر محامياً متخصصاً', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('اختر المجال القانوني المناسب واحجز موعد استشارة بسهولة.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: () => context.push('/legal-categories'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('اختر التخصص')),
              ]),
            ),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: Text('التخصصات القانونية', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('عرض الكل')),
            ]),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
              itemBuilder: (_, i) {
                final c = categories[i];
                return InkWell(
                  onTap: () { ref.read(selectedCategoryProvider.notifier).setCategory(c['value'] as String); context.go('/lawyers'); },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(width: 58, height: 58, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(c['icon'] as IconData, color: AppColors.goldDark)),
                      Text(c['title'] as String, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => context.push('/legal-categories'), icon: const Icon(Icons.grid_view_rounded), label: Text('عرض جميع الفئات (${LegalSpecializations.all.length})')),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: Text('محامون مقترحون', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => context.go('/lawyers'), child: const Text('عرض الكل')),
            ]),
            const SizedBox(height: 12),
            lawyers.when(
              loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const Center(child: Text('تعذر تحميل المحامين حالياً')),
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('لا يوجد محامون موثقون حالياً'));
                final visible = items.take(3).toList();
                return SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final Lawyer l = visible[i];
                      final a = l.avatarUrl;
                      return SizedBox(
                        width: 285,
                        child: InkWell(
                          onTap: () => context.push('/lawyer-details/${l.profileId}'),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant)),
                            child: Column(children: [
                              CircleAvatar(radius: 34, backgroundColor: scheme.surfaceContainerHighest, backgroundImage: a != null && a.isNotEmpty ? NetworkImage(a) : null, child: a == null || a.isEmpty ? const Icon(Icons.person_rounded, size: 32) : null),
                              const SizedBox(height: 10),
                              Text(l.fullName ?? 'محامي', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(l.specializations.isEmpty ? 'قانون عام' : l.specializations.take(2).join('، '), textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                              const Spacer(),
                              Text('${l.rating.toStringAsFixed(1)} ★  •  ${l.reviewCount} استشارة', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
