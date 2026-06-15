import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/shared/widgets/category_chip.dart';

/// The gorgeous trip list item. Shows mini route hint, stats, category.
class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final bool showNeedsReview;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.showNeedsReview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryChip(category: trip.category),
                  if (showNeedsReview) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Review',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateHelpers.formatDate(trip.startTime),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trip.formattedDistance,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.0),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${trip.formattedDuration}',
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  if (trip.vehicleId != null)
                    const Icon(Icons.directions_car_filled, size: 18, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${DateHelpers.formatTime(trip.startTime)} → ${DateHelpers.formatTime(trip.endTime)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (trip.purpose != null && trip.purpose!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  trip.purpose!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 10),
              // Mini route visual (simplified polyline representation)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.7),
                      AppColors.primary.withValues(alpha: 0.5),
                      AppColors.mapRouteFast.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
