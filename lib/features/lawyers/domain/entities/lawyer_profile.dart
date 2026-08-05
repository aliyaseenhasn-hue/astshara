import 'package:freezed_annotation/freezed_annotation.dart';

part 'lawyer_profile.freezed.dart';

@freezed
class LawyerProfile with _$LawyerProfile {
  const factory LawyerProfile({
    required String id,
    required String profileId,
    String? fullName,
    String? licenseNumber,
    String? bio,
    @Default([]) List<String> specializations,
    int? yearsExperience,
    double? consultationPrice,
    String? whatsapp,
    String? idCardUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default(false) bool verified,
    @Default(true) bool availability,
    String? avatarUrl,
  }) = _LawyerProfile;
}
