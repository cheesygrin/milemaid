import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:milemaid/core/config/backup_config.dart';
import 'package:milemaid/core/models/backup_state.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/drive_backup_store.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';

/// Thrown by [BackupService.mergeSnapshot] for files that are not a MileMaid
/// backup snapshot, with a message meant to be shown to the user.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pure backup/restore logic.
///
/// All remote access goes through the [BackupStore] interface so every part of
/// this class is testable with a fake and no network (test/backup_test.dart).
class BackupService {
  static final BackupService instance = BackupService._internal();

  BackupService._internal();

  static const int snapshotSchema = 1;

  /// Test seams. Null means "use the real Google Drive stack".
  BackupStore? _storeOverride;
  DriveAuth? _authOverride;

  /// The store used for the current/last backup run, for state bookkeeping.
  BackupStore? _activeStore;
  String? _activeEmail;

  /// Guards against concurrent backups; later calls while one runs are dropped.
  bool _running = false;

  @visibleForTesting
  void setOverridesForTesting({BackupStore? store, DriveAuth? auth}) {
    _storeOverride = store;
    _authOverride = auth;
  }

  /// Full local data plus a schema marker. Settings are included in the
  /// snapshot for completeness but mergeSnapshot never restores them.
  Future<Map<String, dynamic>> buildSnapshot() async {
    final data = await DatabaseService().exportAllDataAsJson();
    data['schema'] = snapshotSchema;
    return data;
  }

  /// One file per local day, overwritten on every backup that day.
  static String fileNameFor(DateTime localDay) {
    final m = localDay.month.toString().padLeft(2, '0');
    final d = localDay.day.toString().padLeft(2, '0');
    return 'milemaid-backup-${localDay.year}-$m-$d.json';
  }

  /// Merges [snapshot] into local data: adds trips, vehicles, places and
  /// purposes whose ids are missing locally. NEVER overwrites or deletes
  /// anything local, and settings are not restored.
  ///
  /// Throws [BackupFormatException] for unknown schemas or non-MileMaid
  /// files, with a user-presentable message.
  Future<MergeResult> mergeSnapshot(Map<String, dynamic> snapshot) async {
    if (snapshot['app'] != 'MileMaid') {
      throw const BackupFormatException(
          'This file is not a MileMaid backup.');
    }
    if (snapshot['schema'] != snapshotSchema) {
      throw BackupFormatException(
          'Unsupported backup schema: ${snapshot['schema']}. '
          'This file may be from a newer app version.');
    }

    final db = DatabaseService();
    var tripsAdded = 0;
    var vehiclesAdded = 0;
    var placesAdded = 0;
    var purposesAdded = 0;

    for (final raw in _listOfMaps(snapshot['trips'])) {
      final id = raw['id'] as String?;
      if (id == null || db.hasTrip(id)) continue;
      await db.saveTrip(Trip.fromJson(raw));
      tripsAdded++;
    }
    if (tripsAdded > 0) {
      unawaited(TripSyncService.instance.pushAllLocal());
    }
    for (final raw in _listOfMaps(snapshot['vehicles'])) {
      final id = raw['id'] as String?;
      if (id == null || db.hasVehicle(id)) continue;
      await db.saveVehicle(Vehicle.fromJson(raw));
      vehiclesAdded++;
    }
    for (final raw in _listOfMaps(snapshot['locations'])) {
      final id = raw['id'] as String?;
      if (id == null || db.hasLocation(id)) continue;
      await db.saveLocation(NamedLocation.fromJson(raw));
      placesAdded++;
    }
    for (final raw in _listOfMaps(snapshot['purposes'])) {
      final id = raw['id'] as String?;
      if (id == null || db.hasPurpose(id)) continue;
      await db.savePurpose(PurposePreset.fromJson(raw));
      purposesAdded++;
    }

    return MergeResult(
      tripsAdded: tripsAdded,
      vehiclesAdded: vehiclesAdded,
      placesAdded: placesAdded,
      purposesAdded: purposesAdded,
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Whether an automatic backup should run now.
  ///
  /// True when the user never backed up, or (after a new trip) at least 10
  /// minutes since the last success, or at least 24 hours since the last
  /// success regardless of trips.
  static bool shouldAutoBackup({
    DateTime? lastSuccess,
    required DateTime now,
    required bool afterNewTrip,
  }) {
    if (lastSuccess == null) return true;
    final since = now.difference(lastSuccess);
    if (since >= const Duration(hours: 24)) return true;
    if (afterNewTrip && since >= const Duration(minutes: 10)) return true;
    return false;
  }

  /// Fire-and-forget automatic backup. Never throws, never blocks trip
  /// saving; failures are recorded in the backup state. Only one backup runs
  /// at a time (later calls while one is running are dropped).
  Future<void> autoBackup({required bool afterNewTrip}) =>
      _runBackup(afterNewTrip: afterNewTrip, force: false);

  /// Manual "Back up now" — ignores the rate limits, still records state and
  /// swallows errors into the backup state.
  Future<void> backupNow() => _runBackup(afterNewTrip: false, force: true);

  Future<void> _runBackup({
    required bool afterNewTrip,
    required bool force,
  }) async {
    if (_running) return;
    _running = true;
    try {
      final db = DatabaseService();
      final state = db.getBackupState();
      final now = DateTime.now();
      if (!force) {
        // Never connected, or Disconnect reset the state: do not touch the
        // plugin and leave the backup state exactly as it is. Without this a
        // fresh install would flip to "Reconnect needed" on the first resume.
        if (state.accountEmail == null) return;
        if (!shouldAutoBackup(
          lastSuccess: state.lastSuccessAt,
          now: now,
          afterNewTrip: afterNewTrip,
        )) {
          return;
        }
      }

      final store = await _resolveStore();
      if (store == null) return; // not configured, or reconnect needed

      final snapshot = await buildSnapshot();
      final name = fileNameFor(DateTime.now());
      final bytes = utf8.encode(jsonEncode(snapshot));
      await store.upload(name, bytes);

      final successAt = DateTime.now();
      state.lastSuccessAt = successAt;
      state.lastAttemptAt = successAt;
      state.lastError = null;
      state.needsReconnect = false;
      final email = _activeEmail;
      if (email != null) state.accountEmail = email;
      await db.saveBackupState(state);
    } catch (e) {
      await _recordFailure(e.toString());
    } finally {
      _running = false;
    }
  }

  /// Returns the store to use for this run, or null when the run should be
  /// skipped (backup not configured, or silent re-auth failed — in which case
  /// the state is updated here, but only when an account had been connected
  /// before; a never-connected user just isn't backed up yet).
  Future<BackupStore?> _resolveStore() async {
    final override = _storeOverride;
    if (override != null) {
      _activeStore = override;
      _activeEmail ??= 'backup-test@example.com';
      return override;
    }
    final auth = _authOverride;
    // Test seam: an injected [DriveAuth] stands in for a configured build, so
    // the fake can be exercised without a client ID. Real builds keep the
    // configured check: no client ID -> no plugin call at all.
    if (auth == null && !driveBackupConfigured) return null;
    final real = auth ?? GoogleDriveAuth.instance;
    final client = await real.silentClient();
    if (client == null) {
      final db = DatabaseService();
      final state = db.getBackupState();
      if (state.accountEmail == null) return null; // never connected
      state.lastAttemptAt = DateTime.now();
      state.needsReconnect = true;
      state.lastError =
          'Reconnect needed: Google Drive sign-in expired or was revoked.';
      await db.saveBackupState(state);
      return null;
    }
    _activeStore = DriveBackupStore(drive.DriveApi(client));
    _activeEmail = real.lastAccountEmail;
    return _activeStore;
  }

  Future<void> _recordFailure(String error) async {
    try {
      final db = DatabaseService();
      final state = db.getBackupState();
      state.lastAttemptAt = DateTime.now();
      state.lastError = error;
      await db.saveBackupState(state);
    } catch (_) {
      // Even recording the failure failed; nothing left to do. The next
      // attempt will retry. Never propagate: backup must not crash the app.
    }
  }

  /// Downloads [file] via the store and merges it. Exposed so the Settings UI
  /// reuses the same validation and merge path as everything else.
  Future<MergeResult> restoreFrom(BackupStore store, BackupFile file) async {
    final bytes = await store.download(file.id);
    final snapshot =
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return mergeSnapshot(snapshot);
  }
}
