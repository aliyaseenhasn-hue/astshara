import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/legal_specializations.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lawyers = ref.watch(lawyersListProvider);
    final categories = LegalSpecializations.all.take(8).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'استشر محامياً بثقة',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر تخصصك وابحث عن المحامي المناسب',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'التخصصات القانونية',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return Material(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).setCategory(category);
                          context.push('/lawyers');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight.withValues(alpha: .45),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.gavel_rounded, color: AppColors.gold, size: 23),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                      height: 1.25,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.18,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'محامون مقترحون',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/lawyers'),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                ),
              ),
            ),
            lawyers.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('تعذر تحميل المحامين حالياً', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ),
              data: (items) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lawyer = items[index] as LawyerProfile;
                    final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامٍ';
                    final specialization = lawyer.specializations.isNotEmpty ? lawyer.specializations.join('، ') : 'استشارات قانونية';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                      child: Card(
                        color: scheme.surfaceContainerLowest,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.goldLight.withValues(alpha: .45),
                            backgroundImage: lawyer.avatarUrl != null && lawyer.avatarUrl!.isNotEmpty ? NetworkImage(lawyer.avatarUrl!) : null,
                            child: lawyer.avatarUrl == null || lawyer.avatarUrl!.isEmpty ? const Icon(Icons.person_outline, color: AppColors.goldDark) : null,
                          ),
                          title: Text(name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(specialization, textAlign: TextAlign.right),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () => context.push('/lawyers/${lawyer.id}'),
                        ),
                      ),
                    );
                  },
                  childCount: items.length > 6 ? 6 : items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }
}
