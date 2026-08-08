import '../../domain/entities/booking.dart';

class BookingModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String status;
  final DateTime scheduledAt;
  final double price;
  final DateTime? createdAt;
  final String? packageName;
  final String? packageDescription;
  final int packageDurationMinutes;
  final String? consultationType;
  final String consultationStatus;
  final String? description;
  final String? documentUrl;
  final String? whatsappNumber;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.status,
    required this.scheduledAt,
    required this.price,
    this.createdAt,
    this.packageName,
    this.packageDescription,
    this.packageDurationMinutes = 30,
    this.consultationType,
    this.consultationStatus = 'لم تبدأ',
    this.description,
    this.documentUrl,
    this.whatsappNumber,
    this.completedAt,
    this.cancelledAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      lawyerId: json['lawyer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'قيد انتظار الدفع',
      scheduledAt: parseDate(json['scheduled_at']) ?? DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['created_at']),
      packageName: json['package_name'] as String?,
      packageDescription: json['package_description'] as String?,
      packageDurationMinutes:
          (json['package_duration_minutes'] as num?)?.toInt() ?? 30,
      consultationType: json['consultation_type'] as String?,
      consultationStatus:
          json['consultation_status'] as String? ?? 'لم تبدأ',
      description: json['description'] as String?,
      documentUrl: json['document_url'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      completedAt: parseDate(json['completed_at']),
      cancelledAt: parseDate(json['cancelled_at']),
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
        packageName: packageName,
        packageDescription: packageDescription,
        packageDurationMinutes: packageDurationMinutes,
        consultationType: consultationType,
        consultationStatus: consultationStatus,
        description: description,
        documentUrl: documentUrl,
        whatsappNumber: whatsappNumber,
        completedAt: completedAt,
        cancelledAt: cancelledAt,
      );
}
