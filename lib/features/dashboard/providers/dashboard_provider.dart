import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/report_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

@riverpod
class Dashboard extends _$Dashboard {
  final DatabaseService _db = DatabaseService();
  final ReportService _reports = ReportService();

  @override
  DashboardState build() {
    return _load();
  }

  DashboardState _load() {
    final all = _db.getAllTrips();
    final settings = _db.getSettings();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    double businessMonth = 0;
    double total = 0;
    double personal = 0;
    int tripCount = all.length;

    for (final t in all) {
      total += t.distanceMiles;
      if (t.category == TripCategory.business) {
        if (t.startTime.isAfter(monthStart) && t.startTime.isBefore(monthEnd.add(const Duration(days: 1)))) {
          businessMonth += t.distanceMiles;
        }
      } else if (t.category == TripCategory.personal) {
        personal += t.distanceMiles;
      }
    }

    final last5 = all.take(5).toList();
    final last7 = _reports.last7DaysMiles();

    return DashboardState(
      businessMilesThisMonth: businessMonth,
      totalMiles: total,
      personalMiles: personal,
      tripsLogged: tripCount,
      recentTrips: last5,
      last7DaysMiles: last7,
      currentRate: settings.effectiveRate,
      deductionEstimate: businessMonth * settings.effectiveRate,
    );
  }

  Future<void> refresh() async {
    state = _load();
  }
}

class DashboardState {
  final double businessMilesThisMonth;
  final double totalMiles;
  final double personalMiles;
  final int tripsLogged;
  final List<Trip> recentTrips;
  final List<double> last7DaysMiles;
  final double currentRate;
  final double deductionEstimate;

  const DashboardState({
    required this.businessMilesThisMonth,
    required this.totalMiles,
    required this.personalMiles,
    required this.tripsLogged,
    required this.recentTrips,
    required this.last7DaysMiles,
    required this.currentRate,
    required this.deductionEstimate,
  });
}
