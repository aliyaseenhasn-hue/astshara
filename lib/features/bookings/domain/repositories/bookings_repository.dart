import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<Booking> createBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required String packageName,
    required String consultationType,
    String? description,
    String? documentUrl,
  });

  Future<List<Booking>> getUserBookings(String userId);
  Future<List<Booking>> getLawyerBookings(String lawyerId);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<String> uploadDocument(dynamic fileBytes, String fileName);
}
