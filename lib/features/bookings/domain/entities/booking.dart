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
  final String? consultationType;
  final String? description;
  final String? documentUrl;
  final String? whatsappNumber;
  final bool lawyerApproved;

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
    this.consultationType,
    this.description,
    this.documentUrl,
    this.whatsappNumber,
    this.lawyerApproved = false,
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
    String? consultationType,
    String? description,
    String? documentUrl,
    String? whatsappNumber,
    bool? lawyerApproved,
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
      consultationType: consultationType ?? this.consultationType,
      description: description ?? this.description,
      documentUrl: documentUrl ?? this.documentUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      lawyerApproved: lawyerApproved ?? this.lawyerApproved,
    );
  }
}
