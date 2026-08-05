import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

class LawyerDetailsPage extends ConsumerWidget {
  final String profileId;
  const LawyerDetailsPage({super.key, required this.profileId});

  void _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    // تنظيف الرقم من أي رموز زائدة
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri url = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

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

                              // Services Cards Section
                              const Text(
                                'باقات الاستشارة المتاحة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (lawyer.services.isEmpty)
                                const Text(
                                    'لم يقم المحامي بإضافة باقات استشارة محددة بعد.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              else
                                ...lawyer.services.map((service) =>
                                    _buildServicePackageCard(
                                        context, service, lawyer)),

                              const SizedBox(height: 24),

                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/create-booking', extra: {
                                  'lawyer': lawyer,
                                  'isCustom': true,
                                }),
                                icon: const Icon(Icons.edit_note_rounded),
                                label: const Text('طلب استشارة بنوع مختلف'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Contact Card
                              _buildContactCard(lawyer),
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
                                  height: 120), // Space for bottom bar
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                        border: Border(
                            top: BorderSide(
                                color: AppColors.surfaceVariant, width: 1)),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () => context.push('/create-booking',
                                    extra: {'lawyer': lawyer}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'حجز موعد',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _openWhatsApp(lawyer.whatsapp),
                                icon: const Icon(Icons.wechat,
                                    color: Colors.white),
                                tooltip: 'واتساب',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _makeCall(lawyer.whatsapp),
                                icon: const Icon(Icons.phone_in_talk,
                                    color: Colors.white),
                                tooltip: 'اتصال مباشر',
                              ),
                            ),
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

  Widget _buildServicePackageCard(
      BuildContext context, dynamic service, dynamic lawyer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${service.price} د.ع',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/create-booking', extra: {
                'lawyer': lawyer,
                'service': service,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('اختيار', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(dynamic lawyer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone_outlined,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'معلومات التواصل المباشر',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _makeCall(lawyer.whatsapp),
            child: Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  lawyer.whatsapp ?? 'غير متوفر',
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text('اتصل الآن',
                    style: TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
        ],
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
          colors: [
            AppColors.secondary,
            AppColors.secondaryLight
          ], // Navy Gradient
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4), width: 2),
              image: lawyer.avatarUrl != null && lawyer.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(lawyer.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: lawyer.avatarUrl == null || lawyer.avatarUrl!.isEmpty
                ? Center(
                    child: Text(
                      (lawyer.fullName ?? 'م')[0],
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            lawyer.fullName ?? 'محامي',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            'محامي · عضو نقابة المحامين العراقيين',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge('✓ موثق'),
              _buildBadge(
                  '⚖️ ${lawyer.specializations.isNotEmpty ? lawyer.specializations.join("، ") : "جنائي"}'),
              _buildBadge('📍 بغداد'),
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
