import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/auto_classifier.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/core/services/trip_enricher.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/core/utils/distance_calculator.dart';
import 'package:milemaid/core/utils/trip_detector.dart';
import 'package:uuid/uuid.dart';

/// The heart of MileMaid: automatic background trip detection & persistence.
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  /// Notification category and action ids for the "Drive detected" prompt.
  static const String tripCategoryId = 'trip_category';
  static const String actionBusiness = 'business';
  static const String actionPersonal = 'personal';
  static const String actionEdit = 'edit';
  static const String _payloadPrefix = 'trip:';

  /// How often to check whether a drive ended while the phone sat still.
  static const Duration _endCheckInterval = Duration(seconds: 30);

  final DatabaseService _db = DatabaseService();
  final LocationService _locationService = LocationService();
  final TripDetector _detector = TripDetector();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _endCheckTimer;
  bool _isTracking = false;
  bool _starting = false;

  // A trip the user started by hand ("Add Manual Trip" → live). Tracked
  // separately from automatic detection.
  DateTime? _manualStart;
  final List<LatLngPoint> _manualRoute = [];
  double _manualDistance = 0.0;

  LatLng? _lastPoint;
  double _lastSpeedMph = 0;

  // For live UI updates (Riverpod will listen)
  final ValueNotifier<ActiveTrip?> activeTripNotifier = ValueNotifier(null);

  /// Set when the user taps a drive notification: the app shows the home
  /// screen, where the drive waits on top as a swipe card.
  final ValueNotifier<String?> pendingClassifyTripId = ValueNotifier(null);

  /// Set when the user taps the notification's Edit button: open the trip.
  final ValueNotifier<String?> pendingReviewTripId = ValueNotifier(null);

  FlutterLocalNotificationsPlugin? _notifications;

  bool get isTracking => _isTracking;

  /// Initialize everything. Call once from main / app startup.
  Future<void> initialize() async {
    await _initNotifications();
    await _initForegroundTask();
  }

  Future<void> _initNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS only shows action buttons for categories registered up front.
    // Foreground actions open the app, so the choice is saved by this isolate
    // (Hive is not safe to open from a second, background isolate).
    const foreground = <DarwinNotificationActionOption>{
      DarwinNotificationActionOption.foreground,
    };
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          tripCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(actionBusiness, 'Business',
                options: foreground),
            DarwinNotificationAction.plain(actionPersonal, 'Personal',
                options: foreground),
            DarwinNotificationAction.plain(actionEdit, 'Edit',
                options: foreground),
          ],
        ),
      ],
    );

    await _notifications!.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
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

    // The app was launched by tapping a drive notification (or one of its buttons).
    final launch = await _notifications!.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      await _handleNotificationResponse(response);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    unawaited(_handleNotificationResponse(response));
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final tripId = _tripIdFromPayload(response.payload);
    if (tripId == null) return;

    switch (response.actionId) {
      case actionBusiness:
        await _classifyTrip(tripId, TripCategory.business);
        break;
      case actionPersonal:
        await _classifyTrip(tripId, TripCategory.personal);
        break;
      case actionEdit:
        pendingReviewTripId.value = tripId;
        break;
      default:
        // The notification itself: open the swipe card, without classifying.
        pendingClassifyTripId.value = tripId;
    }
  }

  static String? _tripIdFromPayload(String? payload) {
    if (payload == null) return null;
    if (payload.startsWith(_payloadPrefix)) {
      final id = payload.substring(_payloadPrefix.length);
      return id.isEmpty ? null : id;
    }
    // Notifications posted by older builds carried "classify:<id>:business".
    // That category was a hard-coded default, never the user's choice: ignore it.
    if (payload.startsWith('classify:')) {
      final parts = payload.split(':');
      return parts.length >= 2 && parts[1].isNotEmpty ? parts[1] : null;
    }
    return null;
  }

  Future<void> _classifyTrip(String tripId, TripCategory category) async {
    final trips = _db.getAllTrips();
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;

    final updated = trips[idx].copyWith(category: category, isConfirmed: true);
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

  /// Start passive background tracking, asking for location permission if needed.
  /// This is called after onboarding + permissions.
  Future<bool> startTracking() async {
    if (_isTracking || _starting) return _isTracking;
    _starting = true;
    try {
      final hasPermission = await _locationService.requestAlwaysPermission();
      if (!hasPermission) {
        debugPrint('TrackingService: Always permission denied');
        return false;
      }
      await _startEngine();
      return true;
    } finally {
      _starting = false;
    }
  }

  /// Start tracking without showing any permission prompt. Used at launch,
  /// including when iOS relaunches the app in the background after a
  /// significant location change (no UI exists then, so nothing may prompt).
  Future<bool> resumeIfAuthorized() async {
    if (_isTracking || _starting) return _isTracking;
    if (!_db.getSettings().hasCompletedOnboarding) return false;

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return false;
    }

    _starting = true;
    try {
      await _startEngine();
      return true;
    } finally {
      _starting = false;
    }
  }

  Future<void> _startEngine() async {
    // Start the Android foreground service (shows persistent notification).
    // A failure here must not stop location tracking itself.
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'MileMaid is tracking your drives',
        notificationText: 'Background location active. Your miles are safe.',
        callback: _startTrackingCallback,
      );
    } catch (e) {
      debugPrint('TrackingService: foreground service not started: $e');
    }

    // Position stream in the main isolate (live UI + detection).
    await _startPositionStream();

    // Drives must end even when no new GPS fix arrives (phone parked).
    _endCheckTimer?.cancel();
    _endCheckTimer =
        Timer.periodic(_endCheckInterval, (_) => checkForEndedTrip());

    _isTracking = true;
    debugPrint('TrackingService: STARTED');
  }

  Future<void> _startPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = _locationService.positionStream.listen(
      _onPosition,
      onError: (e) => debugPrint('Position stream error: $e'),
    );
  }

  void _onPosition(Position position) {
    final now = DateTime.now();
    final latLng = LatLng(position.latitude, position.longitude);

    // iOS reports a negative speed when it has none; the detector derives it.
    final speedMph = position.speed < 0
        ? -1.0
        : LocationService.speedMpsToMph(position.speed);
    _lastSpeedMph = math.max(speedMph, 0);

    if (_manualStart != null) {
      if (_lastPoint != null) {
        _manualDistance += DistanceCalculator.distanceBetween(_lastPoint!, latLng);
      }
      _manualRoute.add(LatLngPoint.fromLatLng(latLng));
    }
    _lastPoint = latLng;

    final result = _detector.processLocation(
      position: latLng,
      speedMph: speedMph,
      timestamp: now,
      // A negative accuracy means the coordinates are invalid.
      accuracyMeters: position.accuracy < 0 ? double.infinity : position.accuracy,
    );
    unawaited(_handleDetectorResult(result));
    _publishActiveTrip();
  }

  /// Closes a drive that ended while no GPS fixes were arriving. Runs every
  /// 30 s while tracking, and whenever the app returns to the foreground.
  Future<void> checkForEndedTrip() async {
    await _handleDetectorResult(_detector.checkTimeout(DateTime.now()));
    _publishActiveTrip();
  }

  Future<void> _handleDetectorResult(TripDetectionResult result) async {
    if (result.isStart) {
      debugPrint('TRIP START DETECTED at ${DateHelpers.formatTime(result.time!)}');
    } else if (result.isEnd) {
      await _saveDetectedTrip(result);
    }
  }

  Future<void> _saveDetectedTrip(TripDetectionResult result) async {
    final start = result.startTime!;
    final end = result.time!;
    final points =
        result.route.map((p) => LatLngPoint.fromLatLng(p)).toList();

    var trip = Trip(
      id: const Uuid().v4(),
      startTime: start,
      endTime: end,
      distanceMiles: result.distanceMiles!,
      durationMinutes: end.difference(start).inMinutes.clamp(1, 9999),
      routePoints: _thinRoute(points, maxPoints: 120),
      // Not business until classified (by the user or an auto-classify rule).
      category: TripCategory.other,
      isConfirmed: false,
    );

    // Auto-classify from Work Hours / Named Locations before the drive hits
    // the review queue (MileIQ-style), then enrich place ids / addresses while
    // the geocoder opt-in is on. A 6 s timeout means a slow geocoder never
    // loses a drive.
    final settings = _db.getSettings();
    final autoCat = AutoClassifier().classify(
      startTime: start,
      startLat: points.isEmpty ? 0.0 : points.first.latitude,
      startLng: points.isEmpty ? 0.0 : points.first.longitude,
      workHours: settings.workHours,
      namedLocations: settings.namedLocations,
    );
    var toSave = autoCat != null
        ? trip.copyWith(category: autoCat, isConfirmed: true)
        : trip;

    if (settings.geocodingEnabled && points.length >= 2) {
      toSave = await TripEnricher.instance
          .enrich(toSave)
          .timeout(const Duration(seconds: 6), onTimeout: () => toSave);
    }

    await _db.saveTrip(toSave);

    if (settings.notificationsEnabled) {
      await _showTripEndedNotification(toSave);
    }

    debugPrint('TRIP ENDED: ${toSave.formattedDistance} in ${toSave.formattedDuration}');
  }

  void _publishActiveTrip() {
    if (_manualStart != null) {
      activeTripNotifier.value = ActiveTrip(
        startTime: _manualStart!,
        currentDistanceMiles: _manualDistance,
        currentSpeedMph: _lastSpeedMph,
        routePoints: List.from(_manualRoute),
      );
    } else if (_detector.isPotentialTrip) {
      activeTripNotifier.value = ActiveTrip(
        startTime: _detector.currentStart!,
        currentDistanceMiles: _detector.currentMiles,
        currentSpeedMph: _lastSpeedMph,
        routePoints: _detector.currentRoute
            .map((p) => LatLngPoint.fromLatLng(p))
            .toList(),
      );
    } else {
      activeTripNotifier.value = null;
    }
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
    final title = AppStrings.tripEndedNotificationTitle;
    String body;
    final endLabel = placeLabel(
      trip.endLocationId,
      trip.endAddress,
      {
        for (final place in _db.getSettings().namedLocations) place.id: place,
      },
    );
    if (trip.endLocationId != null) {
      body = '${trip.distanceMiles.toStringAsFixed(1)} mi drive to $endLabel. Tap to classify.';
    } else {
      body = AppStrings.tripEndedNotificationBody
          .replaceFirst('%s', trip.distanceMiles.toStringAsFixed(1));
    }

    const androidDetails = AndroidNotificationDetails(
      'milemaid_trips',
      'Trip Notifications',
      channelDescription: 'Classify your recent drive',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionBusiness,
          'Business',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          actionPersonal,
          'Personal',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          actionEdit,
          'Edit',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: tripCategoryId,
    );

    await _notifications?.show(
      trip.id.hashCode, // unique per trip
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      // Only the trip id: the category comes from the button the user taps.
      payload: '$_payloadPrefix${trip.id}',
    );
  }

  /// Stop tracking (rarely used; app is meant to be always on).
  Future<void> stopTracking() async {
    _isTracking = false;
    _endCheckTimer?.cancel();
    _endCheckTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('TrackingService: foreground service not stopped: $e');
    }
    // Keep a drive that was in progress.
    await _handleDetectorResult(_detector.forceEnd(DateTime.now()));
    _publishActiveTrip();
    debugPrint('TrackingService: STOPPED');
  }

  /// Manually start a trip (used by "Add Manual Trip" → live).
  Future<void> startManualTrip() async {
    final now = DateTime.now();
    final pos = await _locationService.getCurrentPosition();
    final first = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(37.7749, -122.4194); // Demo fallback center (synthetic coordinates for sample/manual trips)

    _manualStart = now;
    _manualRoute
      ..clear()
      ..add(LatLngPoint.fromLatLng(first));
    _manualDistance = 0;
    _lastPoint = first;
    _publishActiveTrip();
  }

  /// "End" on the live trip card. Ends a manual trip, or closes an
  /// automatically detected drive right away (it still needs review).
  Future<Trip?> endManualTrip() async {
    if (_manualStart == null) {
      await _handleDetectorResult(_detector.forceEnd(DateTime.now()));
      _publishActiveTrip();
      return null;
    }

    final now = DateTime.now();
    final start = _manualStart!;
    final sampled = _thinRoute(_manualRoute, maxPoints: 80);

    final trip = Trip(
      id: const Uuid().v4(),
      startTime: start,
      endTime: now,
      // The distance actually driven: never padded, since this feeds tax records.
      distanceMiles: _manualDistance,
      durationMinutes: now.difference(start).inMinutes,
      routePoints: sampled,
      category: TripCategory.business,
      isConfirmed: true,
    );

    await _db.saveTrip(trip);

    _manualStart = null;
    _manualRoute.clear();
    _manualDistance = 0;
    _publishActiveTrip();

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
