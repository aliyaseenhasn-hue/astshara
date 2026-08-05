import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final SupabaseClient _supabase;

  BookingsRepositoryImpl(this._supabase);

  @override
  Future<void> createBooking(Booking booking,
      {String? consultationType,
      String? description,
      String? documentUrl,
      String? whatsappNumber}) async {
    await _supabase.from('bookings').insert({
      'user_id': booking.userId,
      'lawyer_id': booking.lawyerId,
      'status': booking.status,
      'scheduled_at': booking.scheduledAt.toIso8601String(),
      'price': booking.price,
      'consultation_type': consultationType,
      'description': description,
      'document_url': documentUrl,
      'whatsapp_number': whatsappNumber,
    });
  }

  @override
  Future<String> uploadDocument(dynamic fileBytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final filePath = '${user.id}/docs/$fileName';
    await _supabase.storage.from('lawyer_documents').uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return await _supabase.storage
        .from('lawyer_documents')
        .createSignedUrl(filePath, 31536000);
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response == null) return [];
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => BookingModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<List<Booking>> getLawyerBookings(String lawyerId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('lawyer_id', lawyerId)
        .order('created_at', ascending: false);

    if (response == null) return [];
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => BookingModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _supabase
        .from('bookings')
        .update({'status': status}).eq('id', bookingId);

    // إذا تم قبول الطلب، نقوم بإنشاء محادثة تلقائياً لتمكين التواصل المباشر
    if (status == 'accepted') {
      try {
        final bookingRow = await _supabase
            .from('bookings')
            .select('user_id, lawyer_id')
            .eq('id', bookingId)
            .single();

        await _supabase.from('conversations').upsert({
          'booking_id': bookingId,
          'user_id': bookingRow['user_id'],
          'lawyer_id': bookingRow['lawyer_id'],
          'last_message': 'تم بدء الاستشارة المباشرة',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'booking_id');
      } catch (e) {
        print('Error creating conversation: $e');
      }
    }
  }
}
