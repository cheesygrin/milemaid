import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/services/tracking_health.dart';

void main() {
  test('weekday hours count fully across two workdays', () {
    final from = DateTime(2026, 3, 10, 9); // Tuesday
    final to = DateTime(2026, 3, 12, 9); // Thursday
    expect(countedHoursBetween(from, to), 48);
    expect(
      isTrackingStale(lastActivity: from, now: to),
      isTrue,
    );
  });

  test('weekend hours are skipped by default', () {
    // Friday 5pm → Monday 9am is only a few weekday hours.
    final from = DateTime(2026, 3, 13, 17); // Friday
    final to = DateTime(2026, 3, 16, 9); // Monday
    final hours = countedHoursBetween(from, to);
    expect(hours, lessThan(48));
    expect(isTrackingStale(lastActivity: from, now: to), isFalse);

    // Same span with weekends counted is over the threshold.
    expect(
      countedHoursBetween(from, to, countWeekends: true),
      greaterThan(48),
    );
  });

  test('a quiet Saturday does not age the clock', () {
    final from = DateTime(2026, 3, 14, 8); // Saturday
    final to = DateTime(2026, 3, 15, 8); // Sunday
    expect(countedHoursBetween(from, to), 0);
  });
}
