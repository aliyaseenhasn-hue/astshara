import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/lawyer_profile.dart';

part 'lawyer_profile_model.freezed.dart';
part 'lawyer_profile_model.g.dart';

@freezed
class LawyerProfileModel with _$LawyerProfileModel {
  const LawyerProfileModel._();

  const factory LawyerProfileModel({
    String? id, // جعلها اختيارية لتجنب الانهيار عند القراءة
    @JsonKey(name: 'profile_id') String? profileId,
    @JsonKey(name: 'full_name')
    String? fullName, // إضافة الحقل لدعم القراءة من الجداول الموحدة
    @JsonKey(name: 'license_number') String? licenseNumber,
    String? bio,
    String? specialization,
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
        specialization: specialization,
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

double? _doubleFromPossibleString(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
