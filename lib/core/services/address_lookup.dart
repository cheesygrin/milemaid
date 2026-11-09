import 'package:geocoding/geocoding.dart';

/// Source of human-readable addresses for coordinates. Abstract so tests and
/// the enricher can run without platform plugins.
abstract class AddressLookup {
  /// Best-effort address for the given coordinates, or null when nothing is
  /// found. Never throws.
  Future<String?> addressFor(double lat, double lng);
}

/// Real implementation backed by the platform geocoder (geocoding package).
final class PlatformAddressLookup implements AddressLookup {
  PlatformAddressLookup();

  final Geocoding _geocoder = Geocoding();

  @override
  Future<String?> addressFor(double lat, double lng) async {
    try {
      final placemarks = await _geocoder.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      return _format(placemarks.first);
    } catch (_) {
      // Missing permissions, no geocoder on device, rate limits, etc.
      return null;
    }
  }

  /// `"<subThoroughfare> <thoroughfare>, <locality>"` when there is a street,
  /// otherwise `"<name>, <locality>"`, otherwise `"<locality>, <administrativeArea>"`.
  /// Empty parts are trimmed; anything still empty is not emitted.
  String? _format(Placemark p) {
    final street = [p.subThoroughfare, p.thoroughfare]
        .map((s) => s?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .join(' ');
    final locality = p.locality?.trim() ?? '';
    final name = p.name?.trim() ?? '';
    final adminArea = p.administrativeArea?.trim() ?? '';

    if (street.isNotEmpty && locality.isNotEmpty) {
      return '$street, $locality';
    }
    if (name.isNotEmpty && locality.isNotEmpty) {
      return '$name, $locality';
    }
    if (locality.isNotEmpty && adminArea.isNotEmpty) {
      return '$locality, $adminArea';
    }
    // Degrade gracefully when a part the formats above expect is missing.
    final fallback = [street, name, locality, adminArea]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return fallback.isEmpty ? null : fallback;
  }
}
