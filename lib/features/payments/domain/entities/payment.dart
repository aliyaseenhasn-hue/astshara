import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String bookingId,
    required double amount,
    required String paymentMethod,
    String? transactionNumber,
    String? receiptUrl,
    @Default('pending') String status,
    DateTime? createdAt,
  }) = _Payment;
}
