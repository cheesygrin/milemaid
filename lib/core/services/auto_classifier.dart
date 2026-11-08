import 'dart:math';

import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/work_hours.dart';

/// Decides whether a freshly detected drive can be classified automatically.
///
/// Rules are evaluated in order and the first match wins: Work Hours, then
/// Named Locations. (A frequent-drive rule can be added later.)
class AutoClassifier {
  /// Returns a category to pre-assign, or null to leave the drive unreviewed.
  TripCategory? classify({
    required DateTime startTime,
    required double startLat,
    required double startLng,
    required List<WorkHours> workHours,
    required List<NamedLocation> namedLocations,
  }) {
    for (final wh in workHours) {
      if (wh.covers(startTime)) return TripCategory.business;
    }
    for (final loc in namedLocations) {
      if (_within(startLat, startLng, loc)) return loc.category;
    }
    return null;
  }

  /// Approximate haversine-lite distance check (flat-earth over short ranges),
  /// good enough for a 100 m radius without a full geodesic computation.
  static bool _within(double lat, double lng, NamedLocation loc) {
    final dLat = (lat - loc.lat) * 111320.0;
    final dLng =
        (lng - loc.lng) * 111320.0 * cos(loc.lat * pi / 180.0);
    return sqrt(dLat * dLat + dLng * dLng) <= loc.radiusMeters;
  }
}