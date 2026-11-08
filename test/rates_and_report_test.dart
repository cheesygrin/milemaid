import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/models/report.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/user_settings.dart';

/// Pure Dart tests (no Hive, no plugins) for the IRS rate table, settings
/// migration and the report aggregate — covering the Nov 8 rate fixes.
void main() {
  group('IrsRates.rateFor', () {
    test('2025-06-15 uses the 2025 rate of 0.70', () {
      expect(IrsRates.rateFor(DateTime(2025, 6, 15)), 0.70);
    });

    test('2026-01-01 and 2026-06-30 use the first-half 2026 rate of 0.725', () {
      expect(IrsRates.rateFor(DateTime(2026, 1, 1)), 0.725);
      expect(IrsRates.rateFor(DateTime(2026, 6, 30)), 0.725);
    });

    test('2026-07-01 and 2026-12-31 use the mid-2026 rate of 0.76', () {
      expect(IrsRates.rateFor(DateTime(2026, 7, 1)), 0.76);
      expect(IrsRates.rateFor(DateTime(2026, 12, 31)), 0.76);
    });
  });

  group('IrsRates.format', () {
    test('renders three decimals only when needed', () {
      expect(IrsRates.format(0.725), r'$0.725');
      expect(IrsRates.format(0.76), r'$0.76');
      expect(IrsRates.format(0.70), r'$0.70');
    });
  });

  group('UserSettings.fromJson migration', () {
    test('stored 0.72 (old hard-coded default) follows the IRS rate', () {
      final settings = UserSettings.fromJson(const {
        'mileageRate': 0.72,
      });
      expect(settings.usesIrsRate, isTrue);
    });

    test('missing mileageRate key follows the IRS rate', () {
      final settings = UserSettings.fromJson(const {});
      expect(settings.usesIrsRate, isTrue);
    });

    test('a real stored custom rate like 0.65 is kept', () {
      final settings = UserSettings.fromJson(const {
        'mileageRate': 0.65,
      });
      expect(settings.usesIrsRate, isFalse);
      expect(settings.mileageRate, 0.65);
    });

    test('rateFor(2026-08-01) with the IRS rate is 0.76', () {
      final settings = UserSettings.fromJson(const {
        'mileageRate': 0.72,
      });
      expect(settings.rateFor(DateTime(2026, 8, 1)), 0.76);
    });
  });

  group('Report.fromTrips', () {
    Trip trip({
      required DateTime startTime,
      required double distanceMiles,
      required TripCategory category,
      bool isConfirmed = false,
    }) {
      final endTime = startTime.add(const Duration(minutes: 20));
      return Trip(
        id: 'trip-${startTime.toIso8601String()}',
        startTime: startTime,
        endTime: endTime,
        distanceMiles: distanceMiles,
        durationMinutes: 20,
        routePoints: const [],
        category: category,
        isConfirmed: isConfirmed,
      );
    }

    double fakeRate(DateTime date) => IrsRates.rateFor(date);

    test('confirmed business trips in June and July use per-date rates', () {
      final report = Report.fromTrips(
        trips: [
          trip(
            startTime: DateTime(2026, 6, 15, 9),
            distanceMiles: 10,
            category: TripCategory.business,
            isConfirmed: true,
          ),
          trip(
            startTime: DateTime(2026, 7, 15, 9),
            distanceMiles: 10,
            category: TripCategory.business,
            isConfirmed: true,
          ),
        ],
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 31),
        rateFor: fakeRate,
      );

      expect(report.businessMiles, 20);
      // 10 mi * 0.725 + 10 mi * 0.76 = 14.85
      expect(report.deductionAmount, closeTo(14.85, 0.001));
    });

    test('an unconfirmed business trip is not counted as business', () {
      final report = Report.fromTrips(
        trips: [
          trip(
            startTime: DateTime(2026, 7, 15, 9),
            distanceMiles: 10,
            category: TripCategory.business,
            isConfirmed: false,
          ),
        ],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        rateFor: fakeRate,
      );

      expect(report.businessMiles, 0);
      expect(report.otherMiles, 10);
      expect(report.deductionAmount, 0);
    });

    test('personal and other trips never add to the deduction', () {
      final report = Report.fromTrips(
        trips: [
          trip(
            startTime: DateTime(2026, 7, 1, 9),
            distanceMiles: 5,
            category: TripCategory.personal,
            isConfirmed: true,
          ),
          trip(
            startTime: DateTime(2026, 7, 2, 9),
            distanceMiles: 3,
            category: TripCategory.other,
            isConfirmed: true,
          ),
        ],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        rateFor: fakeRate,
      );

      expect(report.businessMiles, 0);
      expect(report.personalMiles, 5);
      expect(report.otherMiles, 3);
      expect(report.deductionAmount, 0);
    });
  });
}
