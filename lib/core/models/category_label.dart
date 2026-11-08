/// A user-defined category label (MileIQ-style custom category).
class CategoryLabel {
  final String id;
  final String label;
  /// ARGB color, e.g. from `Color.toARGB32()`.
  final int colorValue;

  const CategoryLabel({
    required this.id,
    required this.label,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorValue': colorValue,
      };

  static CategoryLabel fromJson(Map<String, dynamic> j) => CategoryLabel(
        id: j['id'] as String,
        label: j['label'] as String,
        colorValue: j['colorValue'] as int,
      );
}