import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

class LawyersListPage extends ConsumerWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(lawyersListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Navy Header
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('صباح الخير 👋',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            Text('مرحباً بك في استشارة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.white38, size: 20),
                          SizedBox(width: 8),
                          Text('ابحث عن تخصص أو محامي...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Categories
                const Text(
                  'التخصصات',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _CategoryCard(
                      icon: Icons.gavel,
                      label: 'جنائي',
                      count: '12 محامي',
                      iconColor: const Color(0xFFC9A84C),
                      iconBg: const Color(0xFFFFFBF0),
                      isSelected: selectedCategory == 'جنائي',
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .setCategory('جنائي'),
                    ),
                    _CategoryCard(
                      icon: Icons.account_balance,
                      label: 'مدني',
                      count: '8 محامين',
                      iconColor: const Color(0xFF1B4F8A),
                      iconBg: const Color(0xFFEEF3FA),
                      isSelected: selectedCategory == 'مدني',
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .setCategory('مدني'),
                    ),
                    _CategoryCard(
                      icon: Icons.family_restroom,
                      label: 'أحوال شخصية',
                      count: '15 محامي',
                      iconColor: const Color(0xFF7B5EA7),
                      iconBg: const Color(0xFFF5F0F8),
                      isSelected: selectedCategory == 'أحوال شخصية',
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .setCategory('أحوال شخصية'),
                    ),
                    _CategoryCard(
                      icon: Icons.business_center,
                      label: 'تجاري',
                      count: '9 محامين',
                      iconColor: const Color(0xFF2E7D32),
                      iconBg: const Color(0xFFF0F8F0),
                      isSelected: selectedCategory == 'تجاري',
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .setCategory('تجاري'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Top Rated Lawyers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المحامون الأعلى تقييماً',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    if (selectedCategory != null)
                      TextButton(
                        onPressed: () => ref
                            .read(selectedCategoryProvider.notifier)
                            .setCategory(null),
                        child: const Text('الكل',
                            style: TextStyle(color: AppColors.accent)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                lawyersAsync.when(
                  data: (lawyers) => lawyers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('لا يوجد محامون في هذا التخصص حالياً'),
                          ),
                        )
                      : Column(
                          children: lawyers
                              .map((lawyer) => _LawyerCard(lawyer: lawyer))
                              .toList(),
                        ),
                  loading: () => const LoadingWidget(),
                  error: (err, stack) => Center(child: Text('خطأ: $err')),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: AppColors.surfaceVariant, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.outline.withValues(alpha: 0.5),
          currentIndex: 0,
          selectedLabelStyle:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined), label: 'حجوزاتي'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'المحادثات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'حسابي'),
          ],
          onTap: (index) {
            if (index == 1) context.push('/bookings');
            if (index == 3) context.push('/profile');
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color iconColor;
  final Color iconBg;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconColor,
    required this.iconBg,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBF0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    count,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final dynamic lawyer;

  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  (lawyer.fullName ?? 'م')[0],
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        lawyer.fullName ?? 'محامي',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      if (lawyer.verified)
                        const Icon(Icons.verified,
                            color: AppColors.accent, size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(lawyer.specialization as List<String>?)?.join(", ") ?? "قانون عام"} · بغداد',


                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lawyer.bio ?? 'لا يوجد وصف متاح',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.gold, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${lawyer.rating} ',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(${lawyer.reviewCount})',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${lawyer.consultationPrice} د.ع',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'احجز',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
