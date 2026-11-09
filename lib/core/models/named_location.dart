import 'package:milemaid/core/models/trip.dart';

/// A user-named place (e.g. "Office", "Gym") with a geofence radius used to
/// label trips automatically. Plain Dart model: hand-written JSON, no codegen.
class NamedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Geofence radius in meters: a trip point within this distance of the
  /// place matches it.
  final double radiusMeters;
  final String? address;
  final TripCategory? defaultCategory;

  /// Free-text purpose applied when the user classifies a trip at this place.
  final String? defaultPurpose;
  final DateTime createdAt;

  const NamedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
    this.address,
    this.defaultCategory,
    this.defaultPurpose,
    required this.createdAt,
  });

  NamedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? address,
    TripCategory? defaultCategory,
    String? defaultPurpose,
    DateTime? createdAt,
  }) {
    return NamedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      address: address ?? this.address,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultPurpose: defaultPurpose ?? this.defaultPurpose,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'address': address,
        'defaultCategory': defaultCategory?.name,
        'defaultPurpose': defaultPurpose,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Tolerant: unknown/missing optional keys become null; invalid or missing
  /// category names are ignored so stored data never fails to load.
  factory NamedLocation.fromJson(Map<String, dynamic> json) {
    return NamedLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150,
      address: json['address'] as String?,
      defaultCategory: TripCategory.values
          .where((c) => c.name == (json['defaultCategory'] as String?))
          .firstOrNull,
      defaultPurpose: json['defaultPurpose'] as String?,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
