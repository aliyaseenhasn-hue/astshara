import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<void> createBooking(Booking booking,
      {String? consultationType,
      String? description,
      String? documentUrl,
      String? whatsappNumber});
  Future<List<Booking>> getUserBookings(String userId);
  Future<List<Booking>> getLawyerBookings(String lawyerId);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<String> uploadDocument(dynamic fileBytes, String fileName);
}
