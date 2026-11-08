import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/utils/distance_calculator.dart';

/// Heuristics for automatic trip start / end detection.
///
/// A drive begins at the first GPS fix at driving speed and ends once no
/// driving-speed fix has been seen for [endAfterNoDriving]. The end check does
/// not depend on new GPS fixes arriving: iOS sends nothing while the phone sits
/// still, so [checkTimeout] is called from a timer, and every new fix also
/// checks whether the previous drive already ended (for example after the app
/// was suspended while parked).
///
/// Only driven segments count toward distance, so walking around a job site
/// with the phone never adds miles or keeps a drive open.
class TripDetector {
  /// Speed at or above which the phone is considered to be in a moving vehicle.
  /// Walking (~3 mph) and GPS jitter while indoors stay below this.
  static const double drivingSpeedMph = 8.0;

  /// A drive is reported as started (live UI) once it has been at driving
  /// speed for this long, or has covered [startConfirmMiles].
  static const Duration startSustained = Duration(seconds: 90);
  static const double startConfirmMiles = 0.3;

  /// A drive ends after this long without any driving-speed fix.
  static const Duration endAfterNoDriving = Duration(minutes: 4);

  /// Drives shorter than this are discarded (parking-lot shuffles).
  static const double minTripDistanceMiles = 0.2;

  /// Fixes worse than this horizontal accuracy are not used for distance.
  static const double maxAccuracyMeters = 100;

  /// Segments implying a faster speed than this are GPS jumps and are ignored.
  static const double maxPlausibleSpeedMph = 130;

  LatLng? _lastPosition;
  DateTime? _lastTimestamp;
  double _lastSpeedMph = 0;

  // Current drive (candidate or confirmed).
  DateTime? _movingStart;
  DateTime? _lastDrivingTime;
  LatLng? _startPosition;
  LatLng? _endPosition;
  double _miles = 0;
  bool _confirmed = false;
  final List<LatLng> _route = [];

  /// Feed a new GPS fix. [speedMph] may be negative when the platform reports
  /// no valid speed; it is then derived from the distance between fixes.
  TripDetectionResult processLocation({
    required LatLng position,
    required double speedMph,
    required DateTime timestamp,
    double? accuracyMeters,
  }) {
    // A long gap since the last driving fix means the previous drive ended
    // while no fixes were arriving. Close it before handling this fix.
    final timedOut = checkTimeout(timestamp);

    final prevPos = _lastPosition;
    final prevTime = _lastTimestamp;
    final prevSpeed = _lastSpeedMph;

    final accurate =
        accuracyMeters == null || accuracyMeters <= maxAccuracyMeters;
    final segMiles = prevPos == null
        ? 0.0
        : DistanceCalculator.distanceBetween(prevPos, position);

    double speed = speedMph;
    double? segSpeed;
    if (prevPos != null && prevTime != null) {
      final hours = timestamp.difference(prevTime).inMilliseconds / 3600000.0;
      if (hours > 0) segSpeed = segMiles / hours;
    }
    if (speed < 0) speed = segSpeed ?? 0;

    final plausible = segSpeed == null || segSpeed <= maxPlausibleSpeedMph;
    if (!accurate || !plausible) {
      // Keep the clock moving but don't trust this fix for distance/speed.
      return timedOut;
    }

    _lastPosition = position;
    _lastTimestamp = timestamp;
    _lastSpeedMph = speed;

    final driving = speed >= drivingSpeedMph;

    if (_movingStart == null) {
      if (driving) {
        _movingStart = timestamp;
        _lastDrivingTime = timestamp;
        _startPosition = prevPos ?? position;
        _endPosition = position;
        _route
          ..clear()
          ..add(_startPosition!);
        if (prevPos != null) {
          _miles = segMiles;
          _route.add(position);
        } else {
          _miles = 0;
        }
        _confirmed = false;
      }
      return timedOut;
    }

    // Inside a drive: count only driven segments.
    final segmentDriven = driving || prevSpeed >= drivingSpeedMph;
    if (segmentDriven && prevPos != null) {
      _miles += segMiles;
      _route.add(position);
      _endPosition = position;
    }
    if (driving) _lastDrivingTime = timestamp;

    if (!_confirmed) {
      final drivenFor = _lastDrivingTime!.difference(_movingStart!);
      if (drivenFor >= startSustained || _miles >= startConfirmMiles) {
        _confirmed = true;
        // A drive that just timed out takes priority; the new one still
        // shows up through [isPotentialTrip] / [currentStart].
        if (timedOut.event == TripDetectionEvent.none) {
          return TripDetectionResult.started(_movingStart!);
        }
      }
    }

    return timedOut;
  }

  /// Ends the current drive if nothing at driving speed has been seen for
  /// [endAfterNoDriving]. Safe to call at any time (e.g. from a timer).
  TripDetectionResult checkTimeout(DateTime now) {
    if (_movingStart == null || _lastDrivingTime == null) {
      return TripDetectionResult.none();
    }
    if (now.difference(_lastDrivingTime!) < endAfterNoDriving) {
      return TripDetectionResult.none();
    }
    return _finish();
  }

  TripDetectionResult _finish() {
    final start = _movingStart!;
    final end = _lastDrivingTime!;
    final miles = _miles;
    final route = List<LatLng>.from(_route);
    final startPos = _startPosition;
    final endPos = _endPosition;
    _reset();

    if (miles < minTripDistanceMiles) {
      return TripDetectionResult.ignoredTooShort();
    }
    return TripDetectionResult.ended(
      startTime: start,
      endTime: end,
      distanceMiles: miles,
      route: route,
      startPosition: startPos,
      endPosition: endPos,
    );
  }

  void _reset() {
    _movingStart = null;
    _lastDrivingTime = null;
    _startPosition = null;
    _endPosition = null;
    _miles = 0;
    _confirmed = false;
    _route.clear();
  }

  /// Force end the current drive (e.g. tracking stopped).
  TripDetectionResult forceEnd(DateTime now) {
    if (_movingStart == null) return TripDetectionResult.none();
    return _finish();
  }

  double get lastSpeedMph => _lastSpeedMph;

  /// True once the current movement qualifies as a drive (for live UI).
  bool get isPotentialTrip => _movingStart != null && _confirmed;

  DateTime? get currentStart => _movingStart;
  double get currentMiles => _miles;
  List<LatLng> get currentRoute => List.unmodifiable(_route);
}

/// Result of feeding a location to the detector.
class TripDetectionResult {
  final TripDetectionEvent event;
  final DateTime? time;
  final DateTime? startTime;
  final double? distanceMiles;
  final List<LatLng> route;
  final LatLng? startPosition;
  final LatLng? endPosition;

  TripDetectionResult._(
    this.event, {
    this.time,
    this.startTime,
    this.distanceMiles,
    this.route = const [],
    this.startPosition,
    this.endPosition,
  });

  factory TripDetectionResult.none() =>
      TripDetectionResult._(TripDetectionEvent.none);
  factory TripDetectionResult.started(DateTime t) => TripDetectionResult._(
      TripDetectionEvent.started,
      time: t,
      startTime: t);
  factory TripDetectionResult.ended({
    required DateTime startTime,
    required DateTime endTime,
    required double distanceMiles,
    required List<LatLng> route,
    LatLng? startPosition,
    LatLng? endPosition,
  }) =>
      TripDetectionResult._(
        TripDetectionEvent.ended,
        time: endTime,
        startTime: startTime,
        distanceMiles: distanceMiles,
        route: route,
        startPosition: startPosition,
        endPosition: endPosition,
      );
  factory TripDetectionResult.ignoredTooShort() =>
      TripDetectionResult._(TripDetectionEvent.ignoredTooShort);

  bool get isStart => event == TripDetectionEvent.started;
  bool get isEnd => event == TripDetectionEvent.ended;
  bool get shouldIgnore => event == TripDetectionEvent.ignoredTooShort;
}

enum TripDetectionEvent { none, started, ended, ignoredTooShort }
