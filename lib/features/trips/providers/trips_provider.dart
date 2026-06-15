import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trips_provider.g.dart';

@riverpod
class Trips extends _$Trips {
  final DatabaseService _db = DatabaseService();

  @override
  List<Trip> build() {
    // Load initial
    return _db.getAllTrips();
  }

  Future<void> refresh() async {
    state = _db.getAllTrips();
  }

  Future<void> addOrUpdateTrip(Trip trip) async {
    await _db.saveTrip(trip);
    state = _db.getAllTrips();
  }

  Future<void> deleteTrip(String id) async {
    await _db.deleteTrip(id);
    state = _db.getAllTrips();
  }

  /// MileIQ-style classify: set category and mark confirmed.
  Future<void> classifyTrip(String id, TripCategory category) async {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    await addOrUpdateTrip(
      state[idx].copyWith(category: category, isConfirmed: true),
    );
  }

  Future<Trip?> duplicateAsReturn(String originalId) async {
    final original = state.firstWhere((t) => t.id == originalId, orElse: () => throw Exception('Not found'));
    final now = DateTime.now();
    final returnTrip = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: now.subtract(const Duration(minutes: 5)),
      endTime: now,
      // reverse route would be nice but skip for v1
      purpose: original.purpose != null ? 'Return: ${original.purpose}' : 'Return trip',
      isConfirmed: true,
    );
    await _db.saveTrip(returnTrip);
    state = _db.getAllTrips();
    return returnTrip;
  }
}

@riverpod
List<Trip> filteredTrips(FilteredTripsRef ref, {TripCategory? category, String query = ''}) {
  final all = ref.watch(tripsProvider);
  var result = all;

  if (category != null) {
    result = result.where((t) => t.category == category).toList();
  }
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    result = result.where((t) {
      return (t.purpose?.toLowerCase().contains(q) ?? false) ||
             (t.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
  return result;
}
