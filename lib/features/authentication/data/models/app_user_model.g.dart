// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserModelImpl _$$AppUserModelImplFromJson(Map<String, dynamic> json) =>
    _$AppUserModelImpl(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      isVerified: json['is_verified'] as bool? ?? false,
      hasProfessionalProfile: json['hasProfessionalProfile'] as bool? ?? false,
      isOnboardingComplete: json['onboarding_completed'] as bool?,
      walletNumber: json['wallet_number'] as String?,
    );

Map<String, dynamic> _$$AppUserModelImplToJson(_$AppUserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'avatar_url': instance.avatarUrl,
      'role': instance.role,
      'is_verified': instance.isVerified,
      'hasProfessionalProfile': instance.hasProfessionalProfile,
      'onboarding_completed': instance.isOnboardingComplete,
      'wallet_number': instance.walletNumber,
    };
