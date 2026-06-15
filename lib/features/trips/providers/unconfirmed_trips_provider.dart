import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';

/// Trips awaiting swipe classification (auto-detected, not yet confirmed).
final unconfirmedTripsProvider = Provider<List<Trip>>((ref) {
  final all = ref.watch(tripsProvider);
  return all.where((t) => !t.isConfirmed).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
});

final unconfirmedTripCountProvider = Provider<int>((ref) {
  return ref.watch(unconfirmedTripsProvider).length;
});
