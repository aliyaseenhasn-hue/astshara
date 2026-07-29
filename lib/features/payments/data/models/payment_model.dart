import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/payment.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

@freezed
class PaymentModel with _$PaymentModel {
  const PaymentModel._();

  const factory PaymentModel({
    required String id,
    @JsonKey(name: 'booking_id') required String bookingId,
    required double amount,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'transaction_number') String? transactionNumber,
    @JsonKey(name: 'receipt') String? receiptUrl,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PaymentModel;

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Payment toEntity() => Payment(
        id: id,
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionNumber: transactionNumber,
        receiptUrl: receiptUrl,
        status: status,
        createdAt: createdAt,
      );
}
