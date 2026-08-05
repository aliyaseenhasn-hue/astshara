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

@riverpod
Future<List<LawyerProfile>> lawyersList(LawyersListRef ref) {
  final category = ref.watch(selectedCategoryProvider);
  final repository = ref.watch(lawyersRepositoryProvider);

  return repository.getLawyers().then((lawyers) {
    // 1. الفلترة حسب التخصص (مع تنظيف النصوص لضمان المطابقة)
    Iterable<LawyerProfile> filtered = lawyers;
    if (category != null && category.isNotEmpty) {
      final cleanCategory = category.trim();
      filtered = lawyers.where((l) => l.specializations
          .any((s) => s.trim().toLowerCase() == cleanCategory.toLowerCase()));
    }

    // 2. الفرز (Sorting):
    // - المحامي المتصل أولاً (اختياري)
    // - ثم حسب التقييم (Rating) من الأعلى للأقل
    // - ثم حسب عدد المراجعات (Review Count)
    final sortedList = filtered.toList();
    sortedList.sort((a, b) {
      // 1. التوفر (اختياري، يمكن إزالته إذا لم يكن مطلوباً)
      if (a.availability && !b.availability) return -1;
      if (!a.availability && b.availability) return 1;

      // 2. التقييم (من الأعلى للأقل)
      int ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      // 3. عدد المراجعات
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
