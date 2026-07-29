import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/lawyers_repository_impl.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../../domain/repositories/lawyers_repository.dart';

part 'lawyers_provider.g.dart';

@riverpod
LawyersRepository lawyersRepository(LawyersRepositoryRef ref) {
  // للاتصال بـ Supabase الحقيقي، اجعل هذه القيمة false
  const bool useMock = false;

  if (useMock) {
    return MockLawyersRepository();
  }
  return LawyersRepositoryImpl(SupabaseConfig.client);
}

class MockLawyersRepository implements LawyersRepository {
  @override
  Future<List<LawyerProfile>> getLawyers() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const LawyerProfile(
        id: '1',
        profileId: 'p1',
        fullName: 'أحمد علي',
        bio: 'محامٍ متخصص في القضايا المدنية والتجارية بخبرة تزيد عن 10 سنوات.',
        specialization: 'تجاري',
        licenseNumber: '12345',
        yearsExperience: 10,
        consultationPrice: 50000,
        rating: 4.8,
        reviewCount: 15,
        verified: true,
      ),
      const LawyerProfile(
        id: '2',
        profileId: 'p2',
        fullName: 'سارة محمود',
        bio: 'خبيرة في قانون الأحوال الشخصية وقضايا الأسرة.',
        specialization: 'أحوال شخصية',
        licenseNumber: '67890',
        yearsExperience: 8,
        consultationPrice: 40000,
        rating: 4.5,
        reviewCount: 22,
        verified: true,
      ),
      const LawyerProfile(
        id: '3',
        profileId: 'p3',
        fullName: 'محمد جاسم',
        bio: 'متخصص في قضايا العقارات والاستثمار.',
        specialization: 'مدني',
        licenseNumber: '11223',
        yearsExperience: 15,
        consultationPrice: 75000,
        rating: 5.0,
        reviewCount: 30,
        verified: true,
      ),
      const LawyerProfile(
        id: '4',
        profileId: 'p4',
        fullName: 'علي حسين',
        bio: 'محامي جنائي خبير في قضايا الجنايات والجنح.',
        specialization: 'جنائي',
        licenseNumber: '44556',
        yearsExperience: 12,
        consultationPrice: 60000,
        rating: 4.9,
        reviewCount: 18,
        verified: true,
      ),
    ];
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    final lawyers = await getLawyers();
    return lawyers.firstWhere((l) => l.profileId == profileId);
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {}

  @override
  Future<String> uploadDocument(String path, String fileName) async => '';
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
