import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_provider.g.dart';

@riverpod
class AdminStats extends _$AdminStats {
  @override
  Map<String, dynamic> build() {
    return {
      'total_users': 150,
      'total_lawyers': 25,
      'pending_verifications': 4,
      'active_bookings': 12,
      'total_revenue': 450000.0,
      'pending_payments': 3,
    };
  }
}
