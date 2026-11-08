// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'915d7a87ca49320cbf0d8c98d1d2dda099adbd83';

/// See also [Settings].
@ProviderFor(Settings)
final settingsProvider =
    AutoDisposeNotifierProvider<Settings, UserSettings>.internal(
  Settings.new,
  name: r'settingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Settings = AutoDisposeNotifier<UserSettings>;
String _$vehiclesHash() => r'5e5ee8b4635e5c1a51918bf944838ce0eea724a6';

/// See also [Vehicles].
@ProviderFor(Vehicles)
final vehiclesProvider =
    AutoDisposeNotifierProvider<Vehicles, List<Vehicle>>.internal(
  Vehicles.new,
  name: r'vehiclesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vehiclesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Vehicles = AutoDisposeNotifier<List<Vehicle>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
