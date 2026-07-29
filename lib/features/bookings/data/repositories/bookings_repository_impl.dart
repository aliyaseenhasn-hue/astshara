import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final SupabaseClient _supabase;

  BookingsRepositoryImpl(this._supabase);

  @override
  Future<void> createBooking(Booking booking) async {
    await _supabase.from('bookings').insert({
      'user_id': booking.userId,
      'lawyer_id': booking.lawyerId,
      'status': booking.status,
      'scheduled_at': booking.scheduledAt.toIso8601String(),
      'price': booking.price,
    });
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => BookingModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<List<Booking>> getLawyerBookings(String lawyerId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('lawyer_id', lawyerId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => BookingModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }
}
