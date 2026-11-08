/// A saved place used to auto-classify drives that start nearby.
class NamedLocation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int radiusMeters;

  const NamedLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.radiusMeters = 100,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
      };

  static NamedLocation fromJson(Map<String, dynamic> j) => NamedLocation(
        id: j['id'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusMeters: j['radiusMeters'] as int? ?? 100,
      );
}