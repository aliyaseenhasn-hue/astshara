// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lawyer_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LawyerProfileModelImpl _$$LawyerProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LawyerProfileModelImpl(
      id: json['id'] as String?,
      profileId: json['profile_id'] as String?,
      licenseNumber: json['license_number'] as String?,
      bio: json['bio'] as String?,
      specialization: json['specialization'] as String?,
      yearsExperience: (json['years_experience'] as num?)?.toInt(),
      consultationPrice: _doubleFromPossibleString(json['consultation_price']),
      whatsapp: json['whatsapp'] as String?,
      idCardUrl: json['id_card_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      verified: json['verified'] as bool? ?? false,
      availability: json['availability'] as bool? ?? true,
    );

Map<String, dynamic> _$$LawyerProfileModelImplToJson(
        _$LawyerProfileModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profile_id': instance.profileId,
      'license_number': instance.licenseNumber,
      'bio': instance.bio,
      'specialization': instance.specialization,
      'years_experience': instance.yearsExperience,
      'consultation_price': instance.consultationPrice,
      'whatsapp': instance.whatsapp,
      'id_card_url': instance.idCardUrl,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'verified': instance.verified,
      'availability': instance.availability,
    };
