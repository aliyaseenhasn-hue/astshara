import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';

part 'admin_provider.g.dart';

@riverpod
class AdminStats extends _$AdminStats {
  @override
  Future<Map<String, dynamic>> build() async {
    final client = SupabaseConfig.client;

    try {
      // جلب إحصائيات دقيقة باستخدام طول المصفوفة لضمان التوافق مع كافة الإصدارات

      final usersRes = await client.from('profiles').select('id');
      final totalUsers = (usersRes as List).length;

      final lawyersRes = await client
          .from('lawyer_profiles')
          .select('id')
          .eq('verified', true);
      final totalLawyers = (lawyersRes as List).length;

      final pendingVerificationsRes = await client
          .from('lawyer_profiles')
          .select('id')
          .eq('verified', false);
      final pendingVerifications = (pendingVerificationsRes as List).length;

      final activeBookingsRes =
          await client.from('bookings').select('id').eq('status', 'confirmed');
      final activeBookings = (activeBookingsRes as List).length;

      final pendingPaymentsRes =
          await client.from('payments').select('id').eq('status', 'pending');
      final pendingPaymentsCount = (pendingPaymentsRes as List).length;

      // جلب مجموع الإيرادات
      final revenueRes =
          await client.from('payments').select('amount').eq('status', 'paid');

      double totalRevenue = 0;
      for (final row in (revenueRes as List)) {
        totalRevenue += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_users': totalUsers,
        'total_lawyers': totalLawyers,
        'pending_verifications': pendingVerifications,
        'active_bookings': activeBookings,
        'total_revenue': totalRevenue,
        'pending_payments': pendingPaymentsCount,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
