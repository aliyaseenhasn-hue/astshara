import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../models/payment_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final SupabaseClient _supabase;

  PaymentsRepositoryImpl(this._supabase);

  @override
  Future<void> createPayment(Payment payment) async {
    await _supabase.from('payments').insert({
      'booking_id': payment.bookingId,
      'amount': payment.amount,
      'payment_method': payment.paymentMethod,
      'transaction_number': payment.transactionNumber,
      'receipt': payment.receiptUrl,
      'status': payment.status,
    });
  }

  @override
  Future<String> uploadReceipt(String path, String fileName) async {
    final user = _supabase.auth.currentUser;
    final filePath = '${user?.id}/$fileName';

    await _supabase.storage
        .from('receipts')
        .uploadBinary(filePath, Uint8List(0));

    return _supabase.storage.from('receipts').createSignedUrl(filePath, 3600);
  }

  @override
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (response == null) return null;
    return PaymentModel.fromJson(response).toEntity();
  }
}
