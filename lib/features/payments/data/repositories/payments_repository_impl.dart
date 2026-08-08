import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../models/payment_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final SupabaseClient _supabase;

  PaymentsRepositoryImpl(this._supabase);

  @override
  Future<void> createPayment(Payment payment) async {
    final response = await _supabase.rpc('submit_payment', params: {
      'p_booking_id': payment.bookingId,
      'p_payment_method': payment.paymentMethod,
      'p_transaction_number': payment.transactionNumber,
      'p_receipt_url': payment.receiptUrl,
    });

    if (response == null) {
      throw Exception('تعذر تسجيل عملية الدفع');
    }
  }

  @override
  Future<String> uploadReceipt(Uint8List bytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    final filePath = '${user.id}/$fileName';
    try {
      await _supabase.storage.from('receipts').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return await _supabase.storage
          .from('receipts')
          .createSignedUrl(filePath, 604800);
    } catch (e) {
      debugPrint('خطأ في رفع الإيصال: $e');
      rethrow;
    }
  }

  @override
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return PaymentModel.fromJson(response).toEntity();
  }
}
