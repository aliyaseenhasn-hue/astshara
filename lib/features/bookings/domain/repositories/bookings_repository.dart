import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<Booking> createBooking({
    required String lawyerId,
    required DateTime scheduledAt,
    required String packageName,
    required String consultationType,
    String? description,
    String? documentUrl,
    String? whatsappNumber,
  });

  Future<List<DateTime>> getAvailableSlots({
    required String lawyerId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<Booking>> getUserBookings(String userId);
  Future<List<Booking>> getLawyerBookings(String lawyerId);
  Future<Booking> updateBookingStatus(String bookingId, String status);
  Future<Map<String, String>?> getBookingContact(String bookingId);
  Future<String> uploadDocument(dynamic fileBytes, String fileName);
}
