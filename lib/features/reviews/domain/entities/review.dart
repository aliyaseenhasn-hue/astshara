import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';

@freezed
class Review with _$Review {
  const factory Review({
    required String id,
    required String bookingId,
    required String userId,
    required String lawyerId,
    required double rating,
    required String comment,
    DateTime? createdAt,
  }) = _Review;
}
