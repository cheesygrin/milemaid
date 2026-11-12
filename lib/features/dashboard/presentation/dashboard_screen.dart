import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/constants/design_tokens.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/shared/widgets/empty_state.dart';
import 'package:milemaid/shared/widgets/fade_slide_in.dart';
import 'package:milemaid/shared/widgets/live_trip_card.dart';
import 'package:milemaid/shared/widgets/stat_card.dart';
import 'package:milemaid/features/trips/presentation/classify_queue_section.dart';
import 'package:milemaid/shared/widgets/trip_card.dart';

/// Current named places keyed by id, for the From/To labels on trip cards.
Map<String, NamedLocation> get _placesById =>
    locationsById(DatabaseService().getAllLocations());

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TrackingService _tracking = TrackingService();
  late final AnimationController _milesController;
  late final Animation<double> _milesAnimation;

  @override
  void initState() {
    super.initState();
    _tracking.activeTripNotifier.addListener(_onActiveTripChanged);

    _milesController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _milesAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _milesController, curve: Curves.easeOutCubic),
    );
    _milesController.forward();
  }

  @override
  void dispose() {
    _tracking.activeTripNotifier.removeListener(_onActiveTripChanged);
    _milesController.dispose();
    super.dispose();
  }

  void _onActiveTripChanged() {
    setState(() {}); // force rebuild for live card
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(dashboardProvider);
    final active = _tracking.activeTripNotifier.value;

    final scheme = Theme.of(context).colorScheme;
    final weekday = DateFormat('EEEEE');
    final today = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dashboardProvider.notifier).refresh();
          ref.read(tripsProvider.notifier).refresh();
        },
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 112,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add manual trip',
                      onPressed: () => context.push('/add-manual'),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
                    expandedTitleScale: 1.35,
                    title: Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    const FadeSlideIn(index: 0, child: ClassifyQueueSection()),
                    FadeSlideIn(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.l),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.l),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.businessMilesThisMonth,
                                  style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AnimatedBuilder(
                                  animation: _milesAnimation,
                                  builder: (context, _) {
                                    final animatedValue = dash.businessMilesThisMonth * _milesAnimation.value;
                                    return Text(
                                      '${animatedValue.toStringAsFixed(1)} mi',
                                      style: AppTypography.displayMedium.copyWith(
                                        color: Colors.white,
                                        height: 1.0,
                                        letterSpacing: -1.4,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${AppStrings.deductionEstimate}: \$${_format(dash.deductionEstimate)} at ${IrsRates.format(dash.currentRate)}/mi',
                                  style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: AppStrings.totalMiles,
                                value: dash.totalMiles.toStringAsFixed(1),
                                subtitle: 'mi, all time',
                                onTap: () => context.go('/trips'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: AppStrings.personalMiles,
                                value: dash.personalMiles.toStringAsFixed(1),
                                subtitle: 'mi',
                                accentColor: AppColors.personal,
                                onTap: () => context.go('/trips?category=personal'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: AppStrings.tripsLogged,
                                value: '${dash.tripsLogged}',
                                subtitle: 'drives',
                                icon: Icons.route_outlined,
                                emphasizeValue: false,
                                onTap: () => context.go('/trips'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text('Last 7 Days', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              checkToShowHorizontalLine: (value) => value == 0,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: scheme.outlineVariant.withValues(alpha: 0.6),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final i = value.toInt().clamp(0, 6);
                                    final day = today.subtract(Duration(days: 6 - i));
                                    return Text(
                                      weekday.format(day),
                                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: dash.last7DaysMiles
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                                    .toList(),
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => context.go('/trips'),
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                    ),
                    if (dash.recentTrips.isEmpty)
                      const EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: 'No trips yet',
                        subtitle: 'Drives you take will show up here.',
                      )
                    else
                      ...dash.recentTrips.map((t) => TripCard(
                            trip: t,
                            onTap: () => context.push('/trips/${t.id}'),
                            placesById: _placesById,
                          )),
                    const SizedBox(height: 24),
                  ]),
                ),
              ],
            ),
            if (active != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LiveTripCard(
                  trip: active,
                  onEndPressed: () async {
                    await _tracking.endManualTrip();
                    ref.read(dashboardProvider.notifier).refresh();
                    ref.read(tripsProvider.notifier).refresh();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _format(double v) => v.toStringAsFixed(2);
}

