import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/app_user.dart';

part 'app_user_model.freezed.dart';
part 'app_user_model.g.dart';

@freezed
class AppUserModel with _$AppUserModel {
  const AppUserModel._();

  const factory AppUserModel({
    required String id,
    String? email, // جعل البريد اختيارياً لأننا نستخدم رقم الهاتف
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default('user') String role,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default(false) bool hasProfessionalProfile,
  }) = _AppUserModel;

  factory AppUserModel.fromJson(Map<String, dynamic> json) =>
      _$AppUserModelFromJson(json);

  // تحويل الموديل إلى Entity المستخدم في الـ UI
  AppUser toEntity() => AppUser(
        id: id,
        email: email ?? '',
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        role: role,
        isVerified: isVerified,
        hasProfessionalProfile: hasProfessionalProfile,
      );
}
