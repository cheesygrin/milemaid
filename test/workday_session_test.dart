import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/workday_session.dart';

/// Synthetic Nebraska coords only (AGENTS.md).
final _created = DateTime.parse('2026-03-10T08:00:00');

NamedLocation _home() => NamedLocation(
      id: 'home',
      name: 'Home',
      latitude: 40.0,
      longitude: -100.0,
      isHome: true,
      createdAt: _created,
    );

Trip _trip({
  required String id,
  required DateTime start,
  required DateTime end,
  String? startId,
  String? endId,
  bool confirmed = false,
  double miles = 5,
}) {
  return Trip(
    id: id,
    startTime: start,
    endTime: end,
    distanceMiles: miles,
    durationMinutes: end.difference(start).inMinutes.clamp(1, 9999),
    routePoints: const [
      LatLngPoint(latitude: 40.0, longitude: -100.0),
      LatLngPoint(latitude: 40.01, longitude: -100.01),
    ],
    category: confirmed ? TripCategory.business : TripCategory.other,
    isConfirmed: confirmed,
    startLocationId: startId,
    endLocationId: endId,
  );
}

void main() {
  final home = _home();
  final day = DateTime(2026, 3, 10);

  test('homePlace returns the marked Home', () {
    expect(homePlace([home])?.id, 'home');
    expect(homePlace([home.copyWith(isHome: false)]), isNull);
  });

  test('detects a leave-Home then return-Home loop', () {
    final leave = _trip(
      id: '1',
      start: day.add(const Duration(hours: 8)),
      end: day.add(const Duration(hours: 8, minutes: 20)),
      startId: 'home',
      endId: 'client',
    );
    final mid = _trip(
      id: '2',
      start: day.add(const Duration(hours: 12)),
      end: day.add(const Duration(hours: 12, minutes: 30)),
      startId: 'client',
      endId: 'supply',
    );
    final back = _trip(
      id: '3',
      start: day.add(const Duration(hours: 17)),
      end: day.add(const Duration(hours: 17, minutes: 40)),
      startId: 'supply',
      endId: 'home',
    );

    final session = detectReturnHomeSession(
      justEnded: back,
      allTrips: [leave, mid, back],
      home: home,
    );

    expect(session, isNotNull);
    expect(session!.tripIds, ['1', '2', '3']);
    expect(session.unconfirmed.length, 3);
    expect(session.totalMiles, 15);
  });

  test('ignores a single drive that never left as a multi-leg day', () {
    final loop = _trip(
      id: 'solo',
      start: day.add(const Duration(hours: 9)),
      end: day.add(const Duration(hours: 10)),
      startId: 'home',
      endId: 'home',
    );
    expect(
      detectReturnHomeSession(justEnded: loop, allTrips: [loop], home: home),
      isNull,
    );
  });

  test('ignores a return that did not start from Home earlier', () {
    final errand = _trip(
      id: 'x',
      start: day.add(const Duration(hours: 14)),
      end: day.add(const Duration(hours: 15)),
      startId: 'store',
      endId: 'home',
    );
    expect(
      detectReturnHomeSession(
        justEnded: errand,
        allTrips: [errand],
        home: home,
      ),
      isNull,
    );
  });

  test('unconfirmed excludes already classified legs', () {
    final leave = _trip(
      id: '1',
      start: day.add(const Duration(hours: 8)),
      end: day.add(const Duration(hours: 8, minutes: 20)),
      startId: 'home',
      endId: 'client',
      confirmed: true,
    );
    final mid = _trip(
      id: '2',
      start: day.add(const Duration(hours: 12)),
      end: day.add(const Duration(hours: 12, minutes: 30)),
      startId: 'client',
      endId: 'supply',
    );
    final back = _trip(
      id: '3',
      start: day.add(const Duration(hours: 17)),
      end: day.add(const Duration(hours: 17, minutes: 40)),
      startId: 'supply',
      endId: 'home',
    );
    final session = detectReturnHomeSession(
      justEnded: back,
      allTrips: [leave, mid, back],
      home: home,
    )!;
    expect(session.unconfirmed.map((t) => t.id), ['2', '3']);
  });
}
