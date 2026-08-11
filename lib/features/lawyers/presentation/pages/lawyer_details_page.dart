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
    final async = ref.watch(lawyerProfileProvider(profileId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => const Center(child: Text('تعذر تحميل الملف الشخصي')),
        data: (lawyer) {
          if (lawyer == null) return const Center(child: Text('المحامي غير موجود'));
          final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName! : 'محامي';
          final avatar = lawyer.avatarUrl;
          final hasAvatar = avatar != null && avatar.isNotEmpty;
          final initial = name.isNotEmpty ? name.substring(0, 1) : 'م';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 210,
                    backgroundColor: AppColors.secondaryDark,
                    foregroundColor: Colors.white,
                    centerTitle: true,
                    title: const Text(
                      'استشارة',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                    ),
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
                            child: Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceVariant,
                                  border: Border.all(color: AppColors.gold, width: 3),
                                  image: hasAvatar
                                      ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: hasAvatar
                                    ? null
                                    : Center(
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                      child: Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.balance_rounded, size: 18, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  lawyer.specializations.isEmpty ? 'محامي' : lawyer.specializations.join('، '),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                ),
                              ),
                              if (lawyer.verified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: AppColors.primaryDark, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.goldDark, size: 23),
                              const SizedBox(width: 5),
                              Text(
                                lawyer.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '(${lawyer.reviewCount} تقييم)',
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _Stats(lawyer: lawyer),
                          const SizedBox(height: 18),
                          _Tabs(lawyer: lawyer),
                          const SizedBox(height: 18),
                          LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/create-booking',
                                extra: {'lawyer': lawyer, 'isCustom': true},
                              ),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('طلب استشارة بنوع مختلف'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: AppColors.primaryDark),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
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
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final dynamic lawyer;
  const _Stats({required this.lawyer});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: .05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _item('${lawyer.yearsExperience ?? 0}+', 'سنوات الخبرة', Icons.work_outline_rounded),
            _divider(),
            _item(lawyer.rating.toStringAsFixed(1), 'التقييم', Icons.star_outline_rounded),
            _divider(),
            _item('${lawyer.reviewCount}', 'التقييمات', Icons.rate_review_outlined),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 56, color: AppColors.divider);

  Widget _item(String value, String label, IconData icon) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryDark, size: 24),
            const SizedBox(height: 7),
            Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _Tabs extends StatelessWidget {
  final dynamic lawyer;
  const _Tabs({required this.lawyer});

  @override
  Widget build(BuildContext context) => DefaultTabController(
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
                child: TabBarView(children: [_about(), _services(context), _reviews()]),
              ),
            ),
          ],
        ),
      );

  Widget _about() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(icon: Icons.person_outline_rounded, title: 'عن المحامي'),
            const SizedBox(height: 12),
            Text(
              lawyer.bio?.trim().isNotEmpty == true ? lawyer.bio! : 'لا توجد نبذة متاحة حالياً.',
              style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textPrimary),
            ),
            if (lawyer.specializations.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('التخصصات', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lawyer.specializations
                    .map<Widget>((s) => Chip(
                          label: Text(s),
                          backgroundColor: AppColors.surfaceVariant,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _services(BuildContext context) => lawyer.services.isEmpty
      ? const Center(
          child: Text(
            'لم يضف المحامي باقات استشارة محددة بعد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        )
      : ListView.separated(
          itemCount: lawyer.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final service = lawyer.services[i];
            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.gavel_rounded, color: AppColors.goldDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            if (service.description?.isNotEmpty == true)
                              Text(
                                service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${service.price.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/create-booking',
                        extra: {'lawyer': lawyer, 'service': service},
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('احجز هذه الباقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.gold,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

  Widget _reviews() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.gold, size: 42),
            const SizedBox(height: 8),
            Text(
              lawyer.rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.secondary),
            ),
            Text('${lawyer.reviewCount} تقييم', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            const Text(
              'تظهر تقييمات العملاء بعد إتمام الاستشارات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        ],
      );
}
