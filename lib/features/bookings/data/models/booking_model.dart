import '../../domain/entities/booking.dart';

class BookingModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String status;
  final DateTime scheduledAt;
  final double price;
  final DateTime? createdAt;
  final String? whatsappNumber;
  final bool lawyerApproved;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.status,
    required this.scheduledAt,
    required this.price,
    this.createdAt,
    this.whatsappNumber,
    this.lawyerApproved = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      lawyerId: json['lawyer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'قيد انتظار الدفع',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      whatsappNumber: json['whatsapp_number'] as String?,
      lawyerApproved: json['lawyer_approved'] as bool? ?? false,
    );
  }

  Booking toEntity() => Booking(
        id: id,
        userId: userId,
        lawyerId: lawyerId,
        status: status,
        scheduledAt: scheduledAt,
        price: price,
        createdAt: createdAt,
        whatsappNumber: whatsappNumber,
        lawyerApproved: lawyerApproved,
      );
}
