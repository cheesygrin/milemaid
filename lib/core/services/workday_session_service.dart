import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/workday_session.dart';

/// Persists a closed Home→Home loop so the UI can ask "all business?"
class PendingWorkdayPrompt {
  const PendingWorkdayPrompt({
    required this.tripIds,
    required this.totalMiles,
    required this.closedAt,
    required this.homePlaceId,
  });

  final List<String> tripIds;
  final double totalMiles;
  final DateTime closedAt;
  final String homePlaceId;

  int get driveCount => tripIds.length;

  Map<String, dynamic> toJson() => {
        'tripIds': tripIds,
        'totalMiles': totalMiles,
        'closedAt': closedAt.toIso8601String(),
        'homePlaceId': homePlaceId,
      };

  factory PendingWorkdayPrompt.fromJson(Map<String, dynamic> json) {
    return PendingWorkdayPrompt(
      tripIds: (json['tripIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      totalMiles: (json['totalMiles'] as num?)?.toDouble() ?? 0,
      closedAt: DateTime.parse(
        json['closedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      homePlaceId: json['homePlaceId'] as String? ?? '',
    );
  }
}

/// Detects return-Home sessions, stores a pending prompt, and notifies.
class WorkdaySessionService {
  WorkdaySessionService._();
  static final WorkdaySessionService instance = WorkdaySessionService._();

  static const _pendingKey = 'pending_workday_prompt';
  static const notificationId = 71001;
  static const payloadOpen = 'workday:review';

  final DatabaseService _db = DatabaseService();
  final ValueNotifier<PendingWorkdayPrompt?> pending =
      ValueNotifier<PendingWorkdayPrompt?>(null);

  FlutterLocalNotificationsPlugin? _notifications;

  void attachNotifications(FlutterLocalNotificationsPlugin? plugin) {
    _notifications = plugin;
  }

  void loadPending() {
    pending.value = _readPending();
  }

  PendingWorkdayPrompt? _readPending() {
    final raw = _db.readMeta(_pendingKey);
    if (raw == null) return null;
    try {
      return PendingWorkdayPrompt.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePending(PendingWorkdayPrompt? prompt) async {
    await _db.writeMeta(
      _pendingKey,
      prompt == null ? null : jsonEncode(prompt.toJson()),
    );
    pending.value = prompt;
  }

  Future<void> clearPending() => _writePending(null);

  /// After a trip is saved (with place ids), close a workday session if this
  /// drive returned to Home.
  Future<WorkdaySession?> considerTrip(
    Trip saved, {
    bool notificationsEnabled = true,
  }) async {
    final home = homePlace(_db.getAllLocations());
    if (home == null) return null;

    final session = detectReturnHomeSession(
      justEnded: saved,
      allTrips: _db.getAllTrips(),
      home: home,
    );
    if (session == null) return null;

    final unconfirmed = session.unconfirmed;
    if (unconfirmed.length < 2) return null;

    final prompt = PendingWorkdayPrompt(
      tripIds: unconfirmed.map((t) => t.id).toList(),
      totalMiles:
          unconfirmed.fold<double>(0, (sum, t) => sum + t.distanceMiles),
      closedAt: saved.endTime,
      homePlaceId: home.id,
    );
    await _writePending(prompt);

    if (notificationsEnabled) {
      await _notify(prompt, home);
    }
    return session;
  }

  Future<void> _notify(
    PendingWorkdayPrompt prompt,
    NamedLocation home,
  ) async {
    final miles = prompt.totalMiles.toStringAsFixed(1);
    final count = prompt.driveCount;
    final title = 'Back at ${home.name}';
    final body = count == 1
        ? '1 drive ($miles mi). Was it business?'
        : '$count drives ($miles mi). Were they all business?';

    const android = AndroidNotificationDetails(
      'milemaid_workday',
      'Workday review',
      channelDescription: 'Ask after you return home whether drives were business',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _notifications?.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: payloadOpen,
    );
  }
}
