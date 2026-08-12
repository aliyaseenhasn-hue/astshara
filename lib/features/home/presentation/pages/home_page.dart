import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

/// الصفحة الرئيسية المطابقة لبنية شاشتي Stitch الفاتحة والداكنة.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _categories = <({IconData icon, String title, String value})>[
    (icon: Icons.gavel_rounded, title: 'جنائي', value: 'جنائي'),
    (icon: Icons.business_center_rounded, title: 'مدني', value: 'مدني'),
    (icon: Icons.family_restroom_rounded, title: 'أحوال شخصية', value: 'أحوال شخصية'),
    (icon: Icons.storefront_rounded, title: 'تجاري', value: 'تجاري'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lawyers = ref.watch(lawyersListProvider);
    final metadata = SupabaseConfig.client.auth.currentUser?.userMetadata;
    final name = (metadata?['full_name'] ?? metadata?['name'] ?? 'أحمد').toString();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HomeHeader(name: name, dark: dark, onNotifications: () => context.push('/notifications'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WelcomeHero(name: name, dark: dark),
                const SizedBox(height: 22),
                _SearchCard(onTap: () => context.go('/lawyers')),
                const SizedBox(height: 34),
                _SectionHeader(title: 'التخصصات القانونية', onAll: () => context.go('/lawyers')),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .94),
                  itemBuilder: (_, index) {
                    final category = _categories[index];
                    return _CategoryCard(category: category, onTap: () {
                      ref.read(selectedCategoryProvider.notifier).setCategory(category.value);
                      context.go('/lawyers');
                    });
                  },
                ),
                const SizedBox(height: 42),
                _SectionHeader(title: 'محامون مقترحون', onAll: () => context.go('/lawyers')),
                const SizedBox(height: 16),
                lawyers.when(
                  loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const _EmptyMessage(text: 'تعذر تحميل المحامين حالياً'),
                  data: (items) {
                    if (items.isEmpty) return const _EmptyMessage(text: 'لا يوجد محامون موثقون حالياً');
                    final shown = items.take(3).toList();
                    return SizedBox(
                      height: dark ? 260 : 250,
                      child: ListView.separated(
                        reverse: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, index) => _SuggestedLawyerCard(lawyer: shown[index]),
                      ),
                    );
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

class _HomeHeader extends StatelessWidget {
  final String name;
  final bool dark;
  final VoidCallback onNotifications;
  const _HomeHeader({required this.name, required this.dark, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 12, 24, 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111415) : scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .18 : .55))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          IconButton(onPressed: onNotifications, tooltip: 'التنبيهات', icon: Icon(Icons.notifications_none_rounded, color: scheme.onSurface, size: 27)),
          const Spacer(),
          Text('استشارة', style: TextStyle(color: dark ? AppColors.gold : scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          Row(textDirection: TextDirection.rtl, children: [
            CircleAvatar(radius: 25, backgroundColor: dark ? scheme.surfaceContainerHighest : const Color(0xFFE9EEF0), child: Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 27)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('أهلاً،', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)), Text(name, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800))]),
          ]),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final String name;
  final bool dark;
  const _WelcomeHero({required this.name, required this.dark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [scheme.primaryContainer, scheme.surfaceContainerHighest]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: dark ? AppColors.gold.withValues(alpha: .14) : scheme.primary.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(Icons.balance_rounded, color: dark ? AppColors.gold : scheme.primary, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('مرحباً ${name.isEmpty ? '' : name} 👋', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('احصل على الاستشارة القانونية المناسبة بخطوات بسيطة.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, height: 1.5)),
          ])),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .72), borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outline.withValues(alpha: .55))),
          child: Row(textDirection: TextDirection.rtl, children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.search_rounded, color: scheme.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text('ابحث عن تخصص، محامي، أو استشارة...', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5))),
            const SizedBox(width: 8),
            Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAll;
  const _SectionHeader({required this.title, required this.onAll});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(textDirection: TextDirection.rtl, children: [
      Expanded(child: Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 21, fontWeight: FontWeight.w800))),
      TextButton.icon(onPressed: onAll, icon: const Icon(Icons.arrow_back_rounded, size: 19), label: const Text('عرض الكل'), style: TextButton.styleFrom(foregroundColor: AppColors.goldDark, padding: EdgeInsets.zero)),
    ]);
  }
}

class _CategoryCard extends StatelessWidget {
  final ({IconData icon, String title, String value}) category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final goldIcon = category.title == 'مدني';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .82) : scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outline.withValues(alpha: .72)), boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 18, offset: const Offset(0, 6))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: goldIcon ? AppColors.gold.withValues(alpha: .2) : scheme.surfaceContainerHighest), child: Icon(category.icon, size: 31, color: goldIcon ? AppColors.goldDark : scheme.onSurface)),
            Text(category.title, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _SuggestedLawyerCard extends StatelessWidget {
  final dynamic lawyer;
  const _SuggestedLawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final avatar = lawyer.avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final specializations = lawyer.specializations.isNotEmpty ? lawyer.specializations.take(2).join('، ') : 'قانون عام';
    return SizedBox(
      width: dark ? 305 : 330,
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: dark ? scheme.surfaceContainerHighest.withValues(alpha: .78) : scheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: scheme.outline.withValues(alpha: .72)), boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 18, offset: const Offset(0, 7))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(textDirection: TextDirection.rtl, children: [
              Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest, border: Border.all(color: AppColors.gold, width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: hasAvatar ? null : Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 34)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(lawyer.fullName ?? 'محامي', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800))), if (lawyer.verified) const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 18)]),
                const SizedBox(height: 4),
                Text(specializations, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 7),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('(${lawyer.reviewCount} استشارة)', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)), const SizedBox(width: 6), const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 18), const SizedBox(width: 2), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.goldDark, fontSize: 13, fontWeight: FontWeight.bold))]),
              ])),
            ]),
            const Spacer(),
            Wrap(alignment: WrapAlignment.end, spacing: 7, runSpacing: 7, children: lawyer.specializations.take(2).map<Widget>((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(7)), child: Text(s.toString(), style: TextStyle(color: scheme.onSurface, fontSize: 10)))).toList()),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.location_on_outlined, color: scheme.onSurfaceVariant, size: 17), const SizedBox(width: 4), Text('العراق', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11))]),
          ]),
        ),
      )),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
}
