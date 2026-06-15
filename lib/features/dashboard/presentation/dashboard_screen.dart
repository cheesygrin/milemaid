import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/constants/design_tokens.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/shared/widgets/live_trip_card.dart';
import 'package:milemaid/shared/widgets/stat_card.dart';
import 'package:milemaid/features/trips/presentation/classify_queue_section.dart';
import 'package:milemaid/shared/widgets/trip_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: AppStrings.reports,
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dashboardProvider.notifier).refresh();
          ref.read(tripsProvider.notifier).refresh(); // from trips
        },
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                // Hero business miles - premium gradient + count-up
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryAccent,
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
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${AppStrings.deductionEstimate}: \$${_format(dash.deductionEstimate)} at ${dash.currentRate.toStringAsFixed(2)}/mi',
                            style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Three stat cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: AppStrings.totalMiles,
                          value: dash.totalMiles.toStringAsFixed(1),
                          subtitle: 'all time',
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: AppStrings.personalMiles,
                          value: dash.personalMiles.toStringAsFixed(1),
                          accentColor: AppColors.personal,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: AppStrings.tripsLogged,
                          value: '${dash.tripsLogged}',
                          icon: Icons.list_alt,
                        ),
                      ),
                    ],
                  ),
                ),

                const ClassifyQueueSection(),

                // 7-day chart
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Last 7 Days', style: Theme.of(context).textTheme.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const days = ['7d', '6d', '5d', '4d', '3d', '2d', 'Today'];
                                final i = value.toInt().clamp(0, 6);
                                return Text(days[i], style: const TextStyle(fontSize: 10));
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

                // Recent activity
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No trips logged yet. Start driving!', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...dash.recentTrips.map((t) => TripCard(
                        trip: t,
                        onTap: () => context.push('/trips/${t.id}'),
                      )),

                const SizedBox(height: 40),
              ],
            ),

            // Live floating / bottom card
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-manual'),
        icon: const Icon(Icons.add),
        label: const Text('Add Manual Trip'),
      ),
    );
  }

  String _format(double v) => v.toStringAsFixed(2);
}

