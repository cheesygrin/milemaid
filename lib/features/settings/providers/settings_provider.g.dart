// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'12887a055d07498fcfc432e60708f8f9b43e8e4d';

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
String _$vehiclesHash() => r'b7325c9a224eb5e30055bb4567ad94044c7462f1';

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
