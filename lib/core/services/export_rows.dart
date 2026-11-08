import 'package:intl/intl.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/place_matcher.dart';

/// Pure, testable row builders for the CSV and PDF exports. No Hive, no
/// platform channels: callers pass in everything (a places map comes from
/// locationsById of DatabaseService.getAllLocations()).

/// CSV column order shared by [csvHeader] and [csvRow].
List<String> csvHeader() => const [
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
    ];

/// One CSV row for [t], in [csvHeader] order. Endpoints are labelled with
/// [placeLabel] (place name, else address, else "Unknown place").
List<String> csvRow(Trip t, Map<String, NamedLocation> placesById) => [
      DateFormat('yyyy-MM-dd').format(t.startTime),
      DateFormat('HH:mm').format(t.startTime),
      DateFormat('HH:mm').format(t.endTime),
      placeLabel(t.startLocationId, t.startAddress, placesById),
      placeLabel(t.endLocationId, t.endAddress, placesById),
      t.distanceMiles.toStringAsFixed(2),
      '${t.durationMinutes}',
      t.category.displayName,
      t.purpose ?? '',
      t.notes ?? '',
      t.vehicleId ?? '',
    ];

/// Quotes a CSV field when it contains a comma or double quote.
String csvEscape(String v) =>
    v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;

/// Truncates [text] to [maxChars] characters for a fixed PDF table column,
/// ending with an ellipsis when anything was cut. Pure so tests can pin it.
String pdfFit(String text, int maxChars) {
  if (text.length <= maxChars) return text;
  return '${text.substring(0, (maxChars - 1).clamp(0, text.length))}…';
}
