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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('استشر محامياً بثقة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('اختر تخصصك وابحث عن المحامي المناسب', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text('التخصصات', textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = category;
                        context.push('/lawyers');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel_rounded, color: AppColors.gold, size: 28),
                            const SizedBox(height: 8),
                            Text(category, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('محامون مقترحون', textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface)),
              ),
            ),
            lawyers.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (items) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lawyer = items[index] as LawyerProfile;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        color: scheme.surfaceContainerHighest,
                        child: ListTile(
                          leading: CircleAvatar(backgroundImage: lawyer.avatarUrl != null ? NetworkImage(lawyer.avatarUrl!) : null, child: lawyer.avatarUrl == null ? const Icon(Icons.person) : null),
                          title: Text(lawyer.fullName, textAlign: TextAlign.right),
                          subtitle: Text(lawyer.specialization, textAlign: TextAlign.right),
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
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
