import '../entities/review.dart';

abstract class ReviewsRepository {
  Future<void> addReview(Review review);
  Future<List<Review>> getLawyerReviews(String lawyerId);
}
