import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookings_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

part 'bookings_provider.g.dart';

class AvailableBookingSlot {
  final String id;
  final DateTime startsAt;

  const AvailableBookingSlot({required this.id, required this.startsAt});
}

@riverpod
BookingsRepository bookingsRepository(BookingsRepositoryRef ref) =>
    BookingsRepositoryImpl(SupabaseConfig.client);

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
  return ref.read(bookingsRepositoryProvider).getUserBookings(profileId);
}

@riverpod
Future<List<Booking>> lawyerBookings(LawyerBookingsRef ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  final profileId = await _getProfileId(user.id);
  if (profileId == null) return [];
  return ref.read(bookingsRepositoryProvider).getLawyerBookings(profileId);
}

final availableSlotsProvider =
    FutureProvider.family<List<AvailableBookingSlot>, String>((ref, lawyerId) async {
  final rows = await SupabaseConfig.client
      .from('lawyer_availability_slots')
      .select('id, starts_at')
      .eq('lawyer_id', lawyerId)
      .eq('is_available', true)
      .gt('starts_at', DateTime.now().toUtc().toIso8601String())
      .order('starts_at');

  return (rows as List).map((row) {
    final map = Map<String, dynamic>.from(row as Map);
    return AvailableBookingSlot(
      id: map['id'] as String,
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
    );
  }).toList();
});

final bookingDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, bookingId) async {
  return await SupabaseConfig.client
      .from('bookings')
      .select(
        'consultation_type, description, document_url, package_name, package_description, package_duration_minutes',
      )
      .eq('id', bookingId)
      .maybeSingle();
});

final bookingContactProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, bookingId) async {
  final response = await SupabaseConfig.client.rpc(
    'get_booking_contact_info',
    params: {'p_booking_id': bookingId},
  );
  if (response is List && response.isNotEmpty) {
    return Map<String, dynamic>.from(response.first as Map);
  }
  return null;
});

@riverpod
class BookingsController extends _$BookingsController {
  @override
  FutureOr<void> build() {}

  Future<Booking?> requestBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    String? slotId,
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

      final isClient = user.role == 'user' || user.role == 'client';
      if (!isClient) {
        throw Exception('فقط طالب الخدمة يمكنه طلب حجز استشارة');
      }

      final repo = ref.read(bookingsRepositoryProvider);
      String? documentUrl;
      if (documentBytes != null && documentName != null) {
        documentUrl = await repo.uploadDocument(documentBytes, documentName);
      }
      createdBooking = await repo.createBooking(
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        slotId: slotId,
        packageName: packageName,
        consultationType: consultationType,
        description: description,
        documentUrl: documentUrl,
      );
      ref.invalidate(userBookingsProvider);
    });
    return state.hasError ? null : createdBooking;
  }
}
