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
      backgroundColor: scheme.surface,
      body: ref.watch(lawyerProfileProvider(profileId)).when(
        loading: () => const Center(child: LoadingWidget()),
        error: (_, __) => Center(child: Text('تعذر تحميل الملف الشخصي', style: TextStyle(color: scheme.onSurfaceVariant))),
        data: (lawyer) {
          if (lawyer == null) return Center(child: Text('المحامي غير موجود', style: TextStyle(color: scheme.onSurface)));
          final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامي';
          final avatar = lawyer.avatarUrl;
          return Stack(children: [
            CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: scheme.surface,
                foregroundColor: scheme.onSurface,
                surfaceTintColor: Colors.transparent,
                title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.w800)),
                leading: IconButton(tooltip: 'رجوع', onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
              ),
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primary, scheme.primaryContainer])),
                    ),
                    Positioned(
                      top: 90,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 59,
                          backgroundColor: scheme.surface,
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: scheme.surfaceContainerHighest,
                            backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar == null || avatar.isEmpty
                                ? Text(name.substring(0, 1), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: scheme.primary))
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 110, 20, 110),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900))),
                          if (lawyer.verified) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.verified_rounded, color: scheme.primary, size: 20)),
                        ]),
                        const SizedBox(height: 6),
                        Text(lawyer.specializations.isEmpty ? 'محامي ومستشار قانوني' : lawyer.specializations.join('، '), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4)),
                        const SizedBox(height: 16),
                        _Stats(lawyer: lawyer),
                        const SizedBox(height: 18),
                        LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}), icon: const Icon(Icons.edit_note_rounded), label: const Text('طلب استشارة بنوع مختلف', style: TextStyle(fontWeight: FontWeight.w700)))),
                      ]),
                    ),
                  ],
                ),
              ),
            ]),
            Positioned(
              left: 14,
              right: 14,
              bottom: 8,
              child: SafeArea(top: false, child: Row(children: [
                Expanded(child: SizedBox(height: 52, child: ElevatedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}), icon: const Icon(Icons.calendar_month_rounded), label: const Text('حجز موعد استشارة', style: TextStyle(fontWeight: FontWeight.w900))))),
                const SizedBox(width: 10),
                SizedBox(width: 100, height: 52, child: OutlinedButton.icon(onPressed: () => context.push('/chats'), icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18), label: const Text('مراسلة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))),
              ])),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)),
      child: Row(children: [_item(context, '${lawyer.reviewCount}', 'استشارة'), _divider(context), _item(context, '${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة'), _divider(context), _item(context, lawyer.rating.toStringAsFixed(1), 'التقييم')]),
    );
  }

  Widget _divider(BuildContext context) => Container(width: 1, height: 42, color: Theme.of(context).colorScheme.outlineVariant);
  Widget _item(BuildContext context, String value, String label) => Expanded(child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}
