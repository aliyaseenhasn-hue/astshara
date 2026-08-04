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
    required String lawyerId,
    required double rating,
    required String comment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;

      final profileId = user.id;

      final review = Review(
        id: '',
        bookingId: bookingId,
        userId: profileId,
        lawyerId: lawyerId,
        rating: rating,
        comment: comment,
      );

      await ref.read(reviewsRepositoryProvider).addReview(review);
    });
  }
}
