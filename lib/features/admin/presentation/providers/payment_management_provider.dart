import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
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
        .eq('status', 'pending')
        .order('created_at');

    return (response as List)
        .map((json) => PaymentModel.fromJson(json).toEntity())
        .toList();
  }

  Future<void> approvePayment(Payment payment) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. تحديث حالة الدفعة
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'paid'}).eq('id', payment.id);

      // 2. تحديث حالة الحجز المرتبط ليكون مقبولاً
      await SupabaseConfig.client
          .from('bookings')
          .update({'status': 'accepted'}).eq('id', payment.bookingId);

      // 3. تحديث القوائم
      ref.invalidate(userBookingsProvider);
      return build();
    });
  }

  Future<void> rejectPayment(Payment payment) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'rejected'}).eq('id', payment.id);

      return build();
    });
  }
}
