import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/legal_specializations.dart';
import '../providers/lawyers_provider.dart';

class LegalCategoriesPage extends ConsumerWidget {
  const LegalCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('الفئات'),
        centerTitle: true,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
        ),
        itemCount: LegalSpecializations.all.length,
        itemBuilder: (context, index) {
          final category = LegalSpecializations.all[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).setCategory(category);
                context.push('/lawyers');
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                padding: const EdgeInsets.all(14),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_rounded, color: scheme.primary, size: 27),
                      const SizedBox(height: 8),
                      Text(category, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
