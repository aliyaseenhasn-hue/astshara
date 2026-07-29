// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lawyers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lawyersRepositoryHash() => r'9e8b6077f86ea5f9246854ee65e0a59899b8385c';

/// See also [lawyersRepository].
@ProviderFor(lawyersRepository)
final lawyersRepositoryProvider =
    AutoDisposeProvider<LawyersRepository>.internal(
  lawyersRepository,
  name: r'lawyersRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lawyersRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LawyersRepositoryRef = AutoDisposeProviderRef<LawyersRepository>;
String _$lawyersListHash() => r'525c251db1a377d7695bd0f775888fb29d7c1646';

/// See also [lawyersList].
@ProviderFor(lawyersList)
final lawyersListProvider =
    AutoDisposeFutureProvider<List<LawyerProfile>>.internal(
  lawyersList,
  name: r'lawyersListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lawyersListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LawyersListRef = AutoDisposeFutureProviderRef<List<LawyerProfile>>;
String _$lawyerProfileHash() => r'6efcea409ab4b90510bf8eeecd1476141b722786';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [lawyerProfile].
@ProviderFor(lawyerProfile)
const lawyerProfileProvider = LawyerProfileFamily();

/// See also [lawyerProfile].
class LawyerProfileFamily extends Family<AsyncValue<LawyerProfile?>> {
  /// See also [lawyerProfile].
  const LawyerProfileFamily();

  /// See also [lawyerProfile].
  LawyerProfileProvider call(
    String profileId,
  ) {
    return LawyerProfileProvider(
      profileId,
    );
  }

  @override
  LawyerProfileProvider getProviderOverride(
    covariant LawyerProfileProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lawyerProfileProvider';
}

/// See also [lawyerProfile].
class LawyerProfileProvider extends AutoDisposeFutureProvider<LawyerProfile?> {
  /// See also [lawyerProfile].
  LawyerProfileProvider(
    String profileId,
  ) : this._internal(
          (ref) => lawyerProfile(
            ref as LawyerProfileRef,
            profileId,
          ),
          from: lawyerProfileProvider,
          name: r'lawyerProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lawyerProfileHash,
          dependencies: LawyerProfileFamily._dependencies,
          allTransitiveDependencies:
              LawyerProfileFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  LawyerProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    FutureOr<LawyerProfile?> Function(LawyerProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LawyerProfileProvider._internal(
        (ref) => create(ref as LawyerProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LawyerProfile?> createElement() {
    return _LawyerProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LawyerProfileProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LawyerProfileRef on AutoDisposeFutureProviderRef<LawyerProfile?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _LawyerProfileProviderElement
    extends AutoDisposeFutureProviderElement<LawyerProfile?>
    with LawyerProfileRef {
  _LawyerProfileProviderElement(super.provider);

  @override
  String get profileId => (origin as LawyerProfileProvider).profileId;
}

String _$selectedCategoryHash() => r'7211a856149692f396d3d0d456fee1b23ec1ec9e';

/// See also [SelectedCategory].
@ProviderFor(SelectedCategory)
final selectedCategoryProvider =
    AutoDisposeNotifierProvider<SelectedCategory, String?>.internal(
  SelectedCategory.new,
  name: r'selectedCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCategory = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
