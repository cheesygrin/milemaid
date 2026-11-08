import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/category_label.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';

Trip _trip({TripCategory category = TripCategory.other, String? customLabel, int? customColor}) {
  return Trip(
    id: 't',
    startTime: DateTime(2026, 6, 15, 10),
    endTime: DateTime(2026, 6, 15, 10, 30),
    distanceMiles: 1,
    durationMinutes: 30,
    routePoints: const [],
    category: category,
    customCategoryLabel: customLabel,
    customCategoryColor: customColor,
  );
}

void main() {
  test('CategoryLabel JSON round-trip', () {
    const c = CategoryLabel(id: 'c1', label: 'Rideshare', colorValue: 0xFF00BCD4);
    final back = CategoryLabel.fromJson(c.toJson());
    expect(back.id, 'c1');
    expect(back.label, 'Rideshare');
    expect(back.colorValue, 0xFF00BCD4);
  });

  test('Trip.categoryLabel prefers the custom label', () {
    expect(_trip(customLabel: 'Charity').categoryLabel, 'Charity');
    expect(_trip(customLabel: 'Charity').hasCustomCategory, isTrue);
  });

  test('Trip.categoryLabel falls back to the enum name', () {
    expect(_trip(category: TripCategory.commute).categoryLabel, 'Commute');
    expect(_trip(category: TripCategory.commute).hasCustomCategory, isFalse);
  });

  test('Trip custom label + color round-trip through JSON', () {
    final t = _trip(customLabel: 'Rideshare', customColor: 0xFF00BCD4);
    final back = Trip.fromJson(t.toJson());
    expect(back.customCategoryLabel, 'Rideshare');
    expect(back.customCategoryColor, 0xFF00BCD4);
    expect(back.categoryLabel, 'Rideshare');
  });

  test('NamedLocation round-trips its auto-classify category', () {
    const loc = NamedLocation(id: 'l1', name: 'Home', lat: 0, lng: 0, category: TripCategory.commute);
    expect(NamedLocation.fromJson(loc.toJson()).category, TripCategory.commute);
  });
}