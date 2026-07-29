import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';

part 'payments_provider.g.dart';

@riverpod
PaymentsRepository paymentsRepository(PaymentsRepositoryRef ref) {
  return PaymentsRepositoryImpl(SupabaseConfig.client);
}

@riverpod
class PaymentsController extends _$PaymentsController {
  @override
  FutureOr<void> build() {}

  Future<void> submitPayment({
    required String bookingId,
    required double amount,
    required String method,
    String? transactionNumber,
    XFile? receiptFile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentsRepositoryProvider);
      String? receiptUrl;

      if (receiptFile != null) {
        final fileName =
            'receipt_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        receiptUrl = await repository.uploadReceipt(receiptFile.path, fileName);
      }

      final payment = Payment(
        id: '',
        bookingId: bookingId,
        amount: amount,
        paymentMethod: method,
        transactionNumber: transactionNumber,
        receiptUrl: receiptUrl,
      );

      await repository.createPayment(payment);
    });
  }
}
