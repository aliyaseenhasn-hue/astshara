import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'admin_provider.g.dart';

@riverpod
class AdminStats extends _$AdminStats {
  @override
  Future<Map<String, dynamic>> build() async {
    final client = SupabaseConfig.client;

    try {
      // جلب إجمالي المستخدمين
      final usersRes =
          await client.from('profiles').select('id').count(CountOption.exact);

      // جلب إجمالي المحامين الموثقين
      final lawyersRes = await client
          .from('lawyer_profiles')
          .select('id')
          .eq('verified', true)
          .count(CountOption.exact);

      // جلب طلبات التوثيق المعلقة
      final pendingVerificationsRes = await client
          .from('lawyer_profiles')
          .select('id')
          .eq('verified', false)
          .count(CountOption.exact);

      // جلب الحجوزات النشطة
      final activeBookingsRes = await client
          .from('bookings')
          .select('id')
          .eq('status', 'confirmed')
          .count(CountOption.exact);

      // جلب الدفعات المعلقة
      final pendingPaymentsRes = await client
          .from('payments')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);

      // جلب مجموع الإيرادات
      final revenueRes =
          await client.from('payments').select('amount').eq('status', 'paid');

      double totalRevenue = 0;
      final revenueList = revenueRes as List;
      for (final row in revenueList) {
        totalRevenue += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_users': usersRes.count ?? 0,
        'total_lawyers': lawyersRes.count ?? 0,
        'pending_verifications': pendingVerificationsRes.count ?? 0,
        'active_bookings': activeBookingsRes.count ?? 0,
        'total_revenue': totalRevenue,
        'pending_payments': pendingPaymentsRes.count ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
