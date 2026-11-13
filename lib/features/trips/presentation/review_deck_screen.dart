import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/features/trips/providers/unconfirmed_trips_provider.dart';
import 'package:milemaid/shared/widgets/empty_state.dart';
import 'package:milemaid/shared/widgets/fade_slide_in.dart';
import 'package:milemaid/shared/widgets/route_preview.dart';
import 'package:milemaid/shared/widgets/swipeable_trip_card.dart';
import 'package:milemaid/shared/widgets/trip_card.dart';

Map<String, NamedLocation> get _placesById =>
    locationsById(DatabaseService().getAllLocations());

/// The unreviewed drives, in a column. Swipe the top card and the rest shift up.
class ReviewDeckScreen extends ConsumerWidget {
  const ReviewDeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(unconfirmedTripsProvider);
    final left = pending.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(left == 0 ? 'Review' : '$left left'),
      ),
      body: left == 0
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All caught up',
              subtitle: 'New drives will show up here to classify.',
            )
          : FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        AppStrings.classifySwipeHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Deck(
                        trips: pending,
                        onClassified: (trip, category) =>
                            _onClassified(context, ref, trip, category),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _onClassified(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    TripCategory category,
  ) async {
    await ref.read(tripsProvider.notifier).classifyTrip(trip.id, category);
    ref.read(dashboardProvider.notifier).refresh();
    if (!context.mounted) return;
    final label = category == TripCategory.business ? AppStrings.business : AppStrings.personal;
    final color = category == TripCategory.business ? AppColors.accent : AppColors.personal;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(AppStrings.classifiedAs(label))),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () => _undo(ref, trip.id, trip.category),
          ),
        ),
      );
  }

  Future<void> _undo(WidgetRef ref, String tripId, TripCategory previous) async {
    await ref.read(tripsProvider.notifier).unclassifyTrip(tripId, previous);
    ref.read(dashboardProvider.notifier).refresh();
  }
}

class _Deck extends StatelessWidget {
  const _Deck({required this.trips, required this.onClassified});

  final List<Trip> trips;
  final void Function(Trip trip, TripCategory category) onClassified;

  @override
  Widget build(BuildContext context) {
    final places = _placesById;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        if (index == 0) {
          return SwipeableTripCard(
            key: ValueKey(trip.id),
            trip: trip,
            showMap: true,
            collapseOnExit: true,
            placesById: places,
            onTap: () => context.push('/trips/${trip.id}'),
            onClassified: (category) => onClassified(trip, category),
          );
        }
        return TripCard(
          key: ValueKey(trip.id),
          trip: trip,
          placesById: places,
          showNeedsReview: true,
          header: RoutePreview(
            cacheKey: '${trip.id}:${trip.routePoints.length}',
            points: trip.routeLatLng,
          ),
          onTap: () => context.push('/trips/${trip.id}'),
        );
      },
    );
  }
}
