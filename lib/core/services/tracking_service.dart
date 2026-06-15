import 'dart:async';
import 'dart:math' as math;

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/core/utils/distance_calculator.dart';
import 'package:milemaid/core/utils/trip_detector.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The heart of MileMaid: automatic background trip detection & persistence.
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final DatabaseService _db = DatabaseService();
  final LocationService _locationService = LocationService();
  final TripDetector _detector = TripDetector();

  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  // In-memory buffer for the trip currently being recorded
  final List<LatLngPoint> _currentRoute = [];
  DateTime? _currentTripStart;
  double _currentDistance = 0.0;
  LatLng? _lastPoint;

  // For live UI updates (Riverpod will listen)
  final ValueNotifier<ActiveTrip?> activeTripNotifier = ValueNotifier(null);

  FlutterLocalNotificationsPlugin? _notifications;

  bool get isTracking => _isTracking;

  /// Initialize everything. Call once from main / app startup.
  Future<void> initialize() async {
    await _initNotifications();
    await _initForegroundTask();
    // WorkManager disabled for compatibility; foreground service + main isolate stream is primary mechanism.
  }

  Future<void> _initNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications!.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationAction,
    );

    // Create the trip ended channel (Android)
    const channel = AndroidNotificationChannel(
      'milemaid_trips',
      'Trip Notifications',
      description: 'Notifications when a drive ends so you can classify it.',
      importance: Importance.high,
    );
    await _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationAction(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload.startsWith('classify:')) {
      final parts = payload.split(':');
      if (parts.length == 3) {
        final tripId = parts[1];
        final categoryStr = parts[2];
        _quickClassifyTrip(tripId, categoryStr);
      }
    }
  }

  Future<void> _quickClassifyTrip(String tripId, String categoryStr) async {
    final trips = _db.getAllTrips();
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;

    TripCategory cat;
    switch (categoryStr) {
      case 'business':
        cat = TripCategory.business;
        break;
      case 'personal':
        cat = TripCategory.personal;
        break;
      default:
        cat = TripCategory.other;
    }

    final updated = trips[idx].copyWith(category: cat, isConfirmed: true);
    await _db.updateTrip(updated);
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'milemaid_tracking',
        channelName: 'MileMaid Tracking',
        channelDescription: 'MileMaid is monitoring your drives in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // 5s heartbeat
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start passive background tracking.
  /// This is called automatically after onboarding + permissions.
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final hasPermission = await _locationService.requestAlwaysPermission();
    if (!hasPermission) {
      debugPrint('TrackingService: Always permission denied');
      return false;
    }

    // Start the Android foreground service (shows persistent notification)
    await FlutterForegroundTask.startService(
      notificationTitle: 'MileMaid is tracking your drives',
      notificationText: 'Background location active. Your miles are safe.',
      callback: _startTrackingCallback,
    );

    // Start listening to position stream in the main isolate (for live UI + detection)
    await _startPositionStream();

    // (WorkManager disabled in this build for compatibility)

    _isTracking = true;
    debugPrint('TrackingService: STARTED');
    return true;
  }

  /// The actual position listening + detection logic.
  Future<void> _startPositionStream() async {
    await _positionSubscription?.cancel();

    _positionSubscription = _locationService.positionStream.listen(
      (Position position) {
        final speedMph = LocationService.speedMpsToMph(position.speed);
        final now = DateTime.now();
        final latLng = LatLng(position.latitude, position.longitude);

        if (_currentTripStart != null) {
          _currentRoute.add(LatLngPoint.fromLatLng(latLng));
        }

        // Update live distance if we have an active trip
        if (_currentTripStart != null && _lastPoint != null) {
          final delta = DistanceCalculator.distanceBetween(_lastPoint!, latLng);
          _currentDistance += delta;
        }
        _lastPoint = latLng;

        // Feed detector
        final result = _detector.processLocation(
          position: latLng,
          speedMph: speedMph,
          timestamp: now,
        );

        if (result.isStart) {
          _beginNewTrip(now, latLng);
        } else if (result.isEnd) {
          _finalizeCurrentTrip(now, result.distanceMiles ?? _currentDistance);
        }

        // Update live UI state
        if (_currentTripStart != null) {
          activeTripNotifier.value = ActiveTrip(
            startTime: _currentTripStart!,
            currentDistanceMiles: _currentDistance,
            currentSpeedMph: speedMph,
            routePoints: List.from(_currentRoute),
          );
        } else {
          activeTripNotifier.value = null;
        }
      },
      onError: (e) => debugPrint('Position stream error: $e'),
    );
  }

  void _beginNewTrip(DateTime start, LatLng firstPoint) {
    _currentTripStart = start;
    _currentRoute.clear();
    _currentRoute.add(LatLngPoint.fromLatLng(firstPoint));
    _currentDistance = 0.0;
    _lastPoint = firstPoint;

    debugPrint('TRIP START DETECTED at ${DateHelpers.formatTime(start)}');
  }

  Future<void> _finalizeCurrentTrip(DateTime endTime, double distanceMiles) async {
    if (_currentTripStart == null) return;

    final start = _currentTripStart!;
    final durationMinutes =
        endTime.difference(start).inMinutes.clamp(1, 9999);

    // Sample the route (keep every ~30s or ~100m worth of points).
    // For simplicity we keep most points but thin them a bit here.
    final sampled = _thinRoute(_currentRoute, maxPoints: 120);

    final trip = Trip(
      id: const Uuid().v4(),
      startTime: start,
      endTime: endTime,
      distanceMiles: distanceMiles,
      durationMinutes: durationMinutes,
      routePoints: sampled,
      category: TripCategory.business, // default, user will change
      isConfirmed: false,
    );

    await _db.saveTrip(trip);

    // Show the magic notification with quick actions
    await _showTripEndedNotification(trip);

    // Clear state
    _currentTripStart = null;
    _currentRoute.clear();
    _currentDistance = 0;
    _lastPoint = null;
    activeTripNotifier.value = null;

    debugPrint('TRIP ENDED: ${trip.formattedDistance} in ${trip.formattedDuration}');
  }

  List<LatLngPoint> _thinRoute(List<LatLngPoint> points, {int maxPoints = 120}) {
    if (points.length <= maxPoints) return List.from(points);

    final step = (points.length / maxPoints).ceil();
    final thinned = <LatLngPoint>[];
    for (int i = 0; i < points.length; i += step) {
      thinned.add(points[i]);
    }
    if (thinned.last != points.last) thinned.add(points.last);
    return thinned;
  }

  Future<void> _showTripEndedNotification(Trip trip) async {
    final title = AppStrings.tripEndedNotificationTitle; // from strings
    final body = AppStrings.tripEndedNotificationBody
        .replaceFirst('%s', trip.distanceMiles.toStringAsFixed(1));

    final androidDetails = AndroidNotificationDetails(
      'milemaid_trips',
      'Trip Notifications',
      channelDescription: 'Classify your recent drive',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'business',
          'Business',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'personal',
          'Personal',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'edit',
          'Edit',
          showsUserInterface: true,
        ),
      ],
    );

    final iosDetails = const DarwinNotificationDetails(
      categoryIdentifier: 'trip_category',
    );

    await _notifications?.show(
      trip.id.hashCode, // unique per trip
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'classify:${trip.id}:business', // default payload, actions override
    );
  }

  /// Stop tracking (rarely used; app is meant to be always on).
  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await FlutterForegroundTask.stopService();
    // Workmanager disabled
    activeTripNotifier.value = null;
    debugPrint('TrackingService: STOPPED');
  }

  /// Manually start a trip (used by "Add Manual Trip" or testing).
  Future<void> startManualTrip() async {
    final now = DateTime.now();
    final pos = await _locationService.getCurrentPosition();
    final first = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(25.7617, -80.1918); // Miami fallback

    _currentTripStart = now;
    _currentRoute.clear();
    _currentRoute.add(LatLngPoint.fromLatLng(first));
    _currentDistance = 0;
    _lastPoint = first;

    activeTripNotifier.value = ActiveTrip(
      startTime: now,
      currentDistanceMiles: 0,
      currentSpeedMph: 0,
      routePoints: List.from(_currentRoute),
    );
  }

  /// Manually end the current trip (for manual or testing).
  Future<Trip?> endManualTrip() async {
    if (_currentTripStart == null) return null;

    final now = DateTime.now();
    final dist = math.max(_currentDistance, 0.3); // ensure min

    final sampled = _thinRoute(_currentRoute, maxPoints: 80);

    final trip = Trip(
      id: const Uuid().v4(),
      startTime: _currentTripStart!,
      endTime: now,
      distanceMiles: dist,
      durationMinutes: now.difference(_currentTripStart!).inMinutes,
      routePoints: sampled,
      category: TripCategory.business,
      isConfirmed: true,
    );

    await _db.saveTrip(trip);

    _currentTripStart = null;
    _currentRoute.clear();
    _currentDistance = 0;
    activeTripNotifier.value = null;

    return trip;
  }

  /// Called by the foreground task isolate (Android only).
  /// We keep light here; the main isolate does the heavy detection.
  static void _startTrackingCallback() {
    FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
  }
}

/// Android ForegroundTask handler. Runs in a separate isolate.
class TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, Object? starter) async {
    debugPrint('[ForegroundTask] Tracking task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // Heartbeat. The real location stream runs in main isolate.
    // We could do a direct location fetch here as extra safety.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('[ForegroundTask] Tracking task destroyed');
  }

  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('[ForegroundTask] Notification button: $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}

/// Lightweight model for the live in-progress trip card.
class ActiveTrip {
  final DateTime startTime;
  final double currentDistanceMiles;
  final double currentSpeedMph;
  final List<LatLngPoint> routePoints;

  ActiveTrip({
    required this.startTime,
    required this.currentDistanceMiles,
    required this.currentSpeedMph,
    required this.routePoints,
  });

  int get currentDurationMinutes =>
      DateTime.now().difference(startTime).inMinutes;

  List<LatLng> get routeLatLng => routePoints.map((p) => p.toLatLng()).toList();
}
