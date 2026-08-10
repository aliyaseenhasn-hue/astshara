import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/lawyers_repository_impl.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../../domain/repositories/lawyers_repository.dart';
part 'lawyers_provider.g.dart';

@riverpod
LawyersRepository lawyersRepository(LawyersRepositoryRef ref) => LawyersRepositoryImpl(SupabaseConfig.client);

final searchQueryProvider = StateProvider<String>((ref) => '');

String _normalizeSpecialization(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[إأآ]'), 'ا').replaceAll('ة', 'ه');
}

bool _matchesCategory(LawyerProfile lawyer, String category) {
  final wanted = _normalizeSpecialization(category);
  return lawyer.specializations.any((specialization) {
    final actual = _normalizeSpecialization(specialization);
    return actual == wanted || actual.contains(wanted) || wanted.contains(actual);
  });
}

@riverpod
Future<List<LawyerProfile>> lawyersList(LawyersListRef ref) {
  final category = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final repository = ref.watch(lawyersRepositoryProvider);
  return repository.getLawyers().then((lawyers) {
    Iterable<LawyerProfile> filtered = lawyers;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered = filtered.where((l) =>
          (l.fullName?.toLowerCase().contains(q) ?? false) ||
          l.specializations.any((s) => s.toLowerCase().contains(q)));
    }
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((l) => _matchesCategory(l, category));
    }
    final list = filtered.toList()
      ..sort((a, b) {
        if (a.availability && !b.availability) return -1;
        if (!a.availability && b.availability) return 1;
        final r = b.rating.compareTo(a.rating);
        return r != 0 ? r : b.reviewCount.compareTo(a.reviewCount);
      });
    return list;
  });
}

@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  void setCategory(String? category) => state == category ? state = null : state = category;
}

@riverpod
Future<LawyerProfile?> lawyerProfile(LawyerProfileRef ref, String profileId) =>
    ref.watch(lawyersRepositoryProvider).getLawyerProfile(profileId);

final userNameProvider = FutureProvider.family<String?, String>((ref, profileId) async {
  final profile = await SupabaseConfig.client
      .from('profiles')
      .select('full_name')
      .eq('id', profileId)
      .maybeSingle();
  final profileName = profile?['full_name'] as String?;
  if (profileName != null && profileName.trim().isNotEmpty) return profileName;

  final lawyer = await SupabaseConfig.client
      .from('lawyer_profiles')
      .select('full_name')
      .eq('profile_id', profileId)
      .maybeSingle();
  return lawyer?['full_name'] as String?;
});
