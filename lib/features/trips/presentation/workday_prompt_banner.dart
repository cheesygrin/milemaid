import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/workday_session_service.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';

/// Asks whether the Home→Home loop was all business.
class WorkdayPromptBanner extends ConsumerStatefulWidget {
  const WorkdayPromptBanner({super.key});

  @override
  ConsumerState<WorkdayPromptBanner> createState() =>
      _WorkdayPromptBannerState();
}

class _WorkdayPromptBannerState extends ConsumerState<WorkdayPromptBanner> {
  final _service = WorkdaySessionService.instance;

  @override
  void initState() {
    super.initState();
    _service.pending.addListener(_onPending);
    _service.loadPending();
  }

  @override
  void dispose() {
    _service.pending.removeListener(_onPending);
    super.dispose();
  }

  void _onPending() {
    if (mounted) setState(() {});
  }

  Future<void> _markAllBusiness(PendingWorkdayPrompt prompt) async {
    await ref
        .read(tripsProvider.notifier)
        .classifyTrips(prompt.tripIds, TripCategory.business);
    await _service.clearPending();
    ref.read(dashboardProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          prompt.driveCount == 1
              ? 'Marked 1 drive as Business'
              : 'Marked ${prompt.driveCount} drives as Business',
        ),
      ),
    );
  }

  Future<void> _dismiss() async {
    await _service.clearPending();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _service.pending.value;
    if (prompt == null || prompt.tripIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final miles = prompt.totalMiles.toStringAsFixed(1);
    final label = prompt.driveCount == 1
        ? '1 drive ($miles mi) since you left home'
        : '${prompt.driveCount} drives ($miles mi) since you left home';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Back home — were these all business?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _markAllBusiness(prompt),
                      child: const Text('Yes, all business'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _dismiss,
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
