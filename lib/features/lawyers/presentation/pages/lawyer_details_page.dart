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
    final lawyerAsync = ref.watch(lawyerProfileProvider(profileId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: lawyerAsync.when(
        data: (lawyer) {
          if (lawyer == null) return const Center(child: Text('المحامي غير موجود'));
          final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName! : 'محامي';
          final avatar = lawyer.avatarUrl;
          final hasAvatar = avatar != null && avatar.isNotEmpty;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 210,
                    backgroundColor: AppColors.secondaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    title: const Text('استشارة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold)),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.secondaryDark, AppColors.secondary],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 58),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceVariant,
                                    border: Border.all(color: AppColors.gold, width: 3),
                                    image: hasAvatar ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
                                  ),
                                  child: hasAvatar ? null : Center(child: Text(name.characters.first, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        children: [
                          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.balance_rounded, size: 18, color: AppColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(lawyer.specializations.isEmpty ? 'محامي' : lawyer.specializations.join('، '), style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                            if (lawyer.verified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded, color: AppColors.primaryDark, size: 18),
                            ],
                          ]),
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 23),
                            const SizedBox(width: 5),
                            Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(width: 5),
                            Text('(${lawyer.reviewCount} تقييم)', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 22),
                          _StatsCard(lawyer: lawyer),
                          const SizedBox(height: 18),
                          _ProfileTabs(lawyer: lawyer),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}),
                          icon: const Icon(Icons.calendar_month_rounded, color: AppColors.secondaryDark),
                          label: const Text('حجز موعد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.secondaryDark,
                            minimumSize: const Size.fromHeight(58),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 92,
                        height: 58,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/chats'),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          label: const Text('مراسلة', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('تعذر تحميل الملف الشخصي')),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final dynamic lawyer;
  const _StatsCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
        boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _item(Icons.calendar_month_outlined, '${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة'),
          _divider(),
          _item(Icons.business_center_outlined, _consultationCount(lawyer), 'استشارة'),
          _divider(),
          _item(Icons.verified_user_outlined, '${lawyer.availability ? 100 : 0}%', 'نسبة الرد'),
        ],
      ),
    );
  }

  String _consultationCount(dynamic lawyer) => lawyer.reviewCount > 0 ? '${lawyer.reviewCount}' : '—';

  Widget _divider() => Container(width: 1, height: 58, color: AppColors.divider);

  Widget _item(IconData icon, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: AppColors.primaryDark, size: 25),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.secondary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _ProfileTabs extends StatelessWidget {
  final dynamic lawyer;
  const _ProfileTabs({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
            child: const TabBar(
              indicatorColor: AppColors.gold,
              indicatorWeight: 3,
              labelColor: AppColors.gold,
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [Tab(text: 'نبذة'), Tab(text: 'الخدمات'), Tab(text: 'التقييمات')],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border.all(color: AppColors.outline),
            ),
            child: SizedBox(
              height: 360,
              child: TabBarView(children: [
                _AboutTab(lawyer: lawyer),
                _ServicesTab(lawyer: lawyer),
                _ReviewsTab(lawyer: lawyer),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final dynamic lawyer;
  const _AboutTab({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final bio = lawyer.bio?.trim();
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.person_outline_rounded, title: 'عن المحامي'),
        const SizedBox(height: 12),
        Text(bio?.isNotEmpty == true ? bio! : 'لا توجد نبذة متاحة حالياً.', style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textPrimary)),
        if (lawyer.specializations.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('التخصصات', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: lawyer.specializations.map<Widget>((s) => Chip(label: Text(s), backgroundColor: AppColors.surfaceVariant, side: BorderSide.none)).toList()),
        ],
      ]),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final dynamic lawyer;
  const _ServicesTab({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    if (lawyer.services.isEmpty) return const Center(child: Text('لم يضف المحامي باقات استشارة محددة بعد.', style: TextStyle(color: AppColors.textSecondary)));
    return ListView.separated(
      itemCount: lawyer.services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final service = lawyer.services[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.gavel_rounded, color: AppColors.goldDark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              if (service.description?.isNotEmpty == true) Text(service.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Text('${service.price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          ]),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final dynamic lawyer;
  const _ReviewsTab({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.star_rounded, color: AppColors.gold, size: 42),
        const SizedBox(height: 8),
        Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        Text('${lawyer.reviewCount} تقييم', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        const Text('التقييمات التفصيلية ستظهر هنا عند توفرها.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.primaryDark, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
      ]);
}
