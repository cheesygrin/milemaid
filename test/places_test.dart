import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/address_lookup.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/core/services/trip_enricher.dart';

/// All coordinates in this file are made-up points near lat 40, lng -100
/// (empty Nebraska), per AGENTS.md. Nothing here is a real location.

final _createdAt = DateTime.parse('2026-01-15T08:00:00Z');

NamedLocation _place({
  required String id,
  required String name,
  double lat = 40.0,
  double lng = -100.0,
  double radiusMeters = 150,
  String? address,
  TripCategory? defaultCategory,
  String? defaultPurpose,
}) {
  return NamedLocation(
    id: id,
    name: name,
    latitude: lat,
    longitude: lng,
    radiusMeters: radiusMeters,
    address: address,
    defaultCategory: defaultCategory,
    defaultPurpose: defaultPurpose,
    createdAt: _createdAt,
  );
}

Trip _trip({
  required List<LatLngPoint> route,
  String? startAddress,
  String? endAddress,
  String? startLocationId,
  String? endLocationId,
}) {
  return Trip(
    id: 'trip-1',
    startTime: DateTime.parse('2026-01-15T09:00:00Z'),
    endTime: DateTime.parse('2026-01-15T09:30:00Z'),
    distanceMiles: 5.2,
    durationMinutes: 30,
    routePoints: route,
    category: TripCategory.other,
    purpose: 'Site visit',
    notes: 'note',
    isConfirmed: false,
    startAddress: startAddress,
    endAddress: endAddress,
    startLocationId: startLocationId,
    endLocationId: endLocationId,
  );
}

LatLngPoint _pt(double lat, double lng) =>
    LatLngPoint(latitude: lat, longitude: lng);

/// Stub geocoder: answers from a table keyed by "lat,lng", and records the
/// coordinates it was asked for.
class _RecordingLookup implements AddressLookup {
  _RecordingLookup(this._answers);

  final Map<String, String> _answers;
  final List<String> asked = [];

  static String _key(double lat, double lng) => '$lat,$lng';

  @override
  Future<String?> addressFor(double lat, double lng) {
    asked.add(_key(lat, lng));
    return Future.value(_answers[_key(lat, lng)]);
  }
}

/// A geocoder that throws if asked: used to prove enrich never calls lookup
/// on an empty route.
class _ThrowingLookup implements AddressLookup {
  @override
  Future<String?> addressFor(double lat, double lng) async {
    throw StateError('no geocoder in test');
  }
}

void main() {
  group('matchLocation', () {
    test('matches a point inside the place radius', () {
      // ~56 m north of the place center: within the 150 m default radius.
      final place = _place(id: 'p1', name: 'Depot');
      final matched = matchLocation(40.0005, -100.0, [place]);
      expect(matched, isNotNull);
      expect(matched!.id, 'p1');
    });

    test('returns null when outside every radius', () {
      // ~222 m north of the place center: beyond 150 m.
      final place = _place(id: 'p1', name: 'Depot');
      expect(matchLocation(40.002, -100.0, [place]), isNull);
    });

    test('picks the nearest of two overlapping places', () {
      final far = _place(id: 'far', name: 'Far', lat: 40.0, radiusMeters: 400);
      final near = _place(
          id: 'near', name: 'Near', lat: 40.001, radiusMeters: 400);
      // ~44 m from 'far', ~67 m from 'near': both in radius, far is nearer.
      final matched = matchLocation(40.0004, -100.0, [far, near]);
      expect(matched, isNotNull);
      expect(matched!.id, 'far');

      // ~167 m from 'far', ~56 m from 'near': now near wins.
      final matched2 = matchLocation(40.0004 + 0.0011, -100.0, [far, near]);
      expect(matched2!.id, 'near');
    });

    test('ignores a place whose own radius excludes it even when a nearer one misses', () {
      final tight = _place(id: 'tight', name: 'Tight', radiusMeters: 50);
      expect(matchLocation(40.0005, -100.0, [tight]), isNull);
    });
  });

  group('placeLabel', () {
    test('resolves a known location id to the place name', () {
      final byId = {'p1': _place(id: 'p1', name: 'Depot')};
      expect(placeLabel('p1', '100 Main St, Springfield', byId), 'Depot');
    });

    test('falls back to the address when the id is unknown', () {
      expect(placeLabel('nope', '100 Main St, Springfield', const {}), '100 Main St, Springfield');
    });

    test('falls back to the address when the id is null', () {
      expect(placeLabel(null, '100 Main St', const {}), '100 Main St');
    });

    test('falls back to Unknown place when everything is missing', () {
      expect(placeLabel(null, null, const {}), 'Unknown place');
      expect(placeLabel('x', '', const {}), 'Unknown place');
    });
  });

  group('TripEnricher.enrich', () {
    test('a named place wins and uses its stored address', () async {
      final place = _place(
        id: 'p1',
        name: 'Depot',
        lat: 40.0,
        lng: -100.0,
        address: '1 Depot Way, Springfield',
      );
      final enricher = TripEnricher(
        places: () => [place],
        lookup: _RecordingLookup(const {}),
      );
      final trip = _trip(route: [_pt(40.0002, -100.0), _pt(40.0002, -100.0)]);

      final enriched = await enricher.enrich(trip);

      expect(enriched.startLocationId, 'p1');
      expect(enriched.startAddress, '1 Depot Way, Springfield');
    });

    test('an unmatched endpoint uses the geocoder', () async {
      final lookup = _RecordingLookup(const {
        '40.0002,-100.0': '100 Main St, Springfield',
        '40.0006,-100.0': '200 Oak Ave, Shelby',
      });
      final enricher = TripEnricher(places: () => [], lookup: lookup);
      final trip = _trip(
        route: [_pt(40.0002, -100.0), _pt(40.0006, -100.0)],
      );

      final enriched = await enricher.enrich(trip);

      expect(enriched.startLocationId, isNull);
      expect(enriched.startAddress, '100 Main St, Springfield');
      expect(enriched.endAddress, '200 Oak Ave, Shelby');
    });

    test('a lookup returning null leaves the address null', () async {
      final enricher = TripEnricher(
        places: () => [],
        lookup: _RecordingLookup(const {}),
      );
      final trip = _trip(route: [_pt(40.0, -100.0), _pt(40.001, -100.0)]);

      final enriched = await enricher.enrich(trip);

      expect(enriched.startAddress, isNull);
      expect(enriched.endAddress, isNull);
    });

    test('an existing address is kept, never overwritten', () async {
      final place = _place(
        id: 'p1',
        name: 'Depot',
        address: '1 Depot Way, Springfield',
      );
      final enricher = TripEnricher(
        places: () => [place],
        lookup: _RecordingLookup(const {}),
      );
      final trip = _trip(
        route: [_pt(40.0, -100.0), _pt(40.0, -100.0)],
        startAddress: 'Kept Address',
      );

      final enriched = await enricher.enrich(trip);

      expect(enriched.startAddress, 'Kept Address');
      expect(enriched.startLocationId, 'p1');
    });

    test('an empty route is returned unchanged', () async {
      final enricher = TripEnricher(places: () => [], lookup: _ThrowingLookup());
      final trip = _trip(route: []);

      final enriched = await enricher.enrich(trip);

      expect(enriched.startAddress, isNull);
      expect(enriched.endAddress, isNull);
    });

    test('never changes category, purpose, notes or isConfirmed', () async {
      final enricher = TripEnricher(
        places: () => [_place(id: 'p1', name: 'Depot')],
        lookup: _RecordingLookup(const {}),
      );
      final trip = _trip(route: [_pt(40.0, -100.0), _pt(40.0, -100.0)]);

      final enriched = await enricher.enrich(trip);

      expect(enriched.category, TripCategory.other);
      expect(enriched.purpose, 'Site visit');
      expect(enriched.notes, 'note');
      expect(enriched.isConfirmed, false);
    });
  });

  group('tripsNeedingAddresses', () {
    test('newest first, route required, missing address only, capped', () {
      final old = _trip(route: [_pt(40.0, -100.0)])
          .copyWith(id: 'old', startTime: DateTime.parse('2026-01-01T00:00:00Z'));
      final oldEnriched = old.copyWith(startAddress: 'a', endAddress: 'b');
      final newest = old.copyWith(id: 'new', startTime: DateTime.parse('2026-03-01T00:00:00Z'));
      final middle = old.copyWith(id: 'mid', startTime: DateTime.parse('2026-02-01T00:00:00Z'));
      final emptyRoute = _trip(route: []).copyWith(id: 'empty');

      final result = TripEnricher.tripsNeedingAddresses(
        [oldEnriched, emptyRoute, old, newest, middle],
        max: 2,
      );

      expect(result.map((t) => t.id).toList(), ['new', 'mid']);
    });

    test('default cap is 25', () {
      final trips = List.generate(40, (i) {
        return _trip(route: [_pt(40.0, -100.0)])
            .copyWith(id: 't$i', startTime: DateTime.parse('2026-01-01T00:00:00Z').add(Duration(hours: i)));
      });
      expect(TripEnricher.tripsNeedingAddresses(trips).length, 25);
    });
  });

  group('Trip JSON', () {
    test('round trip with the new fields', () {
      final trip = _trip(
        route: [_pt(40.0, -100.0), _pt(40.001, -100.0)],
        startAddress: '100 Main St',
        endAddress: '200 Oak Ave',
        startLocationId: 'p1',
        endLocationId: 'p2',
      );

      final back = Trip.fromJson(trip.toJson());

      expect(back.startAddress, '100 Main St');
      expect(back.endAddress, '200 Oak Ave');
      expect(back.startLocationId, 'p1');
      expect(back.endLocationId, 'p2');
      expect(back.id, trip.id);
      expect(back.startTime, trip.startTime);
      expect(back.category, trip.category);
    });

    test('legacy JSON without the new fields loads with nulls', () {
      final legacy = <String, dynamic>{
        'id': 't-legacy',
        'startTime': '2026-01-15T09:00:00.000Z',
        'endTime': '2026-01-15T09:30:00.000Z',
        'distanceMiles': 5.2,
        'durationMinutes': 30,
        'routePoints': [
          {'latitude': 40.0, 'longitude': -100.0},
        ],
        'category': 'business',
        'isConfirmed': true,
      };

      final back = Trip.fromJson(legacy);

      expect(back.startAddress, isNull);
      expect(back.endAddress, isNull);
      expect(back.startLocationId, isNull);
      expect(back.endLocationId, isNull);
      expect(back.category, TripCategory.business);
      expect(back.isConfirmed, true);
      expect(back.routePoints, hasLength(1));
    });
  });

  group('NamedLocation JSON', () {
    test('round trip', () {
      final place = _place(
        id: 'p1',
        name: 'Depot',
        address: '1 Depot Way, Springfield',
        defaultPurpose: 'Client visit',
      );
      final back = NamedLocation.fromJson(place.toJson());

      expect(back.id, 'p1');
      expect(back.name, 'Depot');
      expect(back.latitude, 40.0);
      expect(back.longitude, -100.0);
      expect(back.radiusMeters, 150);
      expect(back.address, '1 Depot Way, Springfield');
      expect(back.defaultCategory, isNull);
      expect(back.defaultPurpose, 'Client visit');
      expect(back.createdAt, _createdAt);
    });

    test('tolerant of missing optional keys', () {
      final back = NamedLocation.fromJson(<String, dynamic>{
        'id': 'p2',
        'name': 'Minimal',
        'latitude': 40.0,
        'longitude': -100.0,
      });
      expect(back.radiusMeters, 150);
      expect(back.address, isNull);
      expect(back.defaultCategory, isNull);
      expect(back.createdAt, isA<DateTime>());
    });
  });

  group('PurposePreset JSON', () {
    test('round trip', () {
      const preset = PurposePreset(
        id: 'pp1',
        name: 'Client visit',
        category: TripCategory.business,
        sortOrder: 2,
      );
      final back = PurposePreset.fromJson(preset.toJson());

      expect(back.id, 'pp1');
      expect(back.name, 'Client visit');
      expect(back.category, TripCategory.business);
      expect(back.sortOrder, 2);
    });

    test('unknown category falls back to other', () {
      final back = PurposePreset.fromJson(<String, dynamic>{
        'id': 'pp2',
        'name': 'Weird',
        'category': 'no-such-category',
        'sortOrder': 0,
      });
      expect(back.category, TripCategory.other);
    });
  });
}
