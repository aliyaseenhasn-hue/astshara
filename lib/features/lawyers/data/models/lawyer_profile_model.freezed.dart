// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lawyer_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LawyerProfileModel _$LawyerProfileModelFromJson(Map<String, dynamic> json) {
  return _LawyerProfileModel.fromJson(json);
}

/// @nodoc
mixin _$LawyerProfileModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_id')
  String get profileId => throw _privateConstructorUsedError;
  @JsonKey(name: 'license_number')
  String? get licenseNumber => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get specialization =>
      throw _privateConstructorUsedError; // إضافة التخصص هنا
  @JsonKey(name: 'years_experience')
  int? get yearsExperience => throw _privateConstructorUsedError;
  @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
  double? get consultationPrice => throw _privateConstructorUsedError;
  String? get whatsapp => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_card_url')
  String? get idCardUrl => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  @JsonKey(name: 'review_count')
  int get reviewCount => throw _privateConstructorUsedError;
  bool get verified => throw _privateConstructorUsedError;
  bool get availability => throw _privateConstructorUsedError;

  /// Serializes this LawyerProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LawyerProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LawyerProfileModelCopyWith<LawyerProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LawyerProfileModelCopyWith<$Res> {
  factory $LawyerProfileModelCopyWith(
          LawyerProfileModel value, $Res Function(LawyerProfileModel) then) =
      _$LawyerProfileModelCopyWithImpl<$Res, LawyerProfileModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'profile_id') String profileId,
      @JsonKey(name: 'license_number') String? licenseNumber,
      String? bio,
      String? specialization,
      @JsonKey(name: 'years_experience') int? yearsExperience,
      @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
      double? consultationPrice,
      String? whatsapp,
      @JsonKey(name: 'id_card_url') String? idCardUrl,
      double rating,
      @JsonKey(name: 'review_count') int reviewCount,
      bool verified,
      bool availability});
}

/// @nodoc
class _$LawyerProfileModelCopyWithImpl<$Res, $Val extends LawyerProfileModel>
    implements $LawyerProfileModelCopyWith<$Res> {
  _$LawyerProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LawyerProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profileId = null,
    Object? licenseNumber = freezed,
    Object? bio = freezed,
    Object? specialization = freezed,
    Object? yearsExperience = freezed,
    Object? consultationPrice = freezed,
    Object? whatsapp = freezed,
    Object? idCardUrl = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? verified = null,
    Object? availability = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      licenseNumber: freezed == licenseNumber
          ? _value.licenseNumber
          : licenseNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      specialization: freezed == specialization
          ? _value.specialization
          : specialization // ignore: cast_nullable_to_non_nullable
              as String?,
      yearsExperience: freezed == yearsExperience
          ? _value.yearsExperience
          : yearsExperience // ignore: cast_nullable_to_non_nullable
              as int?,
      consultationPrice: freezed == consultationPrice
          ? _value.consultationPrice
          : consultationPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      whatsapp: freezed == whatsapp
          ? _value.whatsapp
          : whatsapp // ignore: cast_nullable_to_non_nullable
              as String?,
      idCardUrl: freezed == idCardUrl
          ? _value.idCardUrl
          : idCardUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      verified: null == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      availability: null == availability
          ? _value.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LawyerProfileModelImplCopyWith<$Res>
    implements $LawyerProfileModelCopyWith<$Res> {
  factory _$$LawyerProfileModelImplCopyWith(_$LawyerProfileModelImpl value,
          $Res Function(_$LawyerProfileModelImpl) then) =
      __$$LawyerProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'profile_id') String profileId,
      @JsonKey(name: 'license_number') String? licenseNumber,
      String? bio,
      String? specialization,
      @JsonKey(name: 'years_experience') int? yearsExperience,
      @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
      double? consultationPrice,
      String? whatsapp,
      @JsonKey(name: 'id_card_url') String? idCardUrl,
      double rating,
      @JsonKey(name: 'review_count') int reviewCount,
      bool verified,
      bool availability});
}

/// @nodoc
class __$$LawyerProfileModelImplCopyWithImpl<$Res>
    extends _$LawyerProfileModelCopyWithImpl<$Res, _$LawyerProfileModelImpl>
    implements _$$LawyerProfileModelImplCopyWith<$Res> {
  __$$LawyerProfileModelImplCopyWithImpl(_$LawyerProfileModelImpl _value,
      $Res Function(_$LawyerProfileModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of LawyerProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profileId = null,
    Object? licenseNumber = freezed,
    Object? bio = freezed,
    Object? specialization = freezed,
    Object? yearsExperience = freezed,
    Object? consultationPrice = freezed,
    Object? whatsapp = freezed,
    Object? idCardUrl = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? verified = null,
    Object? availability = null,
  }) {
    return _then(_$LawyerProfileModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      licenseNumber: freezed == licenseNumber
          ? _value.licenseNumber
          : licenseNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      specialization: freezed == specialization
          ? _value.specialization
          : specialization // ignore: cast_nullable_to_non_nullable
              as String?,
      yearsExperience: freezed == yearsExperience
          ? _value.yearsExperience
          : yearsExperience // ignore: cast_nullable_to_non_nullable
              as int?,
      consultationPrice: freezed == consultationPrice
          ? _value.consultationPrice
          : consultationPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      whatsapp: freezed == whatsapp
          ? _value.whatsapp
          : whatsapp // ignore: cast_nullable_to_non_nullable
              as String?,
      idCardUrl: freezed == idCardUrl
          ? _value.idCardUrl
          : idCardUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      verified: null == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      availability: null == availability
          ? _value.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LawyerProfileModelImpl extends _LawyerProfileModel {
  const _$LawyerProfileModelImpl(
      {required this.id,
      @JsonKey(name: 'profile_id') required this.profileId,
      @JsonKey(name: 'license_number') this.licenseNumber,
      this.bio,
      this.specialization,
      @JsonKey(name: 'years_experience') this.yearsExperience,
      @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
      this.consultationPrice,
      this.whatsapp,
      @JsonKey(name: 'id_card_url') this.idCardUrl,
      this.rating = 0.0,
      @JsonKey(name: 'review_count') this.reviewCount = 0,
      this.verified = false,
      this.availability = true})
      : super._();

  factory _$LawyerProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LawyerProfileModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'profile_id')
  final String profileId;
  @override
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @override
  final String? bio;
  @override
  final String? specialization;
// إضافة التخصص هنا
  @override
  @JsonKey(name: 'years_experience')
  final int? yearsExperience;
  @override
  @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
  final double? consultationPrice;
  @override
  final String? whatsapp;
  @override
  @JsonKey(name: 'id_card_url')
  final String? idCardUrl;
  @override
  @JsonKey()
  final double rating;
  @override
  @JsonKey(name: 'review_count')
  final int reviewCount;
  @override
  @JsonKey()
  final bool verified;
  @override
  @JsonKey()
  final bool availability;

  @override
  String toString() {
    return 'LawyerProfileModel(id: $id, profileId: $profileId, licenseNumber: $licenseNumber, bio: $bio, specialization: $specialization, yearsExperience: $yearsExperience, consultationPrice: $consultationPrice, whatsapp: $whatsapp, idCardUrl: $idCardUrl, rating: $rating, reviewCount: $reviewCount, verified: $verified, availability: $availability)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LawyerProfileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.licenseNumber, licenseNumber) ||
                other.licenseNumber == licenseNumber) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.specialization, specialization) ||
                other.specialization == specialization) &&
            (identical(other.yearsExperience, yearsExperience) ||
                other.yearsExperience == yearsExperience) &&
            (identical(other.consultationPrice, consultationPrice) ||
                other.consultationPrice == consultationPrice) &&
            (identical(other.whatsapp, whatsapp) ||
                other.whatsapp == whatsapp) &&
            (identical(other.idCardUrl, idCardUrl) ||
                other.idCardUrl == idCardUrl) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.availability, availability) ||
                other.availability == availability));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      profileId,
      licenseNumber,
      bio,
      specialization,
      yearsExperience,
      consultationPrice,
      whatsapp,
      idCardUrl,
      rating,
      reviewCount,
      verified,
      availability);

  /// Create a copy of LawyerProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LawyerProfileModelImplCopyWith<_$LawyerProfileModelImpl> get copyWith =>
      __$$LawyerProfileModelImplCopyWithImpl<_$LawyerProfileModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LawyerProfileModelImplToJson(
      this,
    );
  }
}

abstract class _LawyerProfileModel extends LawyerProfileModel {
  const factory _LawyerProfileModel(
      {required final String id,
      @JsonKey(name: 'profile_id') required final String profileId,
      @JsonKey(name: 'license_number') final String? licenseNumber,
      final String? bio,
      final String? specialization,
      @JsonKey(name: 'years_experience') final int? yearsExperience,
      @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
      final double? consultationPrice,
      final String? whatsapp,
      @JsonKey(name: 'id_card_url') final String? idCardUrl,
      final double rating,
      @JsonKey(name: 'review_count') final int reviewCount,
      final bool verified,
      final bool availability}) = _$LawyerProfileModelImpl;
  const _LawyerProfileModel._() : super._();

  factory _LawyerProfileModel.fromJson(Map<String, dynamic> json) =
      _$LawyerProfileModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'profile_id')
  String get profileId;
  @override
  @JsonKey(name: 'license_number')
  String? get licenseNumber;
  @override
  String? get bio;
  @override
  String? get specialization; // إضافة التخصص هنا
  @override
  @JsonKey(name: 'years_experience')
  int? get yearsExperience;
  @override
  @JsonKey(name: 'consultation_price', fromJson: _doubleFromPossibleString)
  double? get consultationPrice;
  @override
  String? get whatsapp;
  @override
  @JsonKey(name: 'id_card_url')
  String? get idCardUrl;
  @override
  double get rating;
  @override
  @JsonKey(name: 'review_count')
  int get reviewCount;
  @override
  bool get verified;
  @override
  bool get availability;

  /// Create a copy of LawyerProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LawyerProfileModelImplCopyWith<_$LawyerProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
