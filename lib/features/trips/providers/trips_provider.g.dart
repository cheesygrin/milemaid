// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredTripsHash() => r'e2a9b21a15932752a73bf936143e1d1168c454db';

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

/// See also [filteredTrips].
@ProviderFor(filteredTrips)
const filteredTripsProvider = FilteredTripsFamily();

/// See also [filteredTrips].
class FilteredTripsFamily extends Family<List<Trip>> {
  /// See also [filteredTrips].
  const FilteredTripsFamily();

  /// See also [filteredTrips].
  FilteredTripsProvider call({
    TripCategory? category,
    String query = '',
  }) {
    return FilteredTripsProvider(
      category: category,
      query: query,
    );
  }

  @override
  FilteredTripsProvider getProviderOverride(
    covariant FilteredTripsProvider provider,
  ) {
    return call(
      category: provider.category,
      query: provider.query,
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
  String? get name => r'filteredTripsProvider';
}

/// See also [filteredTrips].
class FilteredTripsProvider extends AutoDisposeProvider<List<Trip>> {
  /// See also [filteredTrips].
  FilteredTripsProvider({
    TripCategory? category,
    String query = '',
  }) : this._internal(
          (ref) => filteredTrips(
            ref as FilteredTripsRef,
            category: category,
            query: query,
          ),
          from: filteredTripsProvider,
          name: r'filteredTripsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredTripsHash,
          dependencies: FilteredTripsFamily._dependencies,
          allTransitiveDependencies:
              FilteredTripsFamily._allTransitiveDependencies,
          category: category,
          query: query,
        );

  FilteredTripsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
    required this.query,
  }) : super.internal();

  final TripCategory? category;
  final String query;

  @override
  Override overrideWith(
    List<Trip> Function(FilteredTripsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredTripsProvider._internal(
        (ref) => create(ref as FilteredTripsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<Trip>> createElement() {
    return _FilteredTripsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTripsProvider &&
        other.category == category &&
        other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FilteredTripsRef on AutoDisposeProviderRef<List<Trip>> {
  /// The parameter `category` of this provider.
  TripCategory? get category;

  /// The parameter `query` of this provider.
  String get query;
}

class _FilteredTripsProviderElement
    extends AutoDisposeProviderElement<List<Trip>> with FilteredTripsRef {
  _FilteredTripsProviderElement(super.provider);

  @override
  TripCategory? get category => (origin as FilteredTripsProvider).category;
  @override
  String get query => (origin as FilteredTripsProvider).query;
}

String _$tripsHash() => r'0b28650c3133bb73cb7e8c31f8210908e679e049';

/// See also [Trips].
@ProviderFor(Trips)
final tripsProvider = AutoDisposeNotifierProvider<Trips, List<Trip>>.internal(
  Trips.new,
  name: r'tripsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Trips = AutoDisposeNotifier<List<Trip>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
