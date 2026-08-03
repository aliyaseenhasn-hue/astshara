import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/lawyer_profile.dart';

part 'lawyer_profile_model.freezed.dart';
part 'lawyer_profile_model.g.dart';

@freezed
class LawyerProfileModel with _$LawyerProfileModel {
  const LawyerProfileModel._();

  const factory LawyerProfileModel({
    required String id,
    @JsonKey(name: 'profile_id') required String profileId,
    @JsonKey(name: 'license_number') String? licenseNumber,
    String? bio,
    @JsonKey(name: 'years_experience') int? yearsExperience,
    @JsonKey(name: 'consultation_price') double? consultationPrice,
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
        id: id,
        profileId: profileId,
        licenseNumber: licenseNumber,
        bio: bio,
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
