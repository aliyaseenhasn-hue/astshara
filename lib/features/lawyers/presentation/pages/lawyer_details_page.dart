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
          return Stack(children: [
            SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _buildHeroSection(context, lawyer),
                Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Row(children: [
                  _buildStatItem('${lawyer.yearsExperience}+', 'سنة خبرة'), const SizedBox(width: 8),
                  _buildStatItem('${lawyer.rating}★', 'التقييم', color: AppColors.gold), const SizedBox(width: 8),
                  _buildStatItem('${lawyer.reviewCount}', 'تقييم'),
                ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildAboutCard(lawyer), const SizedBox(height: 20),
                  LawyerAchievementsGallery(lawyerId: lawyer.profileId, editable: false), const SizedBox(height: 20),
                  const Text('باقات الاستشارة المتاحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 12),
                  if (lawyer.services.isEmpty) const Text('لم يقم المحامي بإضافة باقات استشارة محددة بعد.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else ...lawyer.services.map((service) => _buildServicePackageCard(context, service, lawyer)),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'isCustom': true}),
                    icon: const Icon(Icons.edit_note_rounded), label: const Text('طلب استشارة بنوع مختلف'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20), const Text('أنواع الاستشارة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 12),
                  _buildServicesRow(), const SizedBox(height: 120),
                ])),
              ]),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))], border: Border(top: BorderSide(color: AppColors.surfaceVariant))),
              child: SafeArea(child: ElevatedButton.icon(
                onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer}),
                icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                label: const Text('حجز موعد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            )),
          ]);
        },
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  Widget _buildServicePackageCard(BuildContext context, dynamic service, dynamic lawyer) => Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (service.description != null) ...[const SizedBox(height: 4), Text(service.description!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: 8), Text('${service.price} د.ع', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
      ])),
      ElevatedButton(onPressed: () => context.push('/create-booking', extra: {'lawyer': lawyer, 'service': service}), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('اختيار', style: TextStyle(fontSize: 12))),
    ])),
  );

  Widget _buildHeroSection(BuildContext context, dynamic lawyer) {
    final avatar = lawyer.avatarUrl;
    final hasAvatar = avatar != null && avatar!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.secondary, AppColors.secondaryLight])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Align(alignment: Alignment.topRight, child: InkWell(onTap: () => Navigator.pop(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22)))),
        const SizedBox(height: 10),
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(40), border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 2), image: hasAvatar ? DecorationImage(image: NetworkImage(avatar!), fit: BoxFit.cover) : null), child: hasAvatar ? null : Center(child: Text((lawyer.fullName ?? 'م')[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.gold)))),
        const SizedBox(height: 16), Text(lawyer.fullName ?? 'محامي', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text('محامي · عضو نقابة المحامين العراقيين', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white54)), const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [_buildBadge('✓ موثق'), _buildBadge('⚖️ ${lawyer.specializations.isNotEmpty ? lawyer.specializations.join('، ') : 'جنائي'}'), _buildBadge('📍 بغداد')]),
      ]),
    );
  }

  Widget _buildBadge(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))), child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)));
  Widget _buildStatItem(String value, String label, {Color? color}) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]), child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? AppColors.primary)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])));
  Widget _buildAboutCard(dynamic lawyer) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('نبذة عن المحامي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 10), Text(lawyer.bio?.isNotEmpty == true ? lawyer.bio! : 'لا توجد نبذة متاحة حالياً.', style: const TextStyle(fontSize: 13, height: 1.5))]));
  Widget _buildServicesRow() => Wrap(spacing: 8, runSpacing: 8, children: ['نصية', 'صوتية', 'فيديو'].map((type) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.surfaceVariant)), child: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList());
}
