import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';
import '../widgets/lawyer_achievements_gallery.dart';

/// ملف المحامي العام وفق بنية Stitch مع الحفاظ على مسارات الحجز والتقييم الحالية.
class LawyerDetailsPage extends ConsumerWidget {
  final String profileId;
  const LawyerDetailsPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(lawyerProfileProvider(profileId));
    return Scaffold(
      backgroundColor: scheme.surface,
      body: async.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (_, __) => Center(child: Text('تعذر تحميل الملف الشخصي', style: TextStyle(color: scheme.onSurfaceVariant))),
        data: (lawyer) {
          if (lawyer == null) return Center(child: Text('المحامي غير موجود', style: TextStyle(color: scheme.onSurfaceVariant)));
          final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName! : 'محامي';
          final avatar = lawyer.avatarUrl;
          final hasAvatar = avatar != null && avatar.isNotEmpty;
          final initial = name.substring(0, 1);
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.onSurface,
                    centerTitle: true,
                    title: const Text('الملف الشخصي'),
                    actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
                    leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Container(
                          height: 175,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: dark ? const [Color(0xFF113C58), Color(0xFF1D6B8C)] : const [AppColors.secondary, AppColors.primaryDark]),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                bottom: -55,
                                child: Container(
                                  width: 118,
                                  height: 118,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 16)]),
                                  child: Container(
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest, border: Border.all(color: AppColors.gold, width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null),
                                    child: hasAvatar ? null : Center(child: Text(initial, style: TextStyle(color: scheme.onSurface, fontSize: 38, fontWeight: FontWeight.w800))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 66),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Flexible(child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 23, fontWeight: FontWeight.w800))),
                                if (lawyer.verified) ...[const SizedBox(width: 7), const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 20)],
                              ]),
                              const SizedBox(height: 6),
                              Text(lawyer.specializations.isEmpty ? 'محامي ومستشار قانوني' : lawyer.specializations.join('، '), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                              const SizedBox(height: 16),
                              _Stats(lawyer: lawyer),
                              const SizedBox(height: 16),
                              _ProfileTabs(lawyer: lawyer),
                              const SizedBox(height: 16),
                              LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}), icon: const Icon(Icons.edit_note_rounded), label: const Text('طلب استشارة بنوع مختلف'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: SafeArea(
                  top: false,
                  child: Row(
                    textDirection: Directionality.of(context),
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('حجز موعد استشارة'),
                          style: ElevatedButton.styleFrom(backgroundColor: dark ? AppColors.gold : AppColors.goldDark, foregroundColor: AppColors.secondaryDark, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(width: 98, child: OutlinedButton.icon(onPressed: () => context.push('/chats'), icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18), label: const Text('مراسلة', style: TextStyle(fontSize: 11)), style: OutlinedButton.styleFrom(backgroundColor: scheme.surface, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
                    ],
                  ),
                ),
              ),
            ],
          );
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
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outline), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 16, offset: const Offset(0, 5))]),
      child: Row(children: [_item('${lawyer.reviewCount}', 'استشارة', Icons.assignment_outlined), _divider(scheme), _item('${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة', Icons.work_outline_rounded), _divider(scheme), _item(lawyer.rating.toStringAsFixed(1), 'التقييم', Icons.star_outline_rounded)]),
    );
  }
  Widget _divider(ColorScheme scheme) => Container(width: 1, height: 48, color: scheme.outlineVariant);
  Widget _item(String value, String label, IconData icon) => Expanded(child: Column(children: [Icon(icon, color: AppColors.goldDark, size: 21), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10))]));
}

class _ProfileTabs extends StatelessWidget {
  final dynamic lawyer;
  const _ProfileTabs({required this.lawyer});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(labelColor: scheme.onSurface, unselectedLabelColor: scheme.onSurfaceVariant, indicatorColor: AppColors.goldDark, tabs: const [Tab(text: 'نبذة'), Tab(text: 'الخدمات'), Tab(text: 'التقييمات')]),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.surface, border: Border.all(color: scheme.outline), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))), child: SizedBox(height: 355, child: TabBarView(children: [_about(context), _services(context), _reviews(context)])),
      ]),
    );
  }
  Widget _about(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.person_outline_rounded, color: AppColors.primaryDark), const SizedBox(width: 7), Text('نبذة شخصية', style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.bold))]), const SizedBox(height: 10), Text(lawyer.bio?.trim().isNotEmpty == true ? lawyer.bio! : 'لا توجد نبذة متاحة حالياً.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 13, height: 1.75))]));
  }
  Widget _services(BuildContext context) => Center(child: Text('الخدمات والاستشارات المتاحة', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
  Widget _reviews(BuildContext context) => Center(child: Text('التقييمات', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
}
