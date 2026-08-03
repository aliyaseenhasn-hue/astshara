import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

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
            ? const Center(child: Text('المحامي غير موجود'))
            : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Section with Gradient
                        _buildHeroSection(context, lawyer),

                        // Stats Row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(
                            children: [
                              _buildStatItem(
                                  '${lawyer.yearsExperience}+', 'سنة خبرة'),
                              const SizedBox(width: 8),
                              _buildStatItem('${lawyer.rating}★', 'التقييم',
                                  color: AppColors.gold),
                              const SizedBox(width: 8),
                              _buildStatItem(
                                  '${lawyer.reviewCount}', 'استشارة'),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // About Card
                              _buildAboutCard(lawyer),
                              const SizedBox(height: 20),

                              // Services Row
                              const Text(
                                'أنواع الاستشارة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildServicesRow(lawyer),
                              const SizedBox(
                                  height: 100), // Space for bottom bar
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom CTA Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            top: BorderSide(
                                color: AppColors.surfaceVariant, width: 1)),
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/create-booking', extra: lawyer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 8),
                            Text('طلب استشارة الآن'),
                          ],
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

  Widget _buildHeroSection(BuildContext context, dynamic lawyer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.detailsGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    (lawyer.fullName ?? 'م')[0],
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.fullName ?? 'محامي',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const Text(
                      'محامي · عضو نقابة المحامين العراقيين',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge('✓ موثق'),
                        _buildBadge('⚖️ ${lawyer.specialization ?? "جنائي"}'),
                        _buildBadge('📍 بغداد'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(dynamic lawyer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gold, size: 16),
              SizedBox(width: 8),
              Text(
                'نبذة تعريفية',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lawyer.bio ??
                'محامي متخصص في القانون العراقي بخبرة طويلة في الدفاع والمشاورات القانونية.',
            style:
                const TextStyle(fontSize: 12, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesRow(dynamic lawyer) {
    final double price = lawyer.consultationPrice ?? 50000.0;
    return Row(
      children: [
        _buildServiceCard(
            Icons.chat_bubble_outline,
            'نصية',
            '${(price * 0.75).toInt()}',
            const Color(0xFFEEF3FA),
            const Color(0xFF1B4F8A)),
        const SizedBox(width: 8),
        _buildServiceCard(Icons.call_outlined, 'صوتية', '${price.toInt()}',
            const Color(0xFFFFFBF0), const Color(0xFFC9A84C)),
        const SizedBox(width: 8),
        _buildServiceCard(
            Icons.videocam_outlined,
            'فيديو',
            '${(price * 1.5).toInt()}',
            const Color(0xFFF0F8F0),
            const Color(0xFF2E7D32)),
      ],
    );
  }

  Widget _buildServiceCard(
      IconData icon, String label, String price, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(price,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}
