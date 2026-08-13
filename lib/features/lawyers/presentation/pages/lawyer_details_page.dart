import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';
import '../widgets/lawyer_achievements_gallery.dart';

class LawyerDetailsPage extends ConsumerWidget {
  final String profileId;
  const LawyerDetailsPage({super.key, required this.profileId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: scheme.surface, body: ref.watch(lawyerProfileProvider(profileId)).when(
      loading: () => const Center(child: LoadingWidget()),
      error: (_, __) => Center(child: Text('تعذر تحميل الملف الشخصي', style: TextStyle(color: scheme.onSurfaceVariant))),
      data: (lawyer) {
        if (lawyer == null) return const Center(child: Text('المحامي غير موجود'));
        final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامي';
        final avatar = lawyer.avatarUrl;
        return Stack(children: [
          CustomScrollView(slivers: [
            SliverAppBar(pinned: true, backgroundColor: scheme.surface, foregroundColor: scheme.onSurface, title: const Text('الملف الشخصي'), leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded))),
            SliverToBoxAdapter(child: Column(children: [
              Container(height: 165, decoration: BoxDecoration(gradient: LinearGradient(colors: dark ? [AppColors.secondaryDark, AppColors.primaryDark] : [AppColors.secondary, AppColors.primaryDark]))),
              Transform.translate(offset: const Offset(0, -58), child: CircleAvatar(radius: 58, backgroundColor: scheme.surface, child: CircleAvatar(radius: 53, backgroundColor: scheme.surfaceContainerHighest, backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar == null || avatar.isEmpty ? Text(name.substring(0, 1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)) : null))),
              Transform.translate(offset: const Offset(0, -42), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 23, fontWeight: FontWeight.w800))), if (lawyer.verified) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 20))]), const SizedBox(height: 6), Text(lawyer.specializations.isEmpty ? 'محامي ومستشار قانوني' : lawyer.specializations.join('، '), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)), const SizedBox(height: 16), _Stats(lawyer: lawyer), const SizedBox(height: 18), LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false), const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}), icon: const Icon(Icons.edit_note_rounded), label: const Text('طلب استشارة بنوع مختلف'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))), const SizedBox(height: 110)]))),
            ])),
          ]),
          Positioned(left: 14, right: 14, bottom: 8, child: SafeArea(top: false, child: Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}), icon: const Icon(Icons.calendar_month_rounded), label: const Text('حجز موعد استشارة'), style: ElevatedButton.styleFrom(backgroundColor: dark ? AppColors.gold : AppColors.goldDark, foregroundColor: AppColors.secondaryDark, minimumSize: const Size.fromHeight(54)))), const SizedBox(width: 10), SizedBox(width: 98, child: OutlinedButton.icon(onPressed: () => context.push('/chats'), icon: const Icon(Icons.chat_bubble_outline_rounded), label: const Text('مراسلة', style: TextStyle(fontSize: 11)), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54))))]))),
        ]);
      },
    ));
  }
}

class _Stats extends StatelessWidget {
  final dynamic lawyer;
  const _Stats({required this.lawyer});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)), child: Row(children: [_item('${lawyer.reviewCount}', 'استشارة'), _divider(scheme), _item('${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة'), _divider(scheme), _item(lawyer.rating.toStringAsFixed(1), 'التقييم')]));
  }
  Widget _divider(ColorScheme s) => Container(width: 1, height: 42, color: s.outlineVariant);
  Widget _item(String value, String label) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 10))]));
}
