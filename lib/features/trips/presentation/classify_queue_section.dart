import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/features/trips/providers/unconfirmed_trips_provider.dart';

/// One-line entry to the review deck. The cards themselves live on `/review`.
class ClassifyQueueSection extends ConsumerWidget {
  const ClassifyQueueSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(unconfirmedTripsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final count = pending.length;
    final label = count == 1 ? '1 drive to review' : '$count drives to review';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/review'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.swipe, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
