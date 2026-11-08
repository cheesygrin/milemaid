import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/utils/trip_detector.dart';

// Synthetic coordinates only (open country, not a real route).
const _origin = LatLng(40.0, -100.0);
const _milesPerDegreeLat = 69.05;

/// Simulates a phone feeding GPS fixes to the detector.
class _Sim {
  _Sim(this.detector, this.now);

  final TripDetector detector;
  DateTime now;
  LatLng pos = _origin;
  final events = <TripDetectionResult>[];

  TripDetectionResult fix(double speedMph, {double? reportedSpeed}) {
    final r = detector.processLocation(
      position: pos,
      speedMph: reportedSpeed ?? speedMph,
      timestamp: now,
      accuracyMeters: 10,
    );
    if (r.event != TripDetectionEvent.none) events.add(r);
    return r;
  }

  /// Moves north at [speedMph] for [duration], one fix every [every].
  void drive(double speedMph, Duration duration,
      {Duration every = const Duration(seconds: 10), bool reportSpeed = true}) {
    final steps = duration.inSeconds ~/ every.inSeconds;
    for (var i = 0; i < steps; i++) {
      now = now.add(every);
      final miles = speedMph * every.inSeconds / 3600;
      pos = LatLng(pos.latitude + miles / _milesPerDegreeLat, pos.longitude);
      fix(speedMph, reportedSpeed: reportSpeed ? null : -1);
    }
  }

  TripDetectionResult wait(Duration d) {
    now = now.add(d);
    final r = detector.checkTimeout(now);
    if (r.event != TripDetectionEvent.none) events.add(r);
    return r;
  }

  List<TripDetectionResult> get ended => events.where((e) => e.isEnd).toList();
}

void main() {
  late _Sim sim;
  final t0 = DateTime(2026, 11, 9, 8, 0);

  setUp(() {
    sim = _Sim(TripDetector(), t0);
    sim.fix(0); // parked at the start
  });

  test('a drive ends 4 minutes after parking even with no new GPS fixes', () {
    sim.drive(30, const Duration(minutes: 10)); // 5 miles
    final arrived = sim.now;

    expect(sim.wait(const Duration(minutes: 3)).event, TripDetectionEvent.none);
    final r = sim.wait(const Duration(minutes: 2));

    expect(r.isEnd, isTrue);
    expect(r.distanceMiles, closeTo(5.0, 0.05));
    expect(r.startTime, t0.add(const Duration(seconds: 10)));
    expect(r.time, arrived);
  });

  test('reports the start once the drive is established', () {
    sim.drive(30, const Duration(minutes: 3));
    final starts = sim.events.where((e) => e.isStart).toList();
    expect(starts, hasLength(1));
    expect(starts.single.time, t0.add(const Duration(seconds: 10)));
  });

  test('walking around a job site neither adds miles nor keeps the drive open', () {
    sim.drive(30, const Duration(minutes: 10)); // 5 miles
    final arrived = sim.now;

    // 20 minutes of walking at 3 mph with fixes every 30 s.
    sim.drive(3, const Duration(minutes: 20), every: const Duration(seconds: 30));

    expect(sim.ended, hasLength(1));
    final trip = sim.ended.single;
    expect(trip.distanceMiles, closeTo(5.0, 0.05));
    expect(trip.time, arrived);
  });

  test('two drives with a long stop in between are two trips', () {
    sim.drive(40, const Duration(minutes: 15)); // 10 miles
    // Parked for two hours with no fixes and no timer (app suspended).
    sim.now = sim.now.add(const Duration(hours: 2));
    sim.drive(40, const Duration(minutes: 15)); // 10 miles home
    sim.wait(const Duration(minutes: 5));

    expect(sim.ended, hasLength(2));
    expect(sim.ended[0].distanceMiles, closeTo(10.0, 0.1));
    // The second drive starts from where the car was parked.
    expect(sim.ended[1].distanceMiles, closeTo(10.0, 0.1));
  });

  test('a parking-lot shuffle is ignored', () {
    sim.drive(10, const Duration(seconds: 30)); // ~0.08 miles
    final r = sim.wait(const Duration(minutes: 5));
    expect(r.shouldIgnore, isTrue);
    expect(sim.ended, isEmpty);
  });

  test('speed is derived from distance when the phone reports none', () {
    sim.drive(30, const Duration(minutes: 10), reportSpeed: false);
    sim.wait(const Duration(minutes: 5));
    expect(sim.ended, hasLength(1));
    expect(sim.ended.single.distanceMiles, closeTo(5.0, 0.05));
  });

  test('a GPS jump is not counted as miles', () {
    sim.drive(30, const Duration(minutes: 5)); // 2.5 miles
    // One bogus fix 20 miles away, 10 s later.
    sim.now = sim.now.add(const Duration(seconds: 10));
    final real = sim.pos;
    sim.pos = LatLng(real.latitude + 20 / _milesPerDegreeLat, real.longitude);
    sim.fix(30);
    sim.pos = real;
    sim.drive(30, const Duration(minutes: 5)); // 2.5 more miles
    sim.wait(const Duration(minutes: 5));

    expect(sim.ended, hasLength(1));
    expect(sim.ended.single.distanceMiles, closeTo(5.0, 0.1));
  });
}
