class Booking {
  final String id;
  final String userId;
  final String lawyerId;
  final String status;
  final DateTime scheduledAt;
  final double price;
  final DateTime? createdAt;
  final String? lawyerName;
  final String? userName;
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

  const Booking({
    required this.id,
    required this.userId,
    required this.lawyerId,
    this.status = 'قيد انتظار الدفع',
    required this.scheduledAt,
    required this.price,
    this.createdAt,
    this.lawyerName,
    this.userName,
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

  Booking copyWith({
    String? id,
    String? userId,
    String? lawyerId,
    String? status,
    DateTime? scheduledAt,
    double? price,
    DateTime? createdAt,
    String? lawyerName,
    String? userName,
    String? packageName,
    String? packageDescription,
    int? packageDurationMinutes,
    String? consultationType,
    String? consultationStatus,
    String? description,
    String? documentUrl,
    String? whatsappNumber,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lawyerId: lawyerId ?? this.lawyerId,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      lawyerName: lawyerName ?? this.lawyerName,
      userName: userName ?? this.userName,
      packageName: packageName ?? this.packageName,
      packageDescription: packageDescription ?? this.packageDescription,
      packageDurationMinutes:
          packageDurationMinutes ?? this.packageDurationMinutes,
      consultationType: consultationType ?? this.consultationType,
      consultationStatus: consultationStatus ?? this.consultationStatus,
      description: description ?? this.description,
      documentUrl: documentUrl ?? this.documentUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
