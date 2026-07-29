import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

class LawyerDetailsPage extends ConsumerWidget {
  final String profileId;
  const LawyerDetailsPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyerAsync = ref.watch(lawyerProfileProvider(profileId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        ],
      ),
      body: lawyerAsync.when(
        data: (lawyer) => lawyer == null
            ? const Center(child: Text('المحامي غير موجود'))
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSizes.p20,
                      right: AppSizes.p20,
                      top: AppSizes.p16,
                      bottom: 100, // مساحة للزر العائم في الأسفل
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Header
                        _buildProfileHeader(lawyer),
                        const SizedBox(height: AppSizes.p24),

                        // Stats Grid
                        _buildStatsGrid(lawyer),
                        const SizedBox(height: AppSizes.p24),

                        // About Section
                        _buildAboutSection(lawyer),
                        const SizedBox(height: AppSizes.p24),

                        // Services Section
                        const Text(
                          'خدمات الاستشارة',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSizes.p16),
                        _buildServicesGrid(lawyer),
                        const SizedBox(height: AppSizes.p24),

                        // Reviews Section
                        _buildReviewsSection(lawyer),
                      ],
                    ),
                  ),

                  // Fixed Button at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/create-booking', extra: lawyer),
                        icon: const Icon(Icons.event_available),
                        label: const Text('طلب استشارة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic lawyer) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              if (lawyer.verified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(Icons.verified,
                        color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            lawyer.fullName ?? 'محامي',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const Text(
            'محامي متخصص في القانون التجاري والجنائي',
            style: TextStyle(color: AppColors.outline),
          ),
          const SizedBox(height: AppSizes.p12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(Icons.location_on, 'بغداد، العراق'),
              const SizedBox(width: 8),
              _buildBadge(Icons.work, 'محامي استئناف'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.outline),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic lawyer) {
    return Row(
      children: [
        _buildStatItem('${lawyer.yearsExperience}+', 'سنوات خبرة'),
        const SizedBox(width: 12),
        _buildStatItem('98%', 'نسبة النجاح'),
        const SizedBox(width: 12),
        _buildStatItem('1.2K', 'استشارة'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(dynamic lawyer) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text('نبذة تعريفية',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lawyer.bio ?? 'لا يوجد وصف',
            style: const TextStyle(height: 1.6, color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(dynamic lawyer) {
    return Row(
      children: [
        _buildServiceItem(Icons.chat, 'مراسلة نصية',
            '${(lawyer.consultationPrice * 0.5).toInt()}'),
        const SizedBox(width: 8),
        _buildServiceItem(
            Icons.call, 'مكالمة صوتية', '${lawyer.consultationPrice}'),
        const SizedBox(width: 8),
        _buildServiceItem(Icons.videocam, 'مكالمة فيديو',
            '${(lawyer.consultationPrice * 1.5).toInt()}'),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String label, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$price د.ع',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(dynamic lawyer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('تقييمات العملاء',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${lawyer.rating} (${lawyer.reviewCount} تقييم)',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewCard('م. ح.',
            'استشارة ممتازة ومفيدة جداً. الأستاذ كان مستمعاً جيداً وقدم لي حلولاً قانونية واضحة.'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: const BorderSide(color: AppColors.primary)),
          child: const Text('عرض المزيد من التقييمات'),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String name, String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
                5,
                (index) =>
                    const Icon(Icons.star, color: Colors.amber, size: 14)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(comment,
              style: const TextStyle(fontSize: 13, color: AppColors.outline)),
        ],
      ),
    );
  }
}
