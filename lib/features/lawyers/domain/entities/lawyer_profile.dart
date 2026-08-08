class LawyerService {
  final String title;
  final double price;
  final String? description;
  final int durationMinutes;
  final List<String> consultationTypes;

  const LawyerService({
    required this.title,
    required this.price,
    this.description,
    this.durationMinutes = 30,
    this.consultationTypes = const ['نصية', 'صوتية', 'فيديو'],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'description': description,
        'duration_minutes': durationMinutes,
        'consultation_types': consultationTypes,
      };

  factory LawyerService.fromJson(Map<String, dynamic> json) => LawyerService(
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String?,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
        consultationTypes: (json['consultation_types'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const ['نصية', 'صوتية', 'فيديو'],
      );

  LawyerService copyWith({
    String? title,
    double? price,
    String? description,
    int? durationMinutes,
    List<String>? consultationTypes,
  }) =>
      LawyerService(
        title: title ?? this.title,
        price: price ?? this.price,
        description: description ?? this.description,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        consultationTypes: consultationTypes ?? this.consultationTypes,
      );
}

class LawyerProfile {
  final String id;
  final String profileId;
  final String? fullName;
  final String? licenseNumber;
  final String? bio;
  final List<String> specializations;
  final int? yearsExperience;
  final double? consultationPrice;
  final String? whatsapp;
  final String? idCardUrl;
  final double rating;
  final int reviewCount;
  final bool verified;
  final bool availability;
  final String? avatarUrl;
  final List<LawyerService> services;

  const LawyerProfile({
    required this.id,
    required this.profileId,
    this.fullName,
    this.licenseNumber,
    this.bio,
    this.specializations = const [],
    this.yearsExperience,
    this.consultationPrice,
    this.whatsapp,
    this.idCardUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.verified = false,
    this.availability = true,
    this.avatarUrl,
    this.services = const [],
  });

  LawyerProfile copyWith({
    String? id,
    String? profileId,
    String? fullName,
    String? licenseNumber,
    String? bio,
    List<String>? specializations,
    int? yearsExperience,
    double? consultationPrice,
    String? whatsapp,
    String? idCardUrl,
    double? rating,
    int? reviewCount,
    bool? verified,
    bool? availability,
    String? avatarUrl,
    List<LawyerService>? services,
  }) {
    return LawyerProfile(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fullName: fullName ?? this.fullName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      whatsapp: whatsapp ?? this.whatsapp,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      verified: verified ?? this.verified,
      availability: availability ?? this.availability,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      services: services ?? this.services,
    );
  }
}
