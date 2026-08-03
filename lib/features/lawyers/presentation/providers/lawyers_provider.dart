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
    if (category == null) return lawyers;
    return lawyers.where((l) => l.specialization == category).toList();
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
