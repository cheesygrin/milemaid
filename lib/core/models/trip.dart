import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/models/trip_expense.dart';

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
    /// Optional user-defined category label (overrides the enum name in UI).
    String? customCategoryLabel,
    /// ARGB color for the custom category label.
    int? customCategoryColor,
    String? purpose,
    String? notes,
    /// Human-readable start/end addresses (resolved via optional geocoding).
    String? startAddress,
    String? endAddress,
    /// Tolls, parking, and other out-of-pocket expenses attached to the trip.
    @Default([]) List<TripExpense> expenses,
    String? vehicleId,
    double? startOdometer,
    double? endOdometer,
    @Default(false) bool isConfirmed,
    String? startLocationId,
    String? endLocationId,
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
      customCategoryLabel: json['customCategoryLabel'] as String?,
      customCategoryColor: json['customCategoryColor'] as int?,
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      startAddress: json['startAddress'] as String?,
      endAddress: json['endAddress'] as String?,
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => TripExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      vehicleId: json['vehicleId'] as String?,
      startOdometer: (json['startOdometer'] as num?)?.toDouble(),
      endOdometer: (json['endOdometer'] as num?)?.toDouble(),
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      // Optional enrichment fields: missing keys -> null so old stored trips
      // (pre-addresses) still load unchanged.
      startLocationId: json['startLocationId'] as String?,
      endLocationId: json['endLocationId'] as String?,
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
        'customCategoryLabel': customCategoryLabel,
        'customCategoryColor': customCategoryColor,
        'purpose': purpose,
        'notes': notes,
        'startAddress': startAddress,
        'endAddress': endAddress,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'vehicleId': vehicleId,
        'startOdometer': startOdometer,
        'endOdometer': endOdometer,
        'isConfirmed': isConfirmed,
        'startLocationId': startLocationId,
        'endLocationId': endLocationId,
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

  /// Business miles count only once the user has reviewed the trip.
  bool get countsAsBusiness => category == TripCategory.business && isConfirmed;

  /// True when a user-defined category label is attached.
  bool get hasCustomCategory =>
      customCategoryLabel != null && customCategoryLabel!.isNotEmpty;

  /// Display label: the custom label if present, else the enum name.
  String get categoryLabel =>
      hasCustomCategory ? customCategoryLabel! : category.displayName;

  /// Total of attached expenses in cents (exact integer, for aggregation).
  int get totalExpenseCents =>
      expenses.fold(0, (sum, e) => sum + e.amountCents);

  /// Total of attached expenses (tolls, parking, etc.), in dollars.
  double get totalExpenses => totalExpenseCents / 100.0;
}