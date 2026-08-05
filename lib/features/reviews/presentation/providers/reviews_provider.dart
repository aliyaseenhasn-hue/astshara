import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';

part 'reviews_provider.g.dart';

@riverpod
ReviewsRepository reviewsRepository(ReviewsRepositoryRef ref) {
  return ReviewsRepositoryImpl(SupabaseConfig.client);
}

@riverpod
Future<List<Review>> lawyerReviews(LawyerReviewsRef ref, String lawyerId) {
  return ref.watch(reviewsRepositoryProvider).getLawyerReviews(lawyerId);
}

@riverpod
class ReviewController extends _$ReviewController {
  @override
  FutureOr<void> build() {}

  Future<void> submitReview({
    required String bookingId,
    required String lawyerId, // profiles.id للمحامي
    required double rating,
    required String comment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;

      // user.id = auth.uid() — نجلب profiles.id
      final profileRow = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (profileRow == null) throw Exception('Profile not found');
      final userProfileId = profileRow['id'] as String;

      final review = Review(
        id: '',
        bookingId: bookingId,
        userId: userProfileId, // ← profiles.id وليس auth.uid()
        lawyerId: lawyerId,    // ← profiles.id للمحامي (يأتي صحيحاً من LawyerProfile)
        rating: rating,
        comment: comment,
      );

      await ref.read(reviewsRepositoryProvider).addReview(review);
    });
  }
}
