import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/features/trips/providers/unconfirmed_trips_provider.dart';
import 'package:milemaid/shared/widgets/swipeable_trip_card.dart';

/// Review queue for drives that need classification (shown on dashboard).
class ClassifyQueueSection extends ConsumerWidget {
  const ClassifyQueueSection({super.key, this.maxVisible = 5});

  final int maxVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(unconfirmedTripsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    final visible = pending.take(maxVisible).toList();
    final remaining = pending.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.classifyDrives,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.classifySwipeHint,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pending.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...visible.map((trip) => SwipeableTripCard(
              trip: trip,
              onTap: () => context.push('/trips/${trip.id}'),
              onClassified: (cat) => _onClassified(context, ref, trip.id, cat),
            )),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () => context.go('/trips?review=1'),
              child: Text(AppStrings.classifySeeMore(remaining)),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _onClassified(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    TripCategory category,
  ) async {
    await ref.read(tripsProvider.notifier).classifyTrip(tripId, category);
    ref.read(dashboardProvider.notifier).refresh();
    if (context.mounted) {
      final label = category == TripCategory.business ? AppStrings.business : AppStrings.personal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.classifiedAs(label)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
