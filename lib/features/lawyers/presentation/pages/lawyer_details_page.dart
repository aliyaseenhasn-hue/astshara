import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';
import '../providers/lawyers_provider.dart';
import '../../domain/entities/lawyer_profile.dart';

class LawyerDetailsPage extends ConsumerWidget {
  final String profileId;
  const LawyerDetailsPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyerAsync = ref.watch(lawyerProfileProvider(profileId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: lawyerAsync.when(
        data: (lawyer) => lawyer == null
            ? const Center(child: Text('المهني غير موجود'))
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(context, lawyer),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(children: [
                            _buildStatItem('${lawyer.yearsExperience ?? 0}+', 'سنة خبرة'),
                            const SizedBox(width: 8),
                            _buildStatItem('${lawyer.rating.toStringAsFixed(1)}★', 'التقييم', color: AppColors.gold),
                            const SizedBox(width: 8),
                            _buildStatItem('${lawyer.reviewCount}', 'تقييم'),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildAboutCard(lawyer),
                            const SizedBox(height: 20),
                            const Text('باقات الاستشارة المتاحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 12),
                            if (lawyer.services.isEmpty)
                              const Text('لا توجد باقات استشارة محددة بعد.', style: TextStyle(fontSize: 12, color: Colors.grey))
                            else
                              ...lawyer.services.map((service) => _buildServicePackageCard(context, service, lawyer)),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('طلب استشارة بنوع مختلف'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const SizedBox(height: 24),
                            _buildReviewsSection(ref, lawyer),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                        child: ElevatedButton(
                          onPressed: lawyer.services.isEmpty ? null : () => context.push('/create-booking', extra: {'lawyer': lawyer}),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('حجز موعد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('تعذر تحميل الملف: $err')),
      ),
    );
  }

  Widget _buildServicePackageCard(BuildContext context, LawyerService service, LawyerProfile lawyer) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (service.description != null) ...[const SizedBox(height: 4), Text(service.description!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)],
              const SizedBox(height: 7),
              Text('${service.price.toStringAsFixed(0)} د.ع • ${service.durationMinutes} دقيقة', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('الطرق: ${service.consultationTypes.join('، ')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            ElevatedButton(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'service': service}), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('اختيار', style: TextStyle(fontSize: 12))),
          ]),
        ),
      );

  Widget _buildReviewsSection(WidgetRef ref, LawyerProfile lawyer) {
    final reviewsAsync = ref.watch(lawyerReviewsProvider(lawyer.profileId));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('تقييمات طالبي الخدمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const Spacer(),
        Text('${lawyer.rating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold)),
      ]),
      const SizedBox(height: 10),
      reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('تعذر تحميل التقييمات'),
        data: (reviews) => reviews.isEmpty
            ? const Text('لا توجد تقييمات بعد')
            : Column(children: reviews.take(5).map((review) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Text('${review.rating.toStringAsFixed(0)}★', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)), title: Text(review.comment.isEmpty ? 'بدون تعليق' : review.comment))).toList()),
      ),
    ]);
  }

  Widget _buildHeroSection(BuildContext context, LawyerProfile lawyer) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.secondary, AppColors.secondaryLight])),
        child: Column(children: [
          Align(alignment: Alignment.topRight, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward, color: Colors.white))),
          CircleAvatar(radius: 40, backgroundColor: AppColors.gold.withValues(alpha: 0.2), backgroundImage: lawyer.avatarUrl?.isNotEmpty == true ? NetworkImage(lawyer.avatarUrl!) : null, child: lawyer.avatarUrl?.isNotEmpty == true ? null : Text((lawyer.fullName ?? 'م')[0], style: const TextStyle(fontSize: 30, color: AppColors.gold, fontWeight: FontWeight.bold))),
          const SizedBox(height: 14),
          Text(lawyer.fullName ?? 'مهني', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            _buildBadge('✓ موثق'),
            if (lawyer.specializations.isNotEmpty) _buildBadge('⚖️ ${lawyer.specializations.join('، ')}'),
            _buildBadge('📍 بغداد'),
          ]),
        ]),
      );

  Widget _buildBadge(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))), child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)));

  Widget _buildStatItem(String value, String label, {Color? color}) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? AppColors.primary)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])));

  Widget _buildAboutCard(LawyerProfile lawyer) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نبذة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(lawyer.bio?.isNotEmpty == true ? lawyer.bio! : 'لا توجد نبذة تعريفية بعد.', style: const TextStyle(fontSize: 13, height: 1.5)),
        ]),
      );
}
