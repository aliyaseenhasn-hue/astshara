import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final SupabaseClient _supabase;

  BookingsRepositoryImpl(this._supabase);

  @override
  Future<Booking> createBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required String packageName,
    required String consultationType,
    String? description,
    String? documentUrl,
    String? whatsappNumber,
  }) async {
    final response = await _supabase.rpc('create_booking', params: {
      'p_lawyer_id': lawyerId,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'p_package_name': packageName,
      'p_consultation_type': consultationType,
      'p_description': description,
      'p_document_url': documentUrl,
      'p_client_whatsapp': whatsappNumber,
    });

    return BookingModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    ).toEntity();
  }

  @override
  Future<List<DateTime>> getAvailableSlots({
    required String lawyerId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _supabase
        .from('lawyer_availability_slots')
        .select('starts_at')
        .eq('lawyer_id', lawyerId)
        .eq('is_available', true)
        .gte('starts_at', from.toUtc().toIso8601String())
        .lte('starts_at', to.toUtc().toIso8601String())
        .order('starts_at');

    return (response as List)
        .map((row) => DateTime.parse(row['starts_at'] as String).toLocal())
        .toList();
  }

  @override
  Future<String> uploadDocument(dynamic fileBytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    final filePath = '${user.id}/docs/$fileName';
    await _supabase.storage.from('lawyer_documents').uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return await _supabase.storage
        .from('lawyer_documents')
        .createSignedUrl(filePath, 604800);
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BookingModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ).toEntity())
        .toList();
  }

  @override
  Future<List<Booking>> getLawyerBookings(String lawyerId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('lawyer_id', lawyerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BookingModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ).toEntity())
        .toList();
  }

  @override
  Future<Booking> updateBookingStatus(String bookingId, String status) async {
    final response = await _supabase.rpc('change_booking_status', params: {
      'p_booking_id': bookingId,
      'p_new_status': status,
    });

    return BookingModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    ).toEntity();
  }

  @override
  Future<Map<String, String>?> getBookingContact(String bookingId) async {
    final response = await _supabase.rpc('get_booking_contact', params: {
      'p_booking_id': bookingId,
    });
    final rows = response as List;
    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first as Map);
    return {
      if (row['phone'] != null) 'phone': row['phone'].toString(),
      if (row['whatsapp'] != null) 'whatsapp': row['whatsapp'].toString(),
    };
  }
}
