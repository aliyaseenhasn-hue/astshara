import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final SupabaseClient _supabase;

  BookingsRepositoryImpl(this._supabase);

  @override
  Future<void> createBooking(
    Booking booking, {
    String? consultationType,
    String? description,
    String? documentUrl,
    String? whatsappNumber,
  }) async {
    final raw = consultationType?.trim() ?? '';
    final separator = raw.indexOf('::');
    final packageName = separator > 0 ? raw.substring(0, separator).trim() : raw;
    final method = separator > 0 ? raw.substring(separator + 2).trim() : 'نصية';

    await _supabase.rpc('create_booking', params: {
      'p_lawyer_id': booking.lawyerId,
      'p_scheduled_at': booking.scheduledAt.toUtc().toIso8601String(),
      'p_package_name': packageName,
      'p_consultation_type': method,
      'p_description': description,
      'p_document_url': documentUrl,
      'p_client_whatsapp': whatsappNumber,
    });
  }

  @override
  Future<void> createCustomConsultationRequest({
    required String lawyerId,
    required String subject,
    required String description,
    required String consultationType,
  }) async {
    await _supabase.rpc('create_custom_consultation_request', params: {
      'p_lawyer_id': lawyerId,
      'p_subject': subject,
      'p_description': description,
      'p_consultation_type': consultationType,
    });
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
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _supabase.rpc('change_booking_status', params: {
      'p_booking_id': bookingId,
      'p_new_status': status,
    });
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
