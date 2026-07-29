import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/booking.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

@freezed
class BookingModel with _$BookingModel {
  const BookingModel._();

  const factory BookingModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'lawyer_id') required String lawyerId,
    @Default('pending') String status,
    @JsonKey(name: 'scheduled_at') required DateTime scheduledAt,
    required double price,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _BookingModel;

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  Booking toEntity() => Booking(
        id: id,
        userId: userId,
        lawyerId: lawyerId,
        status: status,
        scheduledAt: scheduledAt,
        price: price,
        createdAt: createdAt,
      );
}
