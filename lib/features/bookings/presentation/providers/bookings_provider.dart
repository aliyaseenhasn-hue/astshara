import 'package:flutter_riverpod/flutter_riverpod.dart';
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

@riverpod
Future<List<Booking>> userBookings(UserBookingsRef ref) async {
  final repository = ref.watch(bookingsRepositoryProvider);
  final profileId = await _getProfileId(ref);
  if (profileId == null) return [];
  return repository.getUserBookings(profileId);
}

@riverpod
Future<List<Booking>> lawyerBookings(LawyerBookingsRef ref) async {
  final repository = ref.watch(bookingsRepositoryProvider);
  final profileId = await _getProfileId(ref);
  if (profileId == null) return [];
  return repository.getLawyerBookings(profileId);
}

/// Helper function to fetch the real DB profiles.id from auth.uid()
Future<String?> _getProfileId(Ref ref) async {
  final user = ref.read(authStateChangesProvider).value;
  if (user == null) return null;

  // AppUser.id is mapped from profiles.id in AuthRepositoryImpl.getCurrentUser
  return user.id;
}

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<void> requestBooking({
    required String lawyerId, // This is already a profile_id
    required DateTime scheduledAt,
    required double price,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profileId = await _getProfileId(ref);
      if (profileId == null) throw Exception('User not logged in');

      final booking = Booking(
        id: '',
        userId: profileId,
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        price: price,
      );

      await ref.read(bookingsRepositoryProvider).createBooking(booking);
      ref.invalidate(userBookingsProvider);
    });
  }
}
