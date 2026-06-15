import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:milemaid/core/models/trip.dart';

part 'report.freezed.dart';

@freezed
class Report with _$Report {
  const Report._();

  const factory Report({
    required DateTime startDate,
    required DateTime endDate,
    required List<Trip> trips,
    required double totalMiles,
    required double businessMiles,
    required double personalMiles,
    required double commuteMiles,
    required double otherMiles,
    required int totalTrips,
    required double deductionAmount,
    required double rateUsed,
  }) = _Report;

  /// Generate a Report aggregate from a list of trips for the given date range.
  factory Report.fromTrips({
    required List<Trip> trips,
    required DateTime startDate,
    required DateTime endDate,
    required double rate,
  }) {
    double total = 0;
    double biz = 0, pers = 0, comm = 0, oth = 0;
    int count = trips.length;

    for (final t in trips) {
      total += t.distanceMiles;
      switch (t.category) {
        case TripCategory.business:
          biz += t.distanceMiles;
          break;
        case TripCategory.personal:
          pers += t.distanceMiles;
          break;
        case TripCategory.commute:
          comm += t.distanceMiles;
          break;
        case TripCategory.other:
          oth += t.distanceMiles;
          break;
      }
    }

    return Report(
      startDate: startDate,
      endDate: endDate,
      trips: trips,
      totalMiles: total,
      businessMiles: biz,
      personalMiles: pers,
      commuteMiles: comm,
      otherMiles: oth,
      totalTrips: count,
      deductionAmount: biz * rate,
      rateUsed: rate,
    );
  }
}
