import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';

part 'payments_provider.g.dart';

@riverpod
PaymentsRepository paymentsRepository(PaymentsRepositoryRef ref) {
  return PaymentsRepositoryImpl(SupabaseConfig.client);
}

final bookingPaymentProvider =
    FutureProvider.family<Payment?, String>((ref, bookingId) {
  return ref.watch(paymentsRepositoryProvider).getPaymentByBookingId(bookingId);
});

@riverpod
class PaymentsController extends _$PaymentsController {
  @override
  FutureOr<void> build() {}

  Future<void> submitPayment({
    required String bookingId,
    required String method,
    required String transactionNumber,
    XFile? receiptFile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentsRepositoryProvider);
      String? receiptUrl;

      if (receiptFile != null) {
        final fileName =
            'receipt_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bytes = await receiptFile.readAsBytes();
        receiptUrl = await repository.uploadReceipt(bytes, fileName);
      }

      await repository.createPayment(
        Payment(
          id: '',
          bookingId: bookingId,
          amount: 0,
          paymentMethod: method,
          transactionNumber: transactionNumber,
          receiptUrl: receiptUrl,
          status: 'قيد معالجة الدفع',
        ),
      );
      ref.invalidate(bookingPaymentProvider(bookingId));
    });
  }
}
