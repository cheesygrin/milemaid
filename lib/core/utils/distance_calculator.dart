import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Haversine formula for accurate Earth distance between two points.
class DistanceCalculator {
  static const double _earthRadiusMiles = 3958.8;

  /// Returns distance in miles between two LatLng points.
  static double distanceBetween(LatLng a, LatLng b) {
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);

    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return _earthRadiusMiles * c;
  }

  /// Total distance for a list of points (sum of segments).
  static double totalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceBetween(points[i], points[i + 1]);
    }
    return total;
  }

  /// Average speed in mph given distance (miles) and duration (minutes).
  static double averageSpeedMph(double distanceMiles, int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    return (distanceMiles / durationMinutes) * 60;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);
}
