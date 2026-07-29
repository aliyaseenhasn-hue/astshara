// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingsRepositoryHash() =>
    r'8e1520261efc4512ebea165344626859346b038d';

/// See also [bookingsRepository].
@ProviderFor(bookingsRepository)
final bookingsRepositoryProvider =
    AutoDisposeProvider<BookingsRepository>.internal(
  bookingsRepository,
  name: r'bookingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookingsRepositoryRef = AutoDisposeProviderRef<BookingsRepository>;
String _$userBookingsHash() => r'59665daab1c5b3ed47aa8070efcf47516b246ee9';

/// See also [userBookings].
@ProviderFor(userBookings)
final userBookingsProvider = AutoDisposeFutureProvider<List<Booking>>.internal(
  userBookings,
  name: r'userBookingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserBookingsRef = AutoDisposeFutureProviderRef<List<Booking>>;
String _$bookingsControllerHash() =>
    r'40c2646be1d8d94a49bba85b9982e8eddfc44f45';

/// See also [BookingsController].
@ProviderFor(BookingsController)
final bookingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<BookingsController, void>.internal(
  BookingsController.new,
  name: r'bookingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookingsController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
