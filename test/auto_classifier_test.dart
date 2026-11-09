import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/work_hours.dart';
import 'package:milemaid/core/services/auto_classifier.dart';

void main() {
  final classifier = AutoClassifier();

  // 2026-01-05 is a Monday; 2026-01-10 is a Saturday.
  final monday = DateTime(2026, 1, 5, 10, 30);
  final saturday = DateTime(2026, 1, 10, 10, 30);

  WorkHours workHours(List<int> days) => WorkHours(
        id: 'wh',
        weekdays: days,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
      );

  group('work hours rule', () {
    test('classifies business inside the window on a working day', () {
      final r = classifier.classify(
        startTime: monday,
        startLat: 0,
        startLng: 0,
        workHours: [workHours([1, 2, 3, 4, 5])],
        namedLocations: [],
      );
      expect(r, TripCategory.business);
    });

    test('returns null outside the window hours', () {
      final r = classifier.classify(
        startTime: DateTime(2026, 1, 5, 20, 0), // Monday evening
        startLat: 0,
        startLng: 0,
        workHours: [workHours([1, 2, 3, 4, 5])],
        namedLocations: [],
      );
      expect(r, isNull);
    });

    test('returns null on a non-working day', () {
      final r = classifier.classify(
        startTime: saturday,
        startLat: 0,
        startLng: 0,
        workHours: [workHours([1, 2, 3, 4, 5])],
        namedLocations: [],
      );
      expect(r, isNull);
    });

    test('an overnight window covers late night and early morning', () {
      final overnight = WorkHours(
        id: 'overnight',
        weekdays: [1],
        startMinutes: 22 * 60,
        endMinutes: 4 * 60,
      );
      expect(overnight.covers(DateTime(2026, 1, 5, 23, 0)), isTrue);
      expect(overnight.covers(DateTime(2026, 1, 5, 2, 0)), isTrue);
      expect(overnight.covers(DateTime(2026, 1, 5, 12, 0)), isFalse);
    });
  });

  group('named location rule', () {
    final office = NamedLocation(
      id: 'loc',
      name: 'Office',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 100,
      defaultCategory: TripCategory.business,
      createdAt: DateTime(2026, 1, 1),
    );

    test('classifies business at a saved location', () {
      final r = classifier.classify(
        startTime: monday,
        startLat: 37.7749,
        startLng: -122.4194,
        workHours: [],
        namedLocations: [office],
      );
      expect(r, TripCategory.business);
    });

    test('returns null far from any saved location', () {
      final r = classifier.classify(
        startTime: monday,
        startLat: 37.0,
        startLng: -122.0,
        workHours: [],
        namedLocations: [office],
      );
      expect(r, isNull);
    });
  });

  test('no rules returns null (leave unreviewed)', () {
    final r = classifier.classify(
      startTime: monday,
      startLat: 0,
      startLng: 0,
      workHours: [],
      namedLocations: [],
    );
    expect(r, isNull);
  });
}