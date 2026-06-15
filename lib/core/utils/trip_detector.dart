import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/utils/distance_calculator.dart';

/// Heuristics for automatic trip start / end detection.
/// Matches the spec exactly:
/// - Start: speed > 5 mph sustained for 90+ seconds
/// - End: speed < 1 mph for 4+ minutes
/// - Ignore trips < 0.2 miles
class TripDetector {
  // Config (can be tuned via settings later)
  static const double startSpeedMph = 5.0;
  static const Duration startSustained = Duration(seconds: 90);

  static const double endSpeedMph = 1.0;
  static const Duration endSustained = Duration(minutes: 4);

  static const double minTripDistanceMiles = 0.2;

  /// Current motion state machine.
  DateTime? _movingStart;
  DateTime? _stoppedStart;
  double _lastSpeedMph = 0;
  LatLng? _lastPosition;

  /// Accumulated distance while "in trip" (for early filtering)
  double _currentAccumulatedMiles = 0;

  bool _inPotentialTrip = false;

  /// Feed a new GPS point + speed (mph). Returns TripState change if any.
  TripDetectionResult processLocation({
    required LatLng position,
    required double speedMph, // from GPS or calculated
    required DateTime timestamp,
  }) {
    final prevPos = _lastPosition;
    _lastPosition = position;
    _lastSpeedMph = speedMph;

    if (prevPos != null) {
      final delta = DistanceCalculator.distanceBetween(prevPos, position);
      if (_inPotentialTrip) {
        _currentAccumulatedMiles += delta;
      }
    }

    // --- Trip START detection ---
    if (!_inPotentialTrip) {
      if (speedMph > startSpeedMph) {
        _movingStart ??= timestamp;
        final sustained = timestamp.difference(_movingStart!);
        if (sustained >= startSustained) {
          _inPotentialTrip = true;
          _stoppedStart = null;
          _currentAccumulatedMiles = 0; // reset for accuracy, we'll recalc on end
          return TripDetectionResult.started(timestamp);
        }
      } else {
        _movingStart = null;
      }
    }

    // --- Trip END detection ---
    if (_inPotentialTrip) {
      if (speedMph < endSpeedMph) {
        _stoppedStart ??= timestamp;
        final stoppedDuration = timestamp.difference(_stoppedStart!);
        if (stoppedDuration >= endSustained) {
          // Candidate end. Check min distance.
          final dist = _currentAccumulatedMiles;
          if (dist >= minTripDistanceMiles) {
            final result = TripDetectionResult.ended(
              endTime: timestamp,
              distanceMiles: dist,
            );
            _reset();
            return result;
          } else {
            // False positive, reset
            _reset();
            return TripDetectionResult.ignoredTooShort();
          }
        }
      } else {
        _stoppedStart = null; // still moving
      }
    }

    return TripDetectionResult.none();
  }

  void _reset() {
    _inPotentialTrip = false;
    _movingStart = null;
    _stoppedStart = null;
    _currentAccumulatedMiles = 0;
  }

  /// Force end current potential trip (e.g. app killed, manual).
  TripDetectionResult forceEnd(DateTime now, double finalDistance) {
    if (!_inPotentialTrip || finalDistance < minTripDistanceMiles) {
      _reset();
      return TripDetectionResult.none();
    }
    final res = TripDetectionResult.ended(endTime: now, distanceMiles: finalDistance);
    _reset();
    return res;
  }

  double get lastSpeedMph => _lastSpeedMph;
  bool get isPotentialTrip => _inPotentialTrip;
}

/// Result of feeding a location to the detector.
class TripDetectionResult {
  final TripDetectionEvent event;
  final DateTime? time;
  final double? distanceMiles;

  TripDetectionResult._(this.event, {this.time, this.distanceMiles});

  factory TripDetectionResult.none() =>
      TripDetectionResult._(TripDetectionEvent.none);
  factory TripDetectionResult.started(DateTime t) =>
      TripDetectionResult._(TripDetectionEvent.started, time: t);
  factory TripDetectionResult.ended(
          {required DateTime endTime, required double distanceMiles}) =>
      TripDetectionResult._(TripDetectionEvent.ended,
          time: endTime, distanceMiles: distanceMiles);
  factory TripDetectionResult.ignoredTooShort() =>
      TripDetectionResult._(TripDetectionEvent.ignoredTooShort);

  bool get isStart => event == TripDetectionEvent.started;
  bool get isEnd => event == TripDetectionEvent.ended;
  bool get shouldIgnore => event == TripDetectionEvent.ignoredTooShort;
}

enum TripDetectionEvent { none, started, ended, ignoredTooShort }
