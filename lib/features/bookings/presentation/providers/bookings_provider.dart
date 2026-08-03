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
Future<List<Booking>> userBookings(UserBookingsRef ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Future.value([]);
  return ref.watch(bookingsRepositoryProvider).getUserBookings(user.id);
}

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<void> requestBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required double price,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception('User not logged in');

      final booking = Booking(
        id: '',
        userId: user.id,
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        price: price,
      );

      await ref.read(bookingsRepositoryProvider).createBooking(booking);
      ref.invalidate(userBookingsProvider);
    });
  }
}
