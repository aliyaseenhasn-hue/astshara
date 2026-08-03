// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppUserModel _$AppUserModelFromJson(Map<String, dynamic> json) {
  return _AppUserModel.fromJson(json);
}

/// @nodoc
mixin _$AppUserModel {
  String get id => throw _privateConstructorUsedError;
  String? get email =>
      throw _privateConstructorUsedError; // جعل البريد اختيارياً لأننا نستخدم رقم الهاتف
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verified')
  bool get isVerified => throw _privateConstructorUsedError;
  bool get hasProfessionalProfile => throw _privateConstructorUsedError;
  @JsonKey(name: 'onboarding_completed')
  bool? get isOnboardingComplete => throw _privateConstructorUsedError;

  /// Serializes this AppUserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppUserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppUserModelCopyWith<AppUserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUserModelCopyWith<$Res> {
  factory $AppUserModelCopyWith(
          AppUserModel value, $Res Function(AppUserModel) then) =
      _$AppUserModelCopyWithImpl<$Res, AppUserModel>;
  @useResult
  $Res call(
      {String id,
      String? email,
      @JsonKey(name: 'full_name') String? fullName,
      String? phone,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      String role,
      @JsonKey(name: 'is_verified') bool isVerified,
      bool hasProfessionalProfile,
      @JsonKey(name: 'onboarding_completed') bool? isOnboardingComplete});
}

/// @nodoc
class _$AppUserModelCopyWithImpl<$Res, $Val extends AppUserModel>
    implements $AppUserModelCopyWith<$Res> {
  _$AppUserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppUserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? fullName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? isVerified = null,
    Object? hasProfessionalProfile = null,
    Object? isOnboardingComplete = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      hasProfessionalProfile: null == hasProfessionalProfile
          ? _value.hasProfessionalProfile
          : hasProfessionalProfile // ignore: cast_nullable_to_non_nullable
              as bool,
      isOnboardingComplete: freezed == isOnboardingComplete
          ? _value.isOnboardingComplete
          : isOnboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppUserModelImplCopyWith<$Res>
    implements $AppUserModelCopyWith<$Res> {
  factory _$$AppUserModelImplCopyWith(
          _$AppUserModelImpl value, $Res Function(_$AppUserModelImpl) then) =
      __$$AppUserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? email,
      @JsonKey(name: 'full_name') String? fullName,
      String? phone,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      String role,
      @JsonKey(name: 'is_verified') bool isVerified,
      bool hasProfessionalProfile,
      @JsonKey(name: 'onboarding_completed') bool? isOnboardingComplete});
}

/// @nodoc
class __$$AppUserModelImplCopyWithImpl<$Res>
    extends _$AppUserModelCopyWithImpl<$Res, _$AppUserModelImpl>
    implements _$$AppUserModelImplCopyWith<$Res> {
  __$$AppUserModelImplCopyWithImpl(
      _$AppUserModelImpl _value, $Res Function(_$AppUserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppUserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? fullName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? isVerified = null,
    Object? hasProfessionalProfile = null,
    Object? isOnboardingComplete = freezed,
  }) {
    return _then(_$AppUserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      hasProfessionalProfile: null == hasProfessionalProfile
          ? _value.hasProfessionalProfile
          : hasProfessionalProfile // ignore: cast_nullable_to_non_nullable
              as bool,
      isOnboardingComplete: freezed == isOnboardingComplete
          ? _value.isOnboardingComplete
          : isOnboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppUserModelImpl extends _AppUserModel {
  const _$AppUserModelImpl(
      {required this.id,
      this.email,
      @JsonKey(name: 'full_name') this.fullName,
      this.phone,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      this.role = 'user',
      @JsonKey(name: 'is_verified') this.isVerified = false,
      this.hasProfessionalProfile = false,
      @JsonKey(name: 'onboarding_completed') this.isOnboardingComplete})
      : super._();

  factory _$AppUserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppUserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? email;
// جعل البريد اختيارياً لأننا نستخدم رقم الهاتف
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @override
  @JsonKey()
  final bool hasProfessionalProfile;
  @override
  @JsonKey(name: 'onboarding_completed')
  final bool? isOnboardingComplete;

  @override
  String toString() {
    return 'AppUserModel(id: $id, email: $email, fullName: $fullName, phone: $phone, avatarUrl: $avatarUrl, role: $role, isVerified: $isVerified, hasProfessionalProfile: $hasProfessionalProfile, isOnboardingComplete: $isOnboardingComplete)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.hasProfessionalProfile, hasProfessionalProfile) ||
                other.hasProfessionalProfile == hasProfessionalProfile) &&
            (identical(other.isOnboardingComplete, isOnboardingComplete) ||
                other.isOnboardingComplete == isOnboardingComplete));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      fullName,
      phone,
      avatarUrl,
      role,
      isVerified,
      hasProfessionalProfile,
      isOnboardingComplete);

  /// Create a copy of AppUserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUserModelImplCopyWith<_$AppUserModelImpl> get copyWith =>
      __$$AppUserModelImplCopyWithImpl<_$AppUserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppUserModelImplToJson(
      this,
    );
  }
}

abstract class _AppUserModel extends AppUserModel {
  const factory _AppUserModel(
      {required final String id,
      final String? email,
      @JsonKey(name: 'full_name') final String? fullName,
      final String? phone,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      final String role,
      @JsonKey(name: 'is_verified') final bool isVerified,
      final bool hasProfessionalProfile,
      @JsonKey(name: 'onboarding_completed')
      final bool? isOnboardingComplete}) = _$AppUserModelImpl;
  const _AppUserModel._() : super._();

  factory _AppUserModel.fromJson(Map<String, dynamic> json) =
      _$AppUserModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get email; // جعل البريد اختيارياً لأننا نستخدم رقم الهاتف
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  String get role;
  @override
  @JsonKey(name: 'is_verified')
  bool get isVerified;
  @override
  bool get hasProfessionalProfile;
  @override
  @JsonKey(name: 'onboarding_completed')
  bool? get isOnboardingComplete;

  /// Create a copy of AppUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppUserModelImplCopyWith<_$AppUserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
