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

final bookingDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, bookingId) async {
  final response = await SupabaseConfig.client
      .from('bookings')
      .select('consultation_type, description, document_url, whatsapp_number')
      .eq('id', bookingId)
      .maybeSingle();
  return response;
});

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<void> requestBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required double price,
    String? consultationType,
    String? description,
    dynamic documentBytes,
    String? documentName,
    String? whatsappNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception('User not logged in');

      final userProfileId = await _getProfileId(user.id);
      if (userProfileId == null) throw Exception('Profile not found');

      final repo = ref.read(bookingsRepositoryProvider);
      String? documentUrl;

      if (documentBytes != null && documentName != null) {
        documentUrl = await repo.uploadDocument(documentBytes, documentName);
      }

      final booking = Booking(
        id: '',
        userId: userProfileId,
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        price: price,
      );

      await repo.createBooking(
        booking,
        consultationType: consultationType,
        description: description,
        documentUrl: documentUrl,
        whatsappNumber: whatsappNumber,
      );
      ref.invalidate(userBookingsProvider);
    });
  }
}
