import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/report.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/trip_expense.dart';
import 'package:milemaid/core/services/geocode_service.dart';

Trip _makeTrip({
  required TripCategory category,
  bool confirmed = false,
  List<TripExpense> expenses = const [],
}) {
  return Trip(
    id: 't1',
    startTime: DateTime(2026, 6, 15, 10),
    endTime: DateTime(2026, 6, 15, 10, 30),
    distanceMiles: 10,
    durationMinutes: 30,
    routePoints: const [],
    category: category,
    isConfirmed: confirmed,
    expenses: expenses,
  );
}

void main() {
  group('TripExpense JSON', () {
    test('round-trips amount, type, and note', () {
      final e = TripExpense(
        id: 'e1',
        type: ExpenseType.parking,
        amountCents: 750,
        note: 'Garage',
      );
      final back = TripExpense.fromJson(e.toJson());
      expect(back.id, 'e1');
      expect(back.type, ExpenseType.parking);
      expect(back.amountCents, 750);
      expect(back.note, 'Garage');
    });

    test('note defaults to null when absent', () {
      final e = TripExpense(id: 'e2', type: ExpenseType.toll, amountCents: 200);
      final back = TripExpense.fromJson(e.toJson());
      expect(back.note, isNull);
    });
  });

  group('Report expenses', () {
    test('fromTrips sums expenses across all trips in range', () {
      final trips = [
        _makeTrip(
          category: TripCategory.business,
          confirmed: true,
          expenses: [
            const TripExpense(id: 'e1', type: ExpenseType.toll, amountCents: 350),
            const TripExpense(id: 'e2', type: ExpenseType.parking, amountCents: 1000),
          ],
        ),
        _makeTrip(
          category: TripCategory.personal,
          expenses: [
            const TripExpense(id: 'e3', type: ExpenseType.other, amountCents: 500),
          ],
        ),
      ];
      final report = Report.fromTrips(
        trips: trips,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
        rateFor: (_) => 0.70,
      );
      // 350 + 1000 + 500 = 1850 cents -> $18.50
      expect(report.expenseTotal, closeTo(18.50, 0.001));
    });

    test('no expenses yields zero', () {
      final report = Report.fromTrips(
        trips: [_makeTrip(category: TripCategory.business, confirmed: true)],
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
        rateFor: (_) => 0.70,
      );
      expect(report.expenseTotal, 0.0);
    });
  });

  group('GeocodeService', () {
    test('builds a Nominatim reverse URI', () {
      final svc = GeocodeService();
      final uri = svc.buildReverseUri(lat: 37.7749, lng: -122.4194);
      expect(uri.path, '/reverse');
      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.queryParameters['format'], 'jsonv2');
      expect(uri.queryParameters['lat'], '37.7749');
      expect(uri.queryParameters['lon'], '-122.4194');
    });

    test('extracts display_name from JSON', () {
      const svc = GeocodeService();
      expect(svc.addressFromJson({'display_name': '123 Main St, Springfield'}),
          '123 Main St, Springfield');
      expect(svc.addressFromJson({}), isNull);
    });
  });
}