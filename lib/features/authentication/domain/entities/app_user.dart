import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    @Default('user') String role,
    @Default(false) bool isVerified,
    @Default(false) bool hasProfessionalProfile,
    @Default(false)
    bool isOnboardingComplete, // حقل جديد للتأكد من اختيار الدور
  }) = _AppUser;
}
