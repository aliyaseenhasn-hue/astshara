import '../../domain/entities/lawyer_profile.dart';

class LawyerProfileModel {
  final String? id;
  final String? profileId;
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
  final List<LawyerService> services;

  const LawyerProfileModel({
    this.id,
    this.profileId,
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
    this.services = const [],
  });

  factory LawyerProfileModel.fromJson(Map<String, dynamic> json) {
    return LawyerProfileModel(
      id: json['id'] as String?,
      profileId: json['profile_id'] as String?,
      fullName: json['full_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      bio: json['bio'] as String?,
      specializations: _specializationsFromJson(json['specialization']),
      yearsExperience: json['years_experience'] as int?,
      consultationPrice: _doubleFromPossibleString(json['consultation_price']),
      whatsapp: json['whatsapp'] as String?,
      idCardUrl: json['id_card_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      verified: json['verified'] as bool? ?? false,
      availability: json['availability'] as bool? ?? true,
      services: (json['services'] as List? ?? [])
          .map((e) => LawyerService.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<String> _specializationsFromJson(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.startsWith('{') && value.endsWith('}')) {
        return value
            .substring(1, value.length - 1)
            .split(',')
            .map((e) => e.trim().replaceAll('"', ''))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static double? _doubleFromPossibleString(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  LawyerProfile toEntity() => LawyerProfile(
        id: id ?? '',
        profileId: profileId ?? '',
        fullName: fullName,
        licenseNumber: licenseNumber,
        bio: bio,
        specializations: specializations,
        yearsExperience: yearsExperience,
        consultationPrice: consultationPrice,
        whatsapp: whatsapp,
        idCardUrl: idCardUrl,
        rating: rating,
        reviewCount: reviewCount,
        verified: verified,
        availability: availability,
        services: services,
      );
}
