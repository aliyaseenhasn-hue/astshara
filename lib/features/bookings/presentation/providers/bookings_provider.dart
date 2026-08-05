import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookings_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

part 'bookings_provider.g.dart';

@riverpod
BookingsRepository bookingsRepository(BookingsRepositoryRef ref) {
  return BookingsRepositoryImpl(SupabaseConfig.client);
}

/// جلب profiles.id من auth.uid() — لأن bookings تستخدم profiles.id وليس auth.uid()
Future<String?> _getProfileId(String authUid) async {
  final row = await SupabaseConfig.client
      .from('profiles')
      .select('id')
      .eq('auth_id', authUid)
      .maybeSingle();
  return row?['id'] as String?;
}

@riverpod
Future<List<Booking>> userBookings(UserBookingsRef ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  // user.id = auth.uid() — نحتاج profiles.id
  final profileId = await _getProfileId(user.id);
  if (profileId == null) return [];
  return ref.watch(bookingsRepositoryProvider).getUserBookings(profileId);
}

@riverpod
Future<List<Booking>> lawyerBookings(LawyerBookingsRef ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  final profileId = await _getProfileId(user.id);
  if (profileId == null) return [];
  return ref.watch(bookingsRepositoryProvider).getLawyerBookings(profileId);
}

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<void> requestBooking({
    required String
        lawyerId, // هذا بالفعل profiles.id لأنه يأتي من LawyerProfile.profileId
    required DateTime scheduledAt,
    required double price,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception('User not logged in');

      // user.id = auth.uid() — نجلب profiles.id للمستخدم
      final userProfileId = await _getProfileId(user.id);
      if (userProfileId == null) throw Exception('Profile not found');

      final booking = Booking(
        id: '',
        userId: userProfileId, // ← profiles.id وليس auth.uid()
        lawyerId: lawyerId, // ← يأتي من LawyerProfile.profileId (صحيح)
        scheduledAt: scheduledAt,
        price: price,
      );

      await ref.read(bookingsRepositoryProvider).createBooking(booking);
      ref.invalidate(userBookingsProvider);
    });
  }
}
