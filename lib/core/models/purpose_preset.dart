import 'package:milemaid/core/models/trip.dart';

/// A named trip-purpose preset the user can pick when classifying a drive
/// (e.g. "Client visit" -> business). Plain Dart model: hand-written JSON.
class PurposePreset {
  final String id;
  final String name;
  final TripCategory category;
  final int sortOrder;

  const PurposePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.sortOrder,
  });

  PurposePreset copyWith({
    String? id,
    String? name,
    TripCategory? category,
    int? sortOrder,
  }) {
    return PurposePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'sortOrder': sortOrder,
      };

  /// Tolerant: an unknown category name falls back to [TripCategory.other].
  factory PurposePreset.fromJson(Map<String, dynamic> json) {
    return PurposePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: TripCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String?),
        orElse: () => TripCategory.other,
      ),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
