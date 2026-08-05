import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/lawyer_profile.dart';

part 'lawyer_profile_model.freezed.dart';
part 'lawyer_profile_model.g.dart';

@freezed
class LawyerProfileModel with _$LawyerProfileModel {
  const LawyerProfileModel._();

  const factory LawyerProfileModel({
    String? id,
    @JsonKey(name: 'profile_id') String? profileId,
    @JsonKey(name: 'full_name') String? fullName,
    @JsonKey(name: 'license_number') String? licenseNumber,
    String? bio,
    @JsonKey(name: 'specialization', fromJson: _specializationsFromJson)
    @Default([])
    List<String> specializations,
    @JsonKey(name: 'years_experience') int? yearsExperience,
    @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
    double? consultationPrice,
    String? whatsapp,
    @JsonKey(name: 'id_card_url') String? idCardUrl,
    @Default(0.0) double rating,
    @JsonKey(name: 'review_count') @Default(0) int reviewCount,
    @Default(false) bool verified,
    @Default(true) bool availability,
  }) = _LawyerProfileModel;

  factory LawyerProfileModel.fromJson(Map<String, dynamic> json) =>
      _$LawyerProfileModelFromJson(json);

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
      );
}

List<String> _specializationsFromJson(dynamic value) {
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

double? _doubleFromPossibleString(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
