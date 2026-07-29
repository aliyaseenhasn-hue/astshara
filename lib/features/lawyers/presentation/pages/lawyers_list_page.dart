import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyers_provider.dart';

class LawyersListPage extends ConsumerWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(lawyersListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('استشارة'),
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p20, vertical: AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن تخصص أو اسم محامي...',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p32),

            // Categories
            const Text(
              'التخصصات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.p12,
              mainAxisSpacing: AppSizes.p12,
              childAspectRatio: 1.5,
              children: [
                _CategoryCard(
                  icon: Icons.gavel,
                  label: 'جنائي',
                  isSelected: selectedCategory == 'جنائي',
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .setCategory('جنائي'),
                ),
                _CategoryCard(
                  icon: Icons.account_balance,
                  label: 'مدني',
                  isSelected: selectedCategory == 'مدني',
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .setCategory('مدني'),
                ),
                _CategoryCard(
                  icon: Icons.family_restroom,
                  label: 'أحوال شخصية',
                  isSelected: selectedCategory == 'أحوال شخصية',
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .setCategory('أحوال شخصية'),
                ),
                _CategoryCard(
                  icon: Icons.business_center,
                  label: 'تجاري',
                  isSelected: selectedCategory == 'تجاري',
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .setCategory('تجاري'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p32),

            // Top Rated Lawyers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المحامون الأعلى تقييماً',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (selectedCategory != null)
                  TextButton(
                    onPressed: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .setCategory(null),
                    child: const Text('إلغاء التصفية'),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'حجوزاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'المحامون'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/bookings');
          if (index == 3) context.push('/profile');
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary) : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 32, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final dynamic lawyer; // LawyerProfile

  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      child: InkWell(
        onTap: () => context.push('/lawyer-details/${lawyer.profileId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.person, size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lawyer.fullName ?? 'محامي',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(' ${lawyer.rating} ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lawyer.bio ?? 'لا يوجد وصف',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.outline),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lawyer.consultationPrice} د.ع',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        ElevatedButton(
                          onPressed: () => context
                              .push('/lawyer-details/${lawyer.profileId}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('حجز'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
