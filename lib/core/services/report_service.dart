import 'package:milemaid/core/models/report.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';

/// Builds Report aggregates and provides helpers for UI + PDF.
class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final DatabaseService _db = DatabaseService();

  /// Generate a report for a custom date range.
  Report generateReport(DateTime start, DateTime end) {
    final trips = _db.getTripsInRange(start, end);
    final settings = _db.getSettings();
    return Report.fromTrips(
      trips: trips,
      startDate: start,
      endDate: end,
      rate: settings.effectiveRate,
    );
  }

  /// Convenience: current month report.
  Report currentMonthReport() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59);
    return generateReport(start, end);
  }

  /// Last 7 full days for dashboard sparkline.
  List<double> last7DaysMiles() {
    final now = DateTime.now();
    final List<double> miles = List.filled(7, 0.0);

    final all = _db.getAllTrips();
    for (final trip in all) {
      final dayDiff = now.difference(trip.startTime).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        miles[6 - dayDiff] += trip.distanceMiles;
      }
    }
    return miles;
  }

  /// Category breakdown for pie chart (values only).
  Map<TripCategory, double> categoryBreakdown(Report report) {
    return {
      TripCategory.business: report.businessMiles,
      TripCategory.personal: report.personalMiles,
      TripCategory.commute: report.commuteMiles,
      TripCategory.other: report.otherMiles,
    };
  }
}
