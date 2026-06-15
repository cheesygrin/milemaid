import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'trip.freezed.dart';

/// IRS-friendly trip categories.
enum TripCategory {
  business,
  personal,
  commute,
  other,
}

extension TripCategoryX on TripCategory {
  String get displayName {
    switch (this) {
      case TripCategory.business:
        return 'Business';
      case TripCategory.personal:
        return 'Personal';
      case TripCategory.commute:
        return 'Commute';
      case TripCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case TripCategory.business:
        return '💼';
      case TripCategory.personal:
        return '🏠';
      case TripCategory.commute:
        return '🚗';
      case TripCategory.other:
        return '📍';
    }
  }
}

/// Serializable geographic point (stored inside Trip JSON).
class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({required this.latitude, required this.longitude});

  factory LatLngPoint.fromLatLng(LatLng latLng) =>
      LatLngPoint(latitude: latLng.latitude, longitude: latLng.longitude);

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory LatLngPoint.fromJson(Map<String, dynamic> json) => LatLngPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// Core Trip model. Freezed for immutability. JSON via freezed for easy storage.
@freezed
class Trip with _$Trip {
  const Trip._();

  const factory Trip({
    required String id,
    required DateTime startTime,
    required DateTime endTime,
    required double distanceMiles,
    required int durationMinutes,
    required List<LatLngPoint> routePoints,
    required TripCategory category,
    String? purpose,
    String? notes,
    String? vehicleId,
    double? startOdometer,
    double? endOdometer,
    @Default(false) bool isConfirmed,
  }) = _Trip;

  // Manual JSON (freezed json disabled to avoid generator conflicts with our Hive JSON storage)
  static Trip fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      distanceMiles: (json['distanceMiles'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      routePoints: (json['routePoints'] as List<dynamic>)
          .map((e) => LatLngPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      category: TripCategory.values.firstWhere((c) => c.name == (json['category'] as String)),
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      vehicleId: json['vehicleId'] as String?,
      startOdometer: (json['startOdometer'] as num?)?.toDouble(),
      endOdometer: (json['endOdometer'] as num?)?.toDouble(),
      isConfirmed: json['isConfirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distanceMiles': distanceMiles,
        'durationMinutes': durationMinutes,
        'routePoints': routePoints.map((p) => p.toJson()).toList(),
        'category': category.name,
        'purpose': purpose,
        'notes': notes,
        'vehicleId': vehicleId,
        'startOdometer': startOdometer,
        'endOdometer': endOdometer,
        'isConfirmed': isConfirmed,
      };

  /// Convenience: convert stored points back to Google Maps LatLng list.
  List<LatLng> get routeLatLng =>
      routePoints.map((p) => p.toLatLng()).toList();

  /// Human readable duration e.g. "42 min"
  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}m';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  /// e.g. "12.4 mi"
  String get formattedDistance => '${distanceMiles.toStringAsFixed(1)} mi';
}
