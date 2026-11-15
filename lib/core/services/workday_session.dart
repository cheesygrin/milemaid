import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';

/// A Home → … → Home loop of drives on one calendar day.
class WorkdaySession {
  const WorkdaySession({
    required this.homePlaceId,
    required this.trips,
  });

  final String homePlaceId;

  /// Chronological legs from leaving Home through returning Home.
  final List<Trip> trips;

  List<String> get tripIds => trips.map((t) => t.id).toList();

  List<Trip> get unconfirmed =>
      trips.where((t) => !t.isConfirmed).toList();

  double get totalMiles =>
      trips.fold<double>(0, (sum, t) => sum + t.distanceMiles);

  int get driveCount => trips.length;
}

/// The single Home place, if the user marked one.
NamedLocation? homePlace(List<NamedLocation> places) {
  for (final place in places) {
    if (place.isHome) return place;
  }
  return null;
}

bool tripStartsAt(Trip trip, NamedLocation home) =>
    trip.startLocationId == home.id;

bool tripEndsAt(Trip trip, NamedLocation home) =>
    trip.endLocationId == home.id;

DateTime _calendarDay(DateTime t) => DateTime(t.year, t.month, t.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// When [justEnded] finishes at Home, find the leave-Home → return-Home
/// session that closed with it. Pure: no Hive, no notifications.
///
/// Returns null when there is no Home, the trip did not end at Home, the day
/// never left Home, or the loop has fewer than two drives.
WorkdaySession? detectReturnHomeSession({
  required Trip justEnded,
  required List<Trip> allTrips,
  required NamedLocation home,
}) {
  if (!tripEndsAt(justEnded, home)) return null;

  final dayTrips = allTrips
      .where((t) => _sameDay(t.startTime, justEnded.endTime))
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Ensure the trip that just ended is present (caller may pass it before
  // or after persisting).
  if (!dayTrips.any((t) => t.id == justEnded.id)) {
    dayTrips.add(justEnded);
    dayTrips.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Trip? leave;
  for (final trip in dayTrips) {
    if (trip.startTime.isAfter(justEnded.startTime)) break;
    if (tripStartsAt(trip, home)) leave = trip;
  }
  if (leave == null) return null;

  final session = dayTrips
      .where(
        (t) =>
            !t.startTime.isBefore(leave!.startTime) &&
            !t.startTime.isAfter(justEnded.startTime),
      )
      .toList();

  if (session.length < 2) return null;
  if (session.last.id != justEnded.id) return null;

  return WorkdaySession(homePlaceId: home.id, trips: session);
}

/// True when [day] is Saturday or Sunday in the device's local calendar.
bool isWeekendDay(DateTime day) {
  final local = _calendarDay(day.toLocal());
  return local.weekday == DateTime.saturday || local.weekday == DateTime.sunday;
}
