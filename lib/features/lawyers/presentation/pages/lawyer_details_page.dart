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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ref.watch(lawyerProfileProvider(profileId)).when(
        loading: () => const Center(child: LoadingWidget()),
        error: (_, __) => Center(child: Text('تعذر تحميل الملف الشخصي', style: TextStyle(color: AppColors.onSurfaceVariant))),
        data: (lawyer) {
          if (lawyer == null) return const Center(child: Text('المحامي غير موجود', style: TextStyle(color: AppColors.onSurface)));
          final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامي';
          final avatar = lawyer.avatarUrl;
          return Stack(children: [
            CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.primary,
                surfaceTintColor: Colors.transparent,
                title: const Text('الملف الشخصي'),
                leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
              ),
              SliverToBoxAdapter(child: Column(children: [
                Container(height: 150, decoration: const BoxDecoration(color: AppColors.primary)),
                Transform.translate(
                  offset: const Offset(0, -56),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: AppColors.surface,
                    child: CircleAvatar(
                      radius: 53,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar == null || avatar.isEmpty
                          ? Text(name.substring(0, 1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary))
                          : null,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Flexible(child: Text(name, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700))),
                        if (lawyer.verified) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.verified_rounded, color: AppColors.secondaryLight, size: 20)),
                      ]),
                      const SizedBox(height: 6),
                      Text(lawyer.specializations.isEmpty ? 'محامي ومستشار قانوني' : lawyer.specializations.join('، '), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(height: 16),
                      _Stats(lawyer: lawyer),
                      const SizedBox(height: 18),
                      LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('طلب استشارة بنوع مختلف'),
                      ),
                      const SizedBox(height: 110),
                    ]),
                  ),
                ),
              ])),
            ]),
            Positioned(
              left: 14,
              right: 14,
              bottom: 8,
              child: SafeArea(
                top: false,
                child: Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}), icon: const Icon(Icons.calendar_month_rounded), label: const Text('حجز موعد استشارة'))),
                  const SizedBox(width: 10),
                  SizedBox(width: 98, child: OutlinedButton.icon(onPressed: () => context.push('/chats'), icon: const Icon(Icons.chat_bubble_outline_rounded), label: const Text('مراسلة', style: TextStyle(fontSize: 11)))),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final dynamic lawyer;
  const _Stats({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
      child: Row(children: [_item('${lawyer.reviewCount}', 'استشارة'), _divider(), _item('${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة'), _divider(), _item(lawyer.rating.toStringAsFixed(1), 'التقييم')]),
    );
  }

  Widget _divider() => Container(width: 1, height: 42, color: AppColors.outlineVariant);
  Widget _item(String value, String label) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant))]));
}
