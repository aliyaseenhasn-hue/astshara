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
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((l) =>
          (l.fullName?.toLowerCase().contains(query) ?? false) ||
          l.specializations.any((s) => s.toLowerCase().contains(query)));
    }
    if (category != null && category.isNotEmpty) {
      final cleanCategory = category.trim();
      filtered = filtered.where((l) => l.specializations
          .any((s) => s.trim().toLowerCase() == cleanCategory.toLowerCase()));
    }

    final sortedList = filtered.toList();
    sortedList.sort((a, b) {
      if (a.availability && !b.availability) return -1;
      if (!a.availability && b.availability) return 1;
      final ratingCompare = b.rating.compareTo(a.rating);
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
    state = state == category ? null : category;
  }
}

@riverpod
Future<LawyerProfile?> lawyerProfile(LawyerProfileRef ref, String profileId) {
  return ref.watch(lawyersRepositoryProvider).getLawyerProfile(profileId);
}

final userNameProvider =
    FutureProvider.family<String?, String>((ref, profileId) async {
  final response = await SupabaseConfig.client
      .from('public_profiles')
      .select('full_name')
      .eq('id', profileId)
      .maybeSingle();
  return response?['full_name'] as String?;
});
