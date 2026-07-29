import '../entities/payment.dart';

abstract class PaymentsRepository {
  Future<void> createPayment(Payment payment);
  Future<String> uploadReceipt(String path, String fileName);
  Future<Payment?> getPaymentByBookingId(String bookingId);
}
