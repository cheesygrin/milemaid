import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/utils/distance_calculator.dart';

/// Meters per mile, for converting [DistanceCalculator] miles to meters.
const double metersPerMile = 1609.344;

/// The nearest place whose distance from (lat, lng) is within its own
/// [NamedLocation.radiusMeters], or null when no place matches.
NamedLocation? matchLocation(
  double lat,
  double lng,
  List<NamedLocation> places,
) {
  final point = LatLng(lat, lng);
  NamedLocation? best;
  double bestMeters = double.infinity;
  for (final place in places) {
    final miles = DistanceCalculator.distanceBetween(
      LatLng(place.latitude, place.longitude),
      point,
    );
    final meters = miles * metersPerMile;
    if (meters <= place.radiusMeters && meters < bestMeters) {
      best = place;
      bestMeters = meters;
    }
  }
  return best;
}

/// Label for a trip endpoint: the place name if [locationId] resolves,
/// else the raw [address], else "Unknown place".
String placeLabel(
  String? locationId,
  String? address,
  Map<String, NamedLocation> placesById,
) {
  if (locationId != null) {
    final place = placesById[locationId];
    if (place != null) return place.name;
  }
  final trimmed = address?.trim() ?? '';
  if (trimmed.isNotEmpty) return trimmed;
  return 'Unknown place';
}
