import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookings_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

part 'bookings_provider.g.dart';

@riverpod
BookingsRepository bookingsRepository(BookingsRepositoryRef ref) {
  // للاتصال بـ Supabase الحقيقي، اجعل هذه القيمة false
  const bool useMock = false;
  if (useMock) {
    return MockBookingsRepository();
  }
  return BookingsRepositoryImpl(SupabaseConfig.client);
}

class MockBookingsRepository implements BookingsRepository {
  final List<Booking> _mockBookings = [
    Booking(
      id: 'b1',
      userId: '123',
      lawyerId: 'p1',
      status: 'pending',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      price: 50000,
    ),
    Booking(
      id: 'b2',
      userId: '123',
      lawyerId: 'p2',
      status: 'accepted',
      scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
      price: 40000,
    ),
  ];

  @override
  Future<void> createBooking(Booking booking) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockBookings.add(booking.copyWith(id: DateTime.now().toString()));
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockBookings.where((b) => b.userId == userId).toList();
  }

  @override
  Future<List<Booking>> getLawyerBookings(String lawyerId) async {
    return _mockBookings.where((b) => b.lawyerId == lawyerId).toList();
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {}
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
