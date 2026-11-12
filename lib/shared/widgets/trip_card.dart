import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/shared/widgets/category_chip.dart';

/// The gorgeous trip list item. Shows mini route hint, stats, category.
class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final bool showNeedsReview;

  /// Optional full-width widget shown at the top of the card (route map preview).
  final Widget? header;

  /// Known named places, used to label the From/To line. Pass
  /// [locationsById] of the user's places; the default empty map falls back
  /// to addresses (so widget tests need no Hive).
  final Map<String, NamedLocation> placesById;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.showNeedsReview = false,
    this.header,
    this.placesById = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    const distanceStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: -0.6,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NOTE: keep the if-form (not the Dart 3.8 `?header` null-aware
            // element) because build_runner pins analyzer 6.4.x, which can't
            // parse null-aware elements and fails codegen on this file.
            // ignore: use_null_aware_elements
            if (header != null) header!,
            Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // An unreviewed drive has no category yet: show only the review badge.
                  if (!showNeedsReview)
                    CategoryChip(
                      category: trip.category,
                      customLabel: trip.customCategoryLabel,
                      customColorValue: trip.customCategoryColor,
                    ),
                  if (showNeedsReview) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Needs review',
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
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(trip.formattedDistance, style: distanceStyle),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${trip.formattedDuration}',
                      style: TextStyle(fontSize: 15, color: muted),
                    ),
                  ),
                  const Spacer(),
                  if (trip.vehicleId != null)
                    Icon(Icons.directions_car_filled, size: 18, color: muted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${DateHelpers.formatTime(trip.startTime)} → ${DateHelpers.formatTime(trip.endTime)}',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Endpoint(
                      label: 'From',
                      value: shortPlaceLabel(trip.startLocationId, trip.startAddress, placesById),
                      color: muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Endpoint(
                      label: 'To',
                      value: shortPlaceLabel(trip.endLocationId, trip.endAddress, placesById),
                      color: muted,
                    ),
                  ),
                ],
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
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
