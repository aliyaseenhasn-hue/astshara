import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/lawyers_repository_impl.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../../domain/repositories/lawyers_repository.dart';

part 'lawyers_provider.g.dart';

@riverpod
LawyersRepository lawyersRepository(LawyersRepositoryRef ref) {
  return LawyersRepositoryImpl(SupabaseConfig.client);
}

final searchQueryProvider = StateProvider<String>((ref) => '');

@riverpod
Future<List<LawyerProfile>> lawyersList(LawyersListRef ref) {
  final category = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final repository = ref.watch(lawyersRepositoryProvider);

  return repository.getLawyers().then((lawyers) {
    Iterable<LawyerProfile> filtered = lawyers;

    // 1. الفلترة حسب البحث (الاسم أو التخصص)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((l) =>
          (l.fullName?.toLowerCase().contains(query) ?? false) ||
          l.specializations.any((s) => s.toLowerCase().contains(query)));
    }

    // 2. الفلترة حسب التخصص المختار من القائمة
    if (category != null && category.isNotEmpty) {
      final cleanCategory = category.trim();
      filtered = filtered.where((l) => l.specializations
          .any((s) => s.trim().toLowerCase() == cleanCategory.toLowerCase()));
    }

    // 3. الفرز (Sorting):
    final sortedList = filtered.toList();
    sortedList.sort((a, b) {
      if (a.availability && !b.availability) return -1;
      if (!a.availability && b.availability) return 1;

      int ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      return b.reviewCount.compareTo(a.reviewCount);
    });

    return sortedList;
  });
}

@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  void setCategory(String? category) {
    if (state == category) {
      state = null; // إلغاء الفلتر إذا ضغط مرتين
    } else {
      state = category;
    }
  }
}

@riverpod
Future<LawyerProfile?> lawyerProfile(LawyerProfileRef ref, String profileId) {
  return ref.watch(lawyersRepositoryProvider).getLawyerProfile(profileId);
}

// استخدام FutureProvider.family لتجنب مشاكل توليد الكود في البيئة الحالية
final userNameProvider =
    FutureProvider.family<String?, String>((ref, profileId) async {
  final response = await SupabaseConfig.client
      .from('profiles')
      .select('full_name')
      .eq('id', profileId)
      .maybeSingle();
  return response?['full_name'] as String?;
});
