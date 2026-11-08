import 'dart:convert';
import 'dart:io';

/// Reverse-geocodes coordinates to a human-readable address using Nominatim
/// (OpenStreetMap, free, no key). Off by default: it sends coordinates to a
/// third party, so the caller gates it behind the user's geocoding preference.
class GeocodeService {
  const GeocodeService({this.baseUrl = 'https://nominatim.openstreetmap.org'});

  final String baseUrl;

  Uri buildReverseUri({required double lat, required double lng}) =>
      Uri.parse('$baseUrl/reverse').replace(queryParameters: {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lng.toString(),
        'zoom': '16',
      });

  /// Extracts the display name from a Nominatim `reverse` JSON response.
  String? addressFromJson(Map<String, dynamic> json) =>
      json['display_name'] as String?;

  Future<String?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client
          .getUrl(buildReverseUri(lat: lat, lng: lng))
          .timeout(const Duration(seconds: 10));
      // Nominatim requires a meaningful User-Agent.
      req.headers.set('User-Agent', 'MileMaid/1.0 (on-device mileage tracker)');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return addressFromJson(data);
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}