import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/backup_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/core/services/trip_enricher.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/features/dashboard/presentation/dashboard_screen.dart';
import 'package:milemaid/features/monetization/presentation/paywall_screen.dart';
import 'package:milemaid/features/onboarding/presentation/onboarding_screen.dart';
import 'package:milemaid/features/reports/presentation/pdf_preview_screen.dart';
import 'package:milemaid/features/reports/presentation/reports_screen.dart';
import 'package:milemaid/features/settings/presentation/auto_classify_screen.dart';
import 'package:milemaid/features/settings/presentation/custom_categories_screen.dart';
import 'package:milemaid/features/settings/presentation/places_screen.dart';
import 'package:milemaid/features/settings/presentation/settings_screen.dart';
import 'package:milemaid/features/settings/presentation/vehicles_screen.dart';
import 'package:milemaid/features/settings/presentation/purposes_screen.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:milemaid/features/trips/presentation/add_manual_trip_screen.dart';
import 'package:milemaid/features/trips/presentation/trip_detail_screen.dart';
import 'package:milemaid/features/trips/presentation/trips_list_screen.dart';
import 'package:milemaid/shared/theme/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _RootDecider(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/trips',
      builder: (context, state) {
        final q = state.uri.queryParameters['category'];
        TripCategory? cat;
        for (final c in TripCategory.values) {
          if (c.name == q) cat = c;
        }
        return TripsListScreen(
          reviewOnly: state.uri.queryParameters['review'] == '1',
          initialCategory: cat,
        );
      },
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => TripDetailScreen(tripId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/add-manual',
      builder: (context, state) => const AddManualTripScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
      routes: [
        GoRoute(
          path: 'pdf-preview',
          builder: (context, state) => const PdfPreviewScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'vehicles',
          builder: (context, state) => const VehiclesScreen(),
        ),
        GoRoute(
          path: 'auto-classify',
          builder: (context, state) => const AutoClassifyScreen(),
        ),
        GoRoute(
          path: 'custom-categories',
          builder: (context, state) => const CustomCategoriesScreen(),
        ),
        GoRoute(
          path: 'places',
          builder: (context, state) => const PlacesScreen(),
        ),
        GoRoute(
          path: 'purposes',
          builder: (context, state) => const PurposesScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/upgrade',
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);

/// Decides whether to show onboarding or the main dashboard.
class _RootDecider extends ConsumerWidget {
  const _RootDecider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = DatabaseService().getSettings();
    if (!settings.hasCompletedOnboarding) {
      // Use post frame to avoid build during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/onboarding');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const DashboardScreen();
  }
}

class MileMaidApp extends ConsumerWidget {
  const MileMaidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = _parseThemeMode(settings.themeMode);

    return MaterialApp.router(
      title: 'MileMaid',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _AppBootstrap(child: child ?? const SizedBox()),
    );
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// Keeps trip UI in sync with Hive and resumes background tracking after relaunch.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    DatabaseService().onTripsChanged = () {
      ref.read(tripsProvider.notifier).refresh();
      ref.read(dashboardProvider.notifier).refresh();
    };

    TrackingService().pendingReviewTripId.addListener(_openPendingTrip);
    TrackingService().pendingClassifyTripId.addListener(_openPendingTrip);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeTrackingIfNeeded();
      // The app may have been launched by tapping a drive notification.
      _openPendingTrip();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TrackingService().pendingReviewTripId.removeListener(_openPendingTrip);
    TrackingService().pendingClassifyTripId.removeListener(_openPendingTrip);
    DatabaseService().onTripsChanged = null;
    super.dispose();
  }

  /// Handles a tapped drive notification: the notification itself goes to the
  /// home screen, where the newest drive waits on top as a swipe card; its Edit
  /// button opens the trip's details.
  void _openPendingTrip() {
    final tracking = TrackingService();
    final classifyId = tracking.pendingClassifyTripId.value;
    final reviewId = tracking.pendingReviewTripId.value;
    if (classifyId == null && reviewId == null) return;
    tracking.pendingClassifyTripId.value = null;
    tracking.pendingReviewTripId.value = null;
    if (!DatabaseService().getSettings().hasCompletedOnboarding) return;
    if (reviewId != null) {
      _router.push('/trips/$reviewId');
    } else {
      _router.go('/');
    }
  }

  /// True while a [TripEnricher.backfill] pass is running, so resume events
  /// never stack a second one on top.
  bool _backfillRunning = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeTrackingIfNeeded();
      // Rate-limited inside the service; failures recorded, never thrown.
      unawaited(BackupService.instance.autoBackup(afterNewTrip: false));
      // Close a drive that ended while the app wasn't getting GPS fixes.
      TrackingService().checkForEndedTrip();
      // Fill in missing addresses in the background (one pass at a time).
      // Errors are swallowed here: a failed geocoder pass must never crash
      // the app on resume; it just tries again next launch.
      if (!_backfillRunning) {
        _backfillRunning = true;
        TripEnricher.instance
            .backfill()
            .catchError((Object e) {
              debugPrint('TripEnricher.backfill failed: $e');
              return 0;
            })
            .whenComplete(() => _backfillRunning = false);
      }
      ref.read(dashboardProvider.notifier).refresh();
      ref.read(tripsProvider.notifier).refresh();
    }
  }

  Future<void> _resumeTrackingIfNeeded() async {
    final settings = DatabaseService().getSettings();
    if (!settings.hasCompletedOnboarding) return;
    if (TrackingService().isTracking) return;
    await TrackingService().startTracking();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
