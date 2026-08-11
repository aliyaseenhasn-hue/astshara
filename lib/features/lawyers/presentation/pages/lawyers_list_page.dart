import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

/// دليل المحامين وفق شاشتي Stitch الفاتحة والداكنة.
class LawyersListPage extends ConsumerWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final lawyersAsync = ref.watch(lawyersListProvider);
    final title = selectedCategory == null ? 'دليل المحامين' : 'القانون ${selectedCategory == 'أحوال شخصية' ? 'للأحوال الشخصية' : selectedCategory}';

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF00483F) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DirectoryHeader(dark: dark, onNotifications: () => context.push('/notifications'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (dark) ...[
                  Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 27, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('ابحث عن نخبة المحامين والمستشارين القانونيين المعتمدين.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.5)),
                ] else ...[
                  Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 27, fontWeight: FontWeight.w800)),
                ],
                const SizedBox(height: 14),
                _SearchField(onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value),
                const SizedBox(height: 12),
                _FilterChips(selectedCategory: selectedCategory, onSelect: (value) => ref.read(selectedCategoryProvider.notifier).setCategory(value)),
                const SizedBox(height: 22),
                lawyersAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(50), child: Center(child: LoadingWidget())),
                  error: (_, __) => const _Message(text: 'تعذر تحميل المحامين'),
                  data: (lawyers) => lawyers.isEmpty ? const _Message(text: 'لا يوجد محامون موثقون حالياً') : Column(children: lawyers.map((lawyer) => _LawyerCard(lawyer: lawyer)).toList()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  final bool dark;
  final VoidCallback onNotifications;
  const _DirectoryHeader({required this.dark, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF00483F) : scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .12 : .55))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          IconButton(onPressed: onNotifications, icon: Icon(Icons.notifications_none_rounded, color: dark ? scheme.onSurface : scheme.onSurface)),
          const Spacer(),
          Text('استشارة', style: TextStyle(color: dark ? AppColors.gold : scheme.onSurface, fontSize: 19, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_forward_rounded, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      onChanged: onChanged,
      textDirection: TextDirection.rtl,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم، التخصص أو المدينة',
        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
        suffixIcon: Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .68),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .5))),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;
  const _FilterChips({required this.selectedCategory, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final values = <String?>[null, 'أحوال شخصية', 'تجاري', 'جنائي', 'مدني'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: values.map((value) {
          final selected = value == selectedCategory;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 7),
            child: ChoiceChip(
              selected: selected,
              label: Text(value ?? 'الكل'),
              onSelected: (_) => onSelect(value),
              selectedColor: dark ? AppColors.gold : AppColors.gold,
              backgroundColor: dark ? Colors.white.withValues(alpha: .06) : Colors.transparent,
              side: BorderSide(color: selected ? AppColors.gold : Theme.of(context).colorScheme.outline.withValues(alpha: .7)),
              labelStyle: TextStyle(color: selected ? AppColors.secondaryDark : Theme.of(context).colorScheme.onSurface, fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final dynamic lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final avatar = lawyer.avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final specializations = lawyer.specializations.isNotEmpty ? lawyer.specializations.take(2).join('، ') : 'قانون عام';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: .055) : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: .10) : scheme.outline),
        boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest, border: Border.all(color: AppColors.gold, width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: hasAvatar ? null : Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(lawyer.fullName ?? 'محامي', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800))), if (lawyer.verified) const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 17)]),
                      const SizedBox(height: 3),
                      Text(lawyer.specializations.isNotEmpty ? 'محامي ${specializations.split('،').first}' : 'محامي ومستشار قانوني', textAlign: TextAlign.right, style: TextStyle(color: dark ? AppColors.primaryLight : AppColors.primaryDark, fontSize: 11)),
                      const SizedBox(height: 7),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('(${lawyer.reviewCount} استشارة)', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)), const SizedBox(width: 5), const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 16), const SizedBox(width: 2), Text(lawyer.rating.toStringAsFixed(1), style: TextStyle(color: scheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.end, spacing: 6, runSpacing: 6, children: lawyer.specializations.take(2).map<Widget>((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: .08) : scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)), child: Text(s.toString(), style: TextStyle(color: scheme.onSurface, fontSize: 9))).toList()),
          const SizedBox(height: 8),
          Row(textDirection: TextDirection.rtl, children: [Icon(Icons.location_on_outlined, color: scheme.onSurfaceVariant, size: 16), const SizedBox(width: 4), Text('العراق', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)), const Spacer(), Icon(Icons.payments_outlined, color: scheme.onSurfaceVariant, size: 16), const SizedBox(width: 4), Text('${(lawyer.consultationPrice ?? 0).toStringAsFixed(0)} د.ع / للجلسة', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10))]),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => context.push('/lawyer-details/${lawyer.profileId}'),
              style: ElevatedButton.styleFrom(backgroundColor: dark ? AppColors.gold : AppColors.goldDark, foregroundColor: AppColors.secondaryDark),
              child: const Text('عرض الملف الشخصي'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
}
