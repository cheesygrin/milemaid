import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/features/trips/providers/unconfirmed_trips_provider.dart';
import 'package:milemaid/shared/widgets/empty_state.dart';
import 'package:milemaid/shared/widgets/swipeable_trip_card.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key, this.reviewOnly = false});

  final bool reviewOnly;

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  String _search = '';
  TripCategory? _categoryFilter;
  late bool _reviewOnly;

  @override
  void initState() {
    super.initState();
    _reviewOnly = widget.reviewOnly;
  }

  List<Trip> _filteredTrips(List<Trip> all) {
    var result = all;
    if (_reviewOnly) {
      result = result.where((t) => !t.isConfirmed).toList();
    }
    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((t) {
        return (t.purpose?.toLowerCase().contains(q) ?? false) ||
            (t.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(tripsProvider);
    final pendingCount = ref.watch(unconfirmedTripCountProvider);
    final trips = _filteredTrips(allTrips);

    final grouped = <String, List<Trip>>{};
    for (final t in trips) {
      final label = _groupLabel(t.startTime);
      grouped.putIfAbsent(label, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_reviewOnly ? AppStrings.classifyFilter : AppStrings.trips),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: AppStrings.searchTripsHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_reviewOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                AppStrings.classifySwipeHint,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _filterChip(
                  label: AppStrings.classifyFilter,
                  selected: _reviewOnly,
                  count: pendingCount,
                  onTap: () => setState(() {
                    _reviewOnly = !_reviewOnly;
                    if (_reviewOnly) _categoryFilter = null;
                  }),
                ),
                _filterChip(label: 'All', selected: !_reviewOnly && _categoryFilter == null, onTap: () {
                  setState(() {
                    _reviewOnly = false;
                    _categoryFilter = null;
                  });
                }),
                _filterChip(
                  label: 'Business',
                  selected: !_reviewOnly && _categoryFilter == TripCategory.business,
                  onTap: () => setState(() {
                    _reviewOnly = false;
                    _categoryFilter = TripCategory.business;
                  }),
                ),
                _filterChip(
                  label: 'Personal',
                  selected: !_reviewOnly && _categoryFilter == TripCategory.personal,
                  onTap: () => setState(() {
                    _reviewOnly = false;
                    _categoryFilter = TripCategory.personal;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: allTrips.isEmpty
                ? const EmptyState(
                    title: AppStrings.noTripsYet,
                    subtitle: AppStrings.noTripsSubtitle,
                    icon: Icons.directions_car,
                  )
                : trips.isEmpty
                    ? EmptyState(
                        title: _reviewOnly ? 'All caught up' : 'No matching trips',
                        subtitle: _reviewOnly
                            ? 'Every drive has been classified.'
                            : 'Try a different filter or search.',
                        icon: _reviewOnly ? Icons.check_circle_outline : Icons.search_off,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(tripsProvider.notifier).refresh();
                        },
                        child: ListView.builder(
                          itemCount: DateHelpers.groupOrder.length,
                          itemBuilder: (context, i) {
                            final label = DateHelpers.groupOrder[i];
                            final items = grouped[label] ?? [];
                            if (items.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ...items.map(
                                  (trip) => SwipeableTripCard(
                                    trip: trip,
                                    onTap: () => context.push('/trips/${trip.id}'),
                                    onClassified: (cat) => _classify(context, trip.id, cat),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _classify(BuildContext context, String tripId, TripCategory category) async {
    await ref.read(tripsProvider.notifier).classifyTrip(tripId, category);
    ref.read(dashboardProvider.notifier).refresh();
    if (context.mounted) {
      final label = category == TripCategory.business ? AppStrings.business : AppStrings.personal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.classifiedAs(label))),
      );
    }
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.warning,
                ),
              ),
            ],
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }

  String _groupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) return 'This Week';
    return 'Earlier';
  }
}
