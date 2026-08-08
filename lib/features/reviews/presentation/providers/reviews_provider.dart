import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final reviewForBookingProvider = FutureProvider.family<Review?, String>((ref, bookingId) async {
  final response = await SupabaseConfig.client
      .from('reviews')
      .select('id, booking_id, user_id, lawyer_id, rating, comment, created_at')
      .eq('booking_id', bookingId)
      .maybeSingle();
  if (response == null) return null;
  return Review(
    id: response['id'] as String,
    bookingId: response['booking_id'] as String,
    userId: response['user_id'] as String,
    lawyerId: response['lawyer_id'] as String,
    rating: (response['rating'] as num).toDouble(),
    comment: response['comment'] as String? ?? '',
    createdAt: DateTime.tryParse(response['created_at'].toString()),
  );
});

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
      if (user == null) throw Exception('المستخدم غير مسجل دخول');

      final profileRow = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();
      if (profileRow == null) throw Exception('ملف المستخدم غير موجود');

      await ref.read(reviewsRepositoryProvider).addReview(Review(
        id: '',
        bookingId: bookingId,
        userId: profileRow['id'] as String,
        lawyerId: lawyerId,
        rating: rating,
        comment: comment.trim(),
      ));

      ref.invalidate(reviewForBookingProvider(bookingId));
      ref.invalidate(lawyerReviewsProvider(lawyerId));
    });
  }
}
