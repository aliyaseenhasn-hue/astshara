import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final SupabaseClient _supabase;

  ReviewsRepositoryImpl(this._supabase);

  @override
  Future<void> addReview(Review review) async {
    // review.userId و review.lawyerId يجب أن يكونا profiles.id (وليس auth.uid)
    // التحقق يتم في reviews_provider قبل الاستدعاء
    await _supabase.from('reviews').insert({
      'booking_id': review.bookingId,
      'user_id': review.userId,
      'lawyer_id': review.lawyerId,
      'rating': review.rating,
      'comment': review.comment,
    });
  }

  @override
  Future<List<Review>> getLawyerReviews(String lawyerId) async {
    final response = await _supabase
        .from('reviews')
        .select()
        .eq('lawyer_id', lawyerId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Review(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      lawyerId: json['lawyer_id'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    )).toList();
  }
}
