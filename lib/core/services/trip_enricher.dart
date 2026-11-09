import 'dart:async';

import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/address_lookup.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/place_matcher.dart';

/// Fills in addresses and named-place ids on trips.
///
/// Dependencies are injected (a places supplier and an [AddressLookup]) so
/// tests need no Hive and no platform plugins; the default [instance] wires
/// those to [DatabaseService] and the platform geocoder.
class TripEnricher {
  final List<NamedLocation> Function() places;
  final AddressLookup lookup;

  TripEnricher({required this.places, required this.lookup});

  static final TripEnricher instance = TripEnricher(
    places: () => DatabaseService().getSettings().namedLocations,
    lookup: PlatformAddressLookup(),
  );

  /// Enriches [t] with start/end place ids and addresses.
  ///
  /// - Empty route: returned unchanged.
  /// - Start = first route point, end = last.
  /// - An existing non-null address is kept; otherwise the matched place's
  ///   stored [NamedLocation.address] wins, else the geocoder is asked.
  /// - Never changes category, purpose, or isConfirmed.
  Future<Trip> enrich(Trip t) async {
    if (t.routePoints.isEmpty) return t;

    final start = await _endpoint(
      t.startLocationId,
      t.startAddress,
      t.routePoints.first,
    );
    final end = await _endpoint(
      t.endLocationId,
      t.endAddress,
      t.routePoints.last,
    );

    return t.copyWith(
      startLocationId: start.$1,
      startAddress: start.$2,
      endLocationId: end.$1,
      endAddress: end.$2,
    );
  }

  Future<(String?, String?)> _endpoint(
    String? existingId,
    String? existingAddress,
    LatLngPoint point,
  ) async {
    final matched = matchLocation(
      point.latitude,
      point.longitude,
      places(),
    );

    String? address;
    if (existingAddress != null && existingAddress.isNotEmpty) {
      // Never lose an address we already have.
      address = existingAddress;
    } else if (matched?.address != null && matched!.address!.isNotEmpty) {
      address = matched.address;
    } else {
      address = await lookup.addressFor(point.latitude, point.longitude);
    }

    return (matched?.id, address);
  }

  /// Trips that could use an address: newest first, route not empty, and a
  /// missing start or end address. Capped at [max] so a backfill pass stays
  /// bounded.
  static List<Trip> tripsNeedingAddresses(List<Trip> all, {int max = 25}) {
    final candidates = all
        .where((t) => t.routePoints.isNotEmpty)
        .where((t) => t.startAddress == null || t.endAddress == null)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return candidates.take(max).toList();
  }

  /// Enriches the trips that are missing addresses, one at a time with a
  /// 1-second pause between lookups (Apple rate-limits geocoding), saving
  /// each. Returns how many trips were saved.
  Future<int> backfill() async {
    final db = DatabaseService();
    final targets = tripsNeedingAddresses(db.getAllTrips());
    var count = 0;
    for (final trip in targets) {
      final enriched = await enrich(trip);
      await db.saveTrip(enriched);
      count++;
      if (count < targets.length) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return count;
  }

  /// Re-runs place matching only (no geocoder lookups) on every trip and
  /// saves the ones that changed. Used after a place is added, moved,
  /// resized or deleted; a deleted place simply clears the ids (addresses
  /// are left alone).
  Future<int> rematchAll() async {
    final db = DatabaseService();
    final placesList = places();
    var changed = 0;

    for (final trip in db.getAllTrips()) {
      if (trip.routePoints.isEmpty) continue;

      final start = matchLocation(
        trip.routePoints.first.latitude,
        trip.routePoints.first.longitude,
        placesList,
      );
      final end = matchLocation(
        trip.routePoints.last.latitude,
        trip.routePoints.last.longitude,
        placesList,
      );

      if (trip.startLocationId == start?.id && trip.endLocationId == end?.id) {
        continue;
      }

      var updated = trip.copyWith(
        startLocationId: start?.id,
        endLocationId: end?.id,
      );
      // Adopt the matched place's address when the trip has none yet.
      if (updated.startAddress == null && start?.address != null) {
        updated = updated.copyWith(startAddress: start!.address);
      }
      if (updated.endAddress == null && end?.address != null) {
        updated = updated.copyWith(endAddress: end!.address);
      }
      await db.saveTrip(updated);
      changed++;
    }
    return changed;
  }
}
