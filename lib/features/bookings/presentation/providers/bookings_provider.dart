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
    FutureProvider.family<Map<String, dynamic>?, String>((ref, bookingId) async {
  final response = await SupabaseConfig.client
      .from('bookings')
      .select('consultation_type, description, document_url, package_name, package_description, package_duration_minutes')
      .eq('id', bookingId)
      .maybeSingle();
  return response;
});

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<Booking?> requestBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required String packageName,
    required String consultationType,
    String? description,
    dynamic documentBytes,
    String? documentName,
  }) async {
    state = const AsyncLoading();
    Booking? createdBooking;

    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final repo = ref.read(bookingsRepositoryProvider);
      String? documentUrl;

      if (documentBytes != null && documentName != null) {
        documentUrl = await repo.uploadDocument(documentBytes, documentName);
      }

      createdBooking = await repo.createBooking(
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        packageName: packageName,
        consultationType: consultationType,
        description: description,
        documentUrl: documentUrl,
      );

      ref.invalidate(userBookingsProvider);
    });

    if (state.hasError) return null;
    return createdBooking;
  }
}
