import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String userId,
    required String lawyerId,
    @Default('pending') String status,
    required DateTime scheduledAt,
    required double price,
    DateTime? createdAt,
  }) = _Booking;
}
