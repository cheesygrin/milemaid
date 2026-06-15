import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/core/utils/date_helpers.dart';

/// Bottom sheet style live card shown when a trip is being auto-tracked.
class LiveTripCard extends StatelessWidget {
  final ActiveTrip trip;
  final VoidCallback? onEndPressed;

  const LiveTripCard({super.key, required this.trip, this.onEndPressed});

  @override
  Widget build(BuildContext context) {
    final duration = trip.currentDurationMinutes;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, size: 14, color: AppColors.accent),
                    SizedBox(width: 6),
                    Text('LIVE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateHelpers.formatDuration(duration),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.currentDistanceMiles.toStringAsFixed(1),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('miles', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Current speed', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  Text('${trip.currentSpeedMph.toStringAsFixed(0)} mph',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEndPressed,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('End Trip Manually'),
            ),
          ),
        ],
      ),
    );
  }
}
