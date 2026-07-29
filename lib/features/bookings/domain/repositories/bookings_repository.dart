import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<void> createBooking(Booking booking);
  Future<List<Booking>> getUserBookings(String userId);
  Future<List<Booking>> getLawyerBookings(String lawyerId);
  Future<void> updateBookingStatus(String bookingId, String status);
}
