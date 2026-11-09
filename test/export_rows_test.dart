import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/export_rows.dart';
import 'package:milemaid/core/services/export_service.dart';
import 'package:milemaid/shared/widgets/trip_card.dart';

/// All coordinates here are made-up points near lat 40, lng -100 (empty
/// Nebraska), per AGENTS.md. Nothing is a real location.

final _createdAt = DateTime.parse('2026-01-15T08:00:00Z');

NamedLocation _place({
  required String id,
  required String name,
  double lat = 40.0,
  double lng = -100.0,
}) {
  return NamedLocation(
    id: id,
    name: name,
    latitude: lat,
    longitude: lng,
    createdAt: _createdAt,
  );
}

Trip _trip({
  String? startLocationId,
  String? startAddress,
  String? endLocationId,
  String? endAddress,
  String? purpose,
}) {
  return Trip(
    id: 'trip-1',
    startTime: DateTime.parse('2026-01-15T09:00:00Z'),
    endTime: DateTime.parse('2026-01-15T09:30:00Z'),
    distanceMiles: 5.2,
    durationMinutes: 30,
    routePoints: const [
      LatLngPoint(latitude: 40.0, longitude: -100.0),
      LatLngPoint(latitude: 40.001, longitude: -100.0),
    ],
    category: TripCategory.business,
    purpose: purpose,
    startLocationId: startLocationId,
    startAddress: startAddress,
    endLocationId: endLocationId,
    endAddress: endAddress,
  );
}

void main() {
  group('csvHeader', () {
    test('exact column order', () {
      expect(
        csvHeader(),
        [
          'Date',
          'Start Time',
          'End Time',
          'From',
          'To',
          'Distance (mi)',
          'Duration (min)',
          'Category',
          'Purpose',
          'Notes',
          'Vehicle ID',
          'Expenses (USD)',
        ],
      );
    });
  });

  group('csvRow', () {
    test('a trip whose end matches a place shows the place name', () {
      final placesById = {
        'p1': _place(id: 'p1', name: 'Depot'),
        'p2': _place(id: 'p2', name: 'Office', lat: 40.001),
      };
      final t = _trip(
        startLocationId: 'p1',
        endLocationId: 'p2',
        purpose: 'Client visit',
      );

      final row = csvRow(t, placesById);

      expect(row.length, csvHeader().length);
      expect(row[0], '2026-01-15');
      expect(row[1], '09:00');
      expect(row[2], '09:30');
      expect(row[3], 'Depot');
      expect(row[4], 'Office');
      expect(row[5], '5.20');
      expect(row[6], '30');
      expect(row[7], 'Business');
      expect(row[8], 'Client visit');
      expect(row[9], '');
      expect(row[10], '');
    });

    test('an unmatched endpoint falls back to its address', () {
      final t = _trip(startAddress: '100 Main St, Springfield');

      final row = csvRow(t, const {});

      expect(row[3], '100 Main St, Springfield');
      expect(row[4], 'Unknown place');
    });

    test('a trip with neither place nor address shows Unknown place', () {
      final row = csvRow(_trip(), const {});

      expect(row[3], 'Unknown place');
      expect(row[4], 'Unknown place');
    });
  });

  group('CSV escaping (through the service exposed helper)', () {
    test('a purpose containing a comma is quoted', () {
      expect(
        ExportService.csvEscapeField('Meeting, then lunch'),
        '"Meeting, then lunch"',
      );
    });

    test('embedded quotes are doubled', () {
      expect(ExportService.csvEscapeField('Say "hi"'), '"Say ""hi"""');
    });

    test('a plain purpose is untouched', () {
      expect(ExportService.csvEscapeField('Client visit'), 'Client visit');
    });
  });

  group('pdfFit', () {
    test('short text passes through; long text is cut with an ellipsis', () {
      expect(pdfFit('Office', 38), 'Office');
      final fitted = pdfFit('A very long label that keeps going and going', 10);
      expect(fitted.length, 10);
      expect(fitted.endsWith('…'), isTrue);
    });
  });

  group('TripCard From -> To line (widget test)', () {
    const longAddress =
        '12345 Very Long Boulevard North East West, Suite 900, Springfield';

    testWidgets('shows place name for the matched end and address for the other',
        (tester) async {
      final trip = _trip(
        startLocationId: 'p1',
        endAddress: '200 Oak Ave, Shelby',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(
              trip: trip,
              onTap: () {},
              placesById: {'p1': _place(id: 'p1', name: 'Depot')},
            ),
          ),
        ),
      );

      expect(find.text('Depot → 200 Oak Ave, Shelby'), findsOneWidget);
    });

    testWidgets('a long label ellipsizes on one line', (tester) async {
      final trip = _trip(
        startLocationId: 'p1',
        endAddress: longAddress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(
              trip: trip,
              onTap: () {},
              placesById: {'p1': _place(id: 'p1', name: 'Depot')},
            ),
          ),
        ),
      );

      final fromToText = tester.widget<Text>(
        find.text('Depot → $longAddress'),
      );
      expect(fromToText.maxLines, 1);
      expect(fromToText.overflow, TextOverflow.ellipsis);
    });
  });
}
