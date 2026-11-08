/// Types of non-mileage trip expenses (MileIQ-style tolls & parking).
enum ExpenseType {
  toll,
  parking,
  other,
}

extension ExpenseTypeX on ExpenseType {
  String get displayName {
    switch (this) {
      case ExpenseType.toll:
        return 'Toll';
      case ExpenseType.parking:
        return 'Parking';
      case ExpenseType.other:
        return 'Other';
    }
  }
}

/// A toll, parking fee, or other expense attached to a trip.
class TripExpense {
  final String id;
  final ExpenseType type;
  final int amountCents;
  final String? note;

  const TripExpense({
    required this.id,
    required this.type,
    required this.amountCents,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amountCents': amountCents,
        'note': note,
      };

  static TripExpense fromJson(Map<String, dynamic> j) => TripExpense(
        id: j['id'] as String,
        type: ExpenseType.values.firstWhere((e) => e.name == (j['type'] as String)),
        amountCents: j['amountCents'] as int,
        note: j['note'] as String?,
      );
}