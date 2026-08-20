import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

/// دليل المحامين — واجهة RTL متجاوبة ومتوافقة مع هوية Stitch.
class LawyersListPage extends ConsumerWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final lawyersAsync = ref.watch(lawyersListProvider);
    final title = selectedCategory == null
        ? 'دليل المحامين'
        : 'القانون ${selectedCategory == 'أحوال شخصية' ? 'للأحوال الشخصية' : selectedCategory}';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DirectoryHeader(onNotifications: () => context.push('/notifications'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(title, textAlign: TextAlign.right, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('ابحث عن نخبة المحامين والمستشارين القانونيين المعتمدين.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.5)),
                const SizedBox(height: 16),
                _SearchField(onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value),
                const SizedBox(height: 12),
                _FilterChips(selectedCategory: selectedCategory, onSelect: (value) => ref.read(selectedCategoryProvider.notifier).setCategory(value)),
                const SizedBox(height: 20),
                lawyersAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(50), child: Center(child: LoadingWidget())),
                  error: (_, __) => const _Message(text: 'تعذر تحميل المحامين. حاول مرة أخرى.'),
                  data: (lawyers) => lawyers.isEmpty ? const _Message(text: 'لا يوجد محامون موثقون حالياً') : Column(children: lawyers.map<Widget>((lawyer) => _LawyerCard(lawyer: lawyer)).toList()),
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
  final VoidCallback onNotifications;
  const _DirectoryHeader({required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 8, 18, 10),
      decoration: BoxDecoration(color: scheme.surface, border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
      child: Row(textDirection: TextDirection.rtl, children: [
        IconButton(tooltip: 'التنبيهات', onPressed: onNotifications, icon: Icon(Icons.notifications_none_rounded, color: scheme.onSurface)),
        const Spacer(),
        Text('استشارة', style: TextStyle(color: scheme.primary, fontSize: 19, fontWeight: FontWeight.w900)),
        const Spacer(),
        IconButton(tooltip: 'رجوع', onPressed: () => context.pop(), icon: Icon(Icons.arrow_forward_rounded, color: scheme.onSurface)),
      ]),
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
      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم، التخصص أو المدينة',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
        suffixIcon: Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
        fillColor: scheme.surfaceContainerLowest,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.primary, width: 1.7)),
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
    final scheme = Theme.of(context).colorScheme;
    const values = <String?>[null, 'أحوال شخصية', 'تجاري', 'جنائي', 'مدني'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(children: values.map((value) {
        final selected = value == selectedCategory;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 7),
          child: ChoiceChip(
            selected: selected,
            label: Text(value ?? 'الكل'),
            onSelected: (_) => onSelect(value),
            selectedColor: scheme.primaryContainer,
            backgroundColor: scheme.surfaceContainerLowest,
            side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
            labelStyle: TextStyle(color: selected ? scheme.onPrimaryContainer : scheme.onSurface, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }).toList()),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final dynamic lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = lawyer.avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final tags = lawyer.specializations.isNotEmpty ? lawyer.specializations.take(2).toList() : ['قانون عام'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
          borderRadius: BorderRadius.circular(12),
          child: Row(textDirection: TextDirection.rtl, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 66, height: 66, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest, border: Border.all(color: scheme.primary.withValues(alpha: .55), width: 1.5), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null), child: hasAvatar ? null : Icon(Icons.person_rounded, color: scheme.onSurfaceVariant, size: 32)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(lawyer.fullName ?? 'محامي', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w900))), if (lawyer.verified) ...[const SizedBox(width: 5), Icon(Icons.verified_rounded, color: scheme.primary, size: 17)]]),
              const SizedBox(height: 4),
              Text(lawyer.specializations.isNotEmpty ? 'محامي ${tags.first}' : 'محامي ومستشار قانوني', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.star_rounded, color: scheme.tertiary, size: 16), const SizedBox(width: 2), Text(lawyer.rating.toStringAsFixed(1), style: TextStyle(color: scheme.onSurface, fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(width: 7), Text('تقييم المحامي', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10))]),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.end, spacing: 6, runSpacing: 6, children: tags.map<Widget>((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)), child: Text(tag.toString(), style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 9, fontWeight: FontWeight.w600)))).toList()),
        const SizedBox(height: 10),
        Row(textDirection: TextDirection.rtl, children: [Icon(Icons.location_on_outlined, color: scheme.onSurfaceVariant, size: 15), const SizedBox(width: 4), Text('العراق', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)), const Spacer(), Icon(Icons.payments_outlined, color: scheme.onSurfaceVariant, size: 15), const SizedBox(width: 4), Text('${(lawyer.consultationPrice ?? 0).toStringAsFixed(0)} د.ع / الجلسة', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),
        SizedBox(height: 46, child: ElevatedButton(onPressed: () => context.push('/lawyer-details/${lawyer.profileId}'), style: ElevatedButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, textStyle: const TextStyle(fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('عرض الملف الشخصي'))),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5))));
}
