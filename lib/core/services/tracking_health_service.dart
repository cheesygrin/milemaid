import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:milemaid/core/services/auth_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/tracking_health.dart';

/// Local prefs for the "no miles in 48 weekday hours" red alert.
class TrackingHealthPrefs {
  const TrackingHealthPrefs({
    this.lastActivityAt,
    this.lastPushAt,
    this.lastEmailAt,
    this.countWeekends = false,
    this.trackingEnabledSince,
  });

  final DateTime? lastActivityAt;
  final DateTime? lastPushAt;
  final DateTime? lastEmailAt;

  /// When true, Saturday and Sunday count toward the 48-hour clock.
  final bool countWeekends;

  /// First time tracking was turned on after onboarding (fallback activity).
  final DateTime? trackingEnabledSince;

  Map<String, dynamic> toJson() => {
        'lastActivityAt': lastActivityAt?.toIso8601String(),
        'lastPushAt': lastPushAt?.toIso8601String(),
        'lastEmailAt': lastEmailAt?.toIso8601String(),
        'countWeekends': countWeekends,
        'trackingEnabledSince': trackingEnabledSince?.toIso8601String(),
      };

  factory TrackingHealthPrefs.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) =>
        raw == null ? null : DateTime.tryParse(raw);
    return TrackingHealthPrefs(
      lastActivityAt: parse(json['lastActivityAt'] as String?),
      lastPushAt: parse(json['lastPushAt'] as String?),
      lastEmailAt: parse(json['lastEmailAt'] as String?),
      countWeekends: json['countWeekends'] as bool? ?? false,
      trackingEnabledSince: parse(json['trackingEnabledSince'] as String?),
    );
  }

  TrackingHealthPrefs copyWith({
    DateTime? lastActivityAt,
    DateTime? lastPushAt,
    DateTime? lastEmailAt,
    bool? countWeekends,
    DateTime? trackingEnabledSince,
    bool clearAlertMarks = false,
  }) {
    return TrackingHealthPrefs(
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastPushAt: clearAlertMarks ? null : (lastPushAt ?? this.lastPushAt),
      lastEmailAt: clearAlertMarks ? null : (lastEmailAt ?? this.lastEmailAt),
      countWeekends: countWeekends ?? this.countWeekends,
      trackingEnabledSince: trackingEnabledSince ?? this.trackingEnabledSince,
    );
  }
}

/// Watches for silent tracking failure and alerts by push + email queue.
class TrackingHealthService {
  TrackingHealthService._();
  static final TrackingHealthService instance = TrackingHealthService._();

  static const _prefsKey = 'tracking_health_prefs';
  static const notificationId = 71002;
  static const payloadOpen = 'tracking:health';
  static const staleThresholdHours = 48.0;

  final DatabaseService _db = DatabaseService();
  FlutterLocalNotificationsPlugin? _notifications;

  void attachNotifications(FlutterLocalNotificationsPlugin? plugin) {
    _notifications = plugin;
  }

  TrackingHealthPrefs readPrefs() {
    final raw = _db.readMeta(_prefsKey);
    if (raw == null) return const TrackingHealthPrefs();
    try {
      return TrackingHealthPrefs.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const TrackingHealthPrefs();
    }
  }

  Future<void> _writePrefs(TrackingHealthPrefs prefs) async {
    await _db.writeMeta(_prefsKey, jsonEncode(prefs.toJson()));
  }

  Future<void> setCountWeekends(bool value) async {
    await _writePrefs(readPrefs().copyWith(countWeekends: value));
  }

  Future<void> markTrackingEnabled([DateTime? at]) async {
    final prefs = readPrefs();
    if (prefs.trackingEnabledSince != null) return;
    await _writePrefs(
      prefs.copyWith(trackingEnabledSince: at ?? DateTime.now()),
    );
  }

  /// Call whenever a drive is saved or GPS shows the tracker is alive.
  Future<void> recordActivity([DateTime? at]) async {
    final when = at ?? DateTime.now();
    final prefs = readPrefs();
    await _writePrefs(
      prefs.copyWith(
        lastActivityAt: when,
        // A new drive clears the alert window so we can warn again later.
        clearAlertMarks: true,
      ),
    );
  }

  DateTime? _effectiveLastActivity(TrackingHealthPrefs prefs) {
    final trips = _db.getAllTrips();
    DateTime? lastTrip;
    for (final trip in trips) {
      if (lastTrip == null || trip.endTime.isAfter(lastTrip)) {
        lastTrip = trip.endTime;
      }
    }
    final candidates = <DateTime>[
      if (lastTrip != null) lastTrip,
      if (prefs.lastActivityAt != null) prefs.lastActivityAt!,
      if (prefs.trackingEnabledSince != null) prefs.trackingEnabledSince!,
    ];
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Runs on launch, resume, and location wake. Sends at most one push and
  /// one email per stale incident (until a drive is logged again).
  Future<void> checkAndAlert({DateTime? now}) async {
    final settings = _db.getSettings();
    if (!settings.hasCompletedOnboarding) return;

    final prefs = readPrefs();
    final last = _effectiveLastActivity(prefs);
    if (last == null) return;

    final at = now ?? DateTime.now();
    if (!isTrackingStale(
      lastActivity: last,
      now: at,
      thresholdHours: staleThresholdHours,
      countWeekends: prefs.countWeekends,
    )) {
      return;
    }

    if (settings.notificationsEnabled && prefs.lastPushAt == null) {
      await _showPush(last);
      await _writePrefs(readPrefs().copyWith(lastPushAt: at));
    }

    if (prefs.lastEmailAt == null) {
      final sent = await _queueEmail(last);
      if (sent) {
        await _writePrefs(readPrefs().copyWith(lastEmailAt: at));
      }
    }
  }

  Future<void> _showPush(DateTime lastActivity) async {
    const title = 'Mileage may not be tracking';
    final body =
        'No drives logged since ${_shortDate(lastActivity)}. Open MileMaid, '
        'confirm Location is Always, or restart your phone.';

    const android = AndroidNotificationDetails(
      'milemaid_tracking_health',
      'Tracking health',
      channelDescription: 'Alerts when drives stop being logged',
      importance: Importance.max,
      priority: Priority.max,
    );
    const ios = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notifications?.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: payloadOpen,
    );
  }

  /// Writes a mail-outbox doc for a Cloud Function to send. Returns false when
  /// the user is signed out or Firebase is unavailable.
  Future<bool> _queueEmail(DateTime lastActivity) async {
    if (!AuthService.available) return false;
    final user = AuthService.instance.currentUser;
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) return false;

    try {
      final doc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mail_outbox')
          .doc();
      await doc.set({
        'type': 'tracking_stale',
        'to': email,
        'subject': 'MileMaid: mileage may not be tracking',
        'body': _emailBody(lastActivity),
        'lastActivityAt': lastActivity.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('TrackingHealthService: email queue failed: $e');
      return false;
    }
  }

  String _emailBody(DateTime lastActivity) {
    return 'Hey — MileMaid has not logged a drive since ${_shortDate(lastActivity)}.\n\n'
        'That usually means background location stopped. Please:\n'
        '1. Open MileMaid once\n'
        '2. Confirm Location access is set to Always\n'
        '3. Confirm Background App Refresh is on for MileMaid\n'
        '4. If it still looks stuck, restart your phone and open the app again\n\n'
        'We only email when two weekdays pass with no miles (weekends do not count unless you turn that on in Settings).\n\n'
        '— MileMaid';
  }

  String _shortDate(DateTime t) {
    final local = t.toLocal();
    return '${local.month}/${local.day}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
