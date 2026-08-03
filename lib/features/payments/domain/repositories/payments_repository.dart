import 'dart:typed_data';
import '../entities/payment.dart';

abstract class PaymentsRepository {
  Future<void> createPayment(Payment payment);
  Future<String> uploadReceipt(Uint8List bytes, String fileName);
  Future<Payment?> getPaymentByBookingId(String bookingId);
}
