import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:uuid/uuid.dart';

/// Demo trips for UI/testing without driving.
class SampleDataService {
  static final SampleDataService _instance = SampleDataService._internal();
  factory SampleDataService() => _instance;
  SampleDataService._internal();

  final DatabaseService _db = DatabaseService();

  /// Inserts realistic sample trips (past ~10 days). Does not delete existing data.
  Future<int> seedSampleTrips() async {
    final vehicles = _db.getAllVehicles();
    final vehicleId = vehicles.isEmpty ? null : vehicles.first.id;
    final now = DateTime.now();
    final samples = _buildSamples(now, vehicleId);

    for (final trip in samples) {
      await _db.saveTrip(trip);
    }
    return samples.length;
  }

  List<Trip> _buildSamples(DateTime now, String? vehicleId) {
    Trip make({
      required int daysAgo,
      required int hour,
      required int minute,
      required int durationMin,
      required double miles,
      required TripCategory category,
      required String purpose,
      required double startLat,
      required double startLng,
      required double endLat,
      required double endLng,
      bool confirmed = true,
    }) {
      final start = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
      final end = start.add(Duration(minutes: durationMin));
      return Trip(
        id: const Uuid().v4(),
        startTime: start,
        endTime: end,
        distanceMiles: miles,
        durationMinutes: durationMin,
        routePoints: _interpolateRoute(startLat, startLng, endLat, endLng),
        category: category,
        purpose: purpose,
        vehicleId: vehicleId,
        isConfirmed: confirmed,
      );
    }

    // Miami-area coordinates — short commutes and client runs.
    return [
      make(
        daysAgo: 0,
        hour: 9,
        minute: 15,
        durationMin: 28,
        miles: 8.4,
        category: TripCategory.business,
        purpose: 'Client site visit — Brickell',
        startLat: 25.7907,
        startLng: -80.1300,
        endLat: 25.7617,
        endLng: -80.1918,
        confirmed: false,
      ),
      make(
        daysAgo: 1,
        hour: 7,
        minute: 30,
        durationMin: 24,
        miles: 5.8,
        category: TripCategory.business,
        purpose: 'Morning client run',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7907,
        endLng: -80.1300,
        confirmed: false,
      ),
      make(
        daysAgo: 1,
        hour: 14,
        minute: 30,
        durationMin: 18,
        miles: 3.2,
        category: TripCategory.personal,
        purpose: 'Grocery run',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7750,
        endLng: -80.2200,
      ),
      make(
        daysAgo: 2,
        hour: 8,
        minute: 0,
        durationMin: 42,
        miles: 14.6,
        category: TripCategory.business,
        purpose: 'Airport pickup — MIA',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7959,
        endLng: -80.2870,
      ),
      make(
        daysAgo: 3,
        hour: 17,
        minute: 45,
        durationMin: 22,
        miles: 6.1,
        category: TripCategory.commute,
        purpose: 'Office commute',
        startLat: 25.7907,
        startLng: -80.1300,
        endLat: 25.7617,
        endLng: -80.1918,
      ),
      make(
        daysAgo: 4,
        hour: 11,
        minute: 0,
        durationMin: 35,
        miles: 11.8,
        category: TripCategory.business,
        purpose: 'Supplier meeting — Doral',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.8195,
        endLng: -80.3553,
      ),
      make(
        daysAgo: 5,
        hour: 16,
        minute: 20,
        durationMin: 15,
        miles: 4.5,
        category: TripCategory.personal,
        purpose: 'Gym',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7480,
        endLng: -80.2600,
      ),
      make(
        daysAgo: 6,
        hour: 9,
        minute: 30,
        durationMin: 31,
        miles: 9.7,
        category: TripCategory.business,
        purpose: 'Site survey — Coral Gables',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7215,
        endLng: -80.2684,
        confirmed: false,
      ),
      make(
        daysAgo: 8,
        hour: 13,
        minute: 0,
        durationMin: 48,
        miles: 18.2,
        category: TripCategory.business,
        purpose: 'Multi-stop client day',
        startLat: 25.7907,
        startLng: -80.1300,
        endLat: 25.8195,
        endLng: -80.3553,
      ),
      make(
        daysAgo: 10,
        hour: 10,
        minute: 15,
        durationMin: 26,
        miles: 7.3,
        category: TripCategory.other,
        purpose: 'Errands',
        startLat: 25.7617,
        startLng: -80.1918,
        endLat: 25.7750,
        endLng: -80.2200,
      ),
    ];
  }

  List<LatLngPoint> _interpolateRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    int points = 12,
  }) {
    final route = <LatLngPoint>[];
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      route.add(LatLngPoint(
        latitude: startLat + (endLat - startLat) * t,
        longitude: startLng + (endLng - startLng) * t,
      ));
    }
    return route;
  }
}
