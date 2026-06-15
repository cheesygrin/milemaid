import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';

@freezed
class Vehicle with _$Vehicle {
  const Vehicle._();

  const factory Vehicle({
    required String id,
    required String name,
    required String makeModel,
    @Default(2024) int year,
    String? color,
    String? licensePlate,
    /// Optional per-vehicle custom rate override (null = use global)
    double? customRatePerMile,
  }) = _Vehicle;

  // Manual JSON (avoid freezed json gen issues)
  static Vehicle fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        name: json['name'] as String,
        makeModel: json['makeModel'] as String,
        year: json['year'] as int? ?? 2024,
        color: json['color'] as String?,
        licensePlate: json['licensePlate'] as String?,
        customRatePerMile: (json['customRatePerMile'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'makeModel': makeModel,
        'year': year,
        'color': color,
        'licensePlate': licensePlate,
        'customRatePerMile': customRatePerMile,
      };

  /// Display label e.g. "2022 Toyota Camry (Blue)"
  String get displayLabel {
    final c = color != null ? ' ($color)' : '';
    return '$year $makeModel$c';
  }
}
