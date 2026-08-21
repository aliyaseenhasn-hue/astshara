import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../../payments/domain/entities/payment.dart';

part 'payment_management_provider.g.dart';

@riverpod
class PaymentManagement extends _$PaymentManagement {
  Future<List<Payment>> _fetchPendingPayments() async {
    final response = await SupabaseConfig.client
        .from('payments')
        .select()
        .eq('status', 'قيد معالجة الدفع')
        .order('created_at');

    return (response as List)
        .map((json) => PaymentModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  FutureOr<List<Payment>> build() async {
    return _fetchPendingPayments();
  }

  Future<void> approvePayment(Payment payment) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    try {
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'تم الدفع'})
          .eq('id', payment.id);

      // لا نستدعي build() من داخل AsyncValue.guard؛ ذلك قد يعيد تشغيل
      // دورة بناء الـ AsyncNotifier نفسها ويتسبب في Future already completed.
      state = AsyncData(await _fetchPendingPayments());
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      ref.read(globalLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> rejectPayment(Payment payment) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    try {
      await SupabaseConfig.client
          .from('payments')
          .update({'status': 'فشل الدفع'})
          .eq('id', payment.id);

      // إعادة تحميل القائمة مباشرة بدلاً من استدعاء build() بشكل متداخل.
      state = AsyncData(await _fetchPendingPayments());
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      ref.read(globalLoadingProvider.notifier).setLoading(false);
    }
  }
}
