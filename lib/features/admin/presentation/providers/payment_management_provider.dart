import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';

part 'payment_management_provider.g.dart';

@riverpod
class PaymentManagement extends _$PaymentManagement {
  @override
  FutureOr<List<Payment>> build() async {
    final response = await SupabaseConfig.client
        .from('payments')
        .select()
        .eq('status', 'قيد معالجة الدفع')
        .order('created_at');

    return (response as List)
        .map((json) => PaymentModel.fromJson(json).toEntity())
        .toList();
  }

  Future<void> approvePayment(Payment payment) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // The database trigger validates the transition and confirms the booking.
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'تم الدفع'})
          .eq('id', payment.id);

      ref.invalidate(userBookingsProvider);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(bookingPaymentProvider(payment.bookingId));
      ref.invalidate(bookingDetailsProvider(payment.bookingId));
      return build();
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> rejectPayment(Payment payment) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // The database trigger moves the booking back to waiting for payment.
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'فشل الدفع'})
          .eq('id', payment.id);

      ref.invalidate(userBookingsProvider);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(bookingPaymentProvider(payment.bookingId));
      ref.invalidate(bookingDetailsProvider(payment.bookingId));
      return build();
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }
}
