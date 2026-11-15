/// How many hours between [from] and [to] count toward a tracking-stale alert.
///
/// When [countWeekends] is false (the default), Saturday and Sunday hours are
/// skipped so a quiet weekend does not trip the red alert.
double countedHoursBetween(
  DateTime from,
  DateTime to, {
  bool countWeekends = false,
}) {
  if (!to.isAfter(from)) return 0;

  var hours = 0.0;
  var cursor = from.toLocal();
  final end = to.toLocal();

  while (cursor.isBefore(end)) {
    final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
    final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
    final weekend =
        cursor.weekday == DateTime.saturday || cursor.weekday == DateTime.sunday;
    if (countWeekends || !weekend) {
      hours += segmentEnd.difference(cursor).inMilliseconds / 3600000.0;
    }
    cursor = segmentEnd;
  }
  return hours;
}

/// True when [lastActivity] is at least [thresholdHours] counted hours ago.
bool isTrackingStale({
  required DateTime lastActivity,
  required DateTime now,
  double thresholdHours = 48,
  bool countWeekends = false,
}) {
  return countedHoursBetween(
        lastActivity,
        now,
        countWeekends: countWeekends,
      ) >=
      thresholdHours;
}
