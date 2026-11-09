import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milemaid/core/models/backup_state.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/core/services/backup_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/drive_backup_store.dart';

/// All data in this file is made up (fake ids, generic purposes, coordinates
/// near lat 40 / lng -100), per AGENTS.md. No network: BackupStore is faked.
class FakeBackupStore implements BackupStore {
  final Map<String, List<int>> files = {};

  /// When set, upload throws with this message (simulates a Drive outage).
  Object? throwOnUpload;

  @override
  Future<void> upload(String name, List<int> bytes) async {
    final err = throwOnUpload;
    if (err != null) throw err;
    files[name] = bytes;
  }

  @override
  Future<List<BackupFile>> list() async {
    final names = files.keys.toList()..sort();
    return [
      for (final name in names.reversed)
        BackupFile(id: name, name: name, sizeBytes: files[name]!.length),
    ];
  }

  @override
  Future<List<int>> download(String id) async {
    final bytes = files[id];
    if (bytes == null) throw StateError('No such file: $id');
    return bytes;
  }
}

/// Fake [DriveAuth]: silent re-auth always fails, but every attempt is
/// counted so tests can assert the plugin was (or was not) touched.
class FakeDriveAuth implements DriveAuth {
  int silentCalls = 0;

  @override
  String? lastAccountEmail = 'you@example.com';

  @override
  Future<gapis.AuthClient?> silentClient() async {
    silentCalls++;
    return null; // sign-in expired / revoked: reconnect needed
  }

  @override
  Future<String> connect() async => 'you@example.com';

  @override
  Future<void> disconnect() async {
    lastAccountEmail = null;
  }
}

Trip _trip({required String id, double miles = 5.2}) => Trip(
      id: id,
      startTime: DateTime.parse('2026-01-15T09:00:00Z'),
      endTime: DateTime.parse('2026-01-15T09:30:00Z'),
      distanceMiles: miles,
      durationMinutes: 30,
      routePoints: const [
        LatLngPoint(latitude: 40.0, longitude: -100.0),
        LatLngPoint(latitude: 40.01, longitude: -100.01),
      ],
      category: TripCategory.business,
      purpose: 'Client site visit',
      isConfirmed: true,
    );

Vehicle _vehicle(String id) => Vehicle(
      id: id,
      name: 'Test Vehicle',
      makeModel: 'Generic Sedan',
      year: 2020,
      color: 'Blue',
    );

NamedLocation _place(String id) => NamedLocation(
      id: id,
      name: 'Office',
      latitude: 40.0,
      longitude: -100.0,
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );

PurposePreset _purpose(String id) => PurposePreset(
      id: id,
      name: 'Errand',
      category: TripCategory.personal,
      sortOrder: 9,
    );

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp
        .createTempSync('milemaid_backup_test')
        .path);
    await DatabaseService().init();
  });

  late FakeBackupStore fake;
  setUp(() async {
    await DatabaseService().clearAllData(); // 0 trips, 1 vehicle, 4 purposes
    fake = FakeBackupStore();
    BackupService.instance.setOverridesForTesting(store: fake, auth: null);
  });

  tearDown(() {
    BackupService.instance.setOverridesForTesting(store: null, auth: null);
  });

  group('snapshot round trip through JSON', () {
    test('buildSnapshot -> JSON -> merge restores trips byte-for-byte', () async {
      final db = DatabaseService();
      final t1 = _trip(id: 'trip-1');
      final t2 = _trip(id: 'trip-2', miles: 12.3);
      await db.saveTrip(t1);
      await db.saveTrip(t2);

      final snapshot = await BackupService.instance.buildSnapshot();
      expect(snapshot['app'], 'MileMaid');
      expect(snapshot['schema'], 1);
      expect(snapshot['settings'], isNotNull);

      final encoded = jsonEncode(snapshot);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      await db.clearAllData(); // simulate a fresh phone
      expect(db.getAllTrips(), isEmpty);

      final result = await BackupService.instance.mergeSnapshot(decoded);
      expect(result.tripsAdded, 2);
      // clearAllData reseeds a fresh vehicle with a new id, so the snapshot's
      // vehicle is missing locally and is restored too.
      expect(result.vehiclesAdded, 1);
      final trips = db.getAllTrips();
      expect(trips.length, 2);
      // Restored trips match the originals exactly.
      final byId = {for (final t in trips) t.id: t};
      expect(jsonEncode(byId['trip-1']!.toJson()),
          jsonEncode(t1.toJson()));
      expect(jsonEncode(byId['trip-2']!.toJson()),
          jsonEncode(t2.toJson()));
    });
  });

  group('mergeSnapshot', () {
    test('adds missing items of every kind and reports counts', () async {
      final result = await BackupService.instance.mergeSnapshot({
        'app': 'MileMaid',
        'schema': 1,
        'trips': [_trip(id: 't-new').toJson()],
        'vehicles': [_vehicle('v-new').toJson()],
        'locations': [_place('p-new').toJson()],
        'purposes': [_purpose('pp-new').toJson()],
      });
      expect(result.tripsAdded, 1);
      expect(result.vehiclesAdded, 1);
      expect(result.placesAdded, 1);
      expect(result.purposesAdded, 1);

      final db = DatabaseService();
      expect(db.hasTrip('t-new'), isTrue);
      expect(db.hasVehicle('v-new'), isTrue);
      expect(db.hasLocation('p-new'), isTrue);
      expect(db.hasPurpose('pp-new'), isTrue);
    });

    test('never overwrites or deletes anything local', () async {
      final db = DatabaseService();
      final local = _trip(id: 't-local', miles: 1.0);
      await db.saveTrip(local);
      final localBefore = jsonEncode(local.toJson());

      // Remote has the SAME id with different data, plus a new one.
      final result = await BackupService.instance.mergeSnapshot({
        'app': 'MileMaid',
        'schema': 1,
        'trips': [
          _trip(id: 't-local', miles: 99.9).toJson(),
          _trip(id: 't-remote').toJson(),
        ],
        'vehicles': [db.getAllVehicles().first.toJson()], // already exists
        'locations': [],
        'purposes': [db.getAllPurposes().first.toJson()], // already exists
      });
      expect(result.tripsAdded, 1);
      expect(result.vehiclesAdded, 0);
      expect(result.purposesAdded, 0);

      final trips = db.getAllTrips();
      expect(trips.length, 2); // nothing deleted
      final kept = trips.firstWhere((t) => t.id == 't-local');
      expect(jsonEncode(kept.toJson()), localBefore); // byte-for-byte unchanged
      expect(kept.distanceMiles, 1.0); // local value, not the remote 99.9
    });

    test('rejects non-MileMaid files and unknown schemas', () async {
      expect(
        () => BackupService.instance
            .mergeSnapshot({'app': 'NotMileMaid', 'schema': 1}),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupService.instance.mergeSnapshot({'app': 'MileMaid'}),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupService.instance
            .mergeSnapshot({'app': 'MileMaid', 'schema': 2}),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('fileNameFor', () {
    test('milemaid-backup-YYYY-MM-DD.json, zero-padded', () {
      expect(BackupService.fileNameFor(DateTime(2026, 11, 8)),
          'milemaid-backup-2026-11-08.json');
      expect(BackupService.fileNameFor(DateTime(2026, 3, 1)),
          'milemaid-backup-2026-03-01.json');
    });
  });

  group('shouldAutoBackup', () {
    final now = DateTime(2026, 11, 8, 12, 0, 0);

    test('never backed up -> always true', () {
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: null, now: now, afterNewTrip: false),
        isTrue,
      );
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: null, now: now, afterNewTrip: true),
        isTrue,
      );
    });

    test('after a new trip: >= 10 min since last success', () {
      final nineM59s = now.subtract(const Duration(minutes: 9, seconds: 59));
      final tenMin = now.subtract(const Duration(minutes: 10));
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: nineM59s, now: now, afterNewTrip: true),
        isFalse,
      );
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: tenMin, now: now, afterNewTrip: true),
        isTrue,
      );
    });

    test('after a new trip: under 10 min -> false', () {
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: now.subtract(const Duration(minutes: 5)),
            now: now,
            afterNewTrip: true),
        isFalse,
      );
    });

    test('no new trip: only after >= 24 h', () {
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: now.subtract(const Duration(hours: 23, minutes: 59)),
            now: now,
            afterNewTrip: false),
        isFalse,
      );
      expect(
        BackupService.shouldAutoBackup(
            lastSuccess: now.subtract(const Duration(hours: 24)),
            now: now,
            afterNewTrip: false),
        isTrue,
      );
    });
  });

  group('autoBackup', () {
    // The auto path only runs for a previously connected account (R2), so
    // seed a connected state first.
    Future<void> seedConnectedAccount([DateTime? lastSuccess]) async {
      final db = DatabaseService();
      final state = BackupState()
        ..accountEmail = 'you@example.com'
        ..lastSuccessAt = lastSuccess;
      await db.saveBackupState(state);
    }

    test('uploads today\'s snapshot and records success state', () async {
      final db = DatabaseService();
      await db.saveTrip(_trip(id: 't-1'));
      await seedConnectedAccount();

      await BackupService.instance.autoBackup(afterNewTrip: true);

      final state = db.getBackupState();
      expect(state.lastSuccessAt, isNotNull);
      expect(state.lastError, isNull);
      expect(state.accountEmail, isNotNull); // test seam fills a display email
      final today = DateTime.now();
      final name = BackupService.fileNameFor(today);
      expect(fake.files.containsKey(name), isTrue);
      final snapshot =
          jsonDecode(utf8.decode(fake.files[name]!)) as Map<String, dynamic>;
      expect(snapshot['app'], 'MileMaid');
      expect(snapshot['schema'], 1);
    });

    test('rate limit: skips within 10 min of a success without a new trip',
        () async {
      final db = DatabaseService();
      final state = BackupState()
        ..accountEmail = 'you@example.com'
        ..lastSuccessAt = DateTime.now().subtract(const Duration(minutes: 5));
      await db.saveBackupState(state);

      await BackupService.instance.autoBackup(afterNewTrip: false);

      expect(fake.files, isEmpty);
      expect(db.getBackupState().lastSuccessAt,
          state.lastSuccessAt); // untouched
    });

    test('a store that throws records the error and returns normally',
        () async {
      final db = DatabaseService();
      await seedConnectedAccount();
      fake.throwOnUpload = Exception('Drive is down');

      // Must complete without throwing.
      await BackupService.instance.autoBackup(afterNewTrip: true);

      final state = db.getBackupState();
      expect(state.lastSuccessAt, isNull);
      expect(state.lastAttemptAt, isNotNull);
      expect(state.lastError, contains('Drive is down'));
      expect(fake.files, isEmpty);
    });

    test('only one backup runs at a time', () async {
      final db = DatabaseService();
      await seedConnectedAccount(
          DateTime.now().subtract(const Duration(days: 2))); // force-eligible

      // Second call while the first is running is dropped (single-flight).
      await Future.wait([
        BackupService.instance.autoBackup(afterNewTrip: false),
        BackupService.instance.autoBackup(afterNewTrip: false),
      ]);
      // Both files would be the same name anyway; assert no crash and a
      // success was recorded exactly once.
      expect(db.getBackupState().lastSuccessAt, isNotNull);
    });
  });

  group('auto path vs never-connected / disconnected accounts (R2)', () {
    test('never-connected resume leaves the state untouched', () async {
      final db = DatabaseService();
      // clearAllData in setUp leaves no backup state at all: fresh install.
      expect(db.getBackupState().accountEmail, isNull);

      await BackupService.instance.autoBackup(afterNewTrip: true);

      final state = db.getBackupState();
      expect(fake.files, isEmpty); // the plugin/store was never touched
      expect(state.accountEmail, isNull);
      expect(state.lastSuccessAt, isNull);
      expect(state.lastAttemptAt, isNull);
      expect(state.lastError, isNull);
      expect(state.needsReconnect, isFalse);
    });

    test('connected account whose silent re-auth fails -> Reconnect needed',
        () async {
      final db = DatabaseService();
      final state = BackupState()..accountEmail = 'you@example.com';
      await db.saveBackupState(state);

      final auth = FakeDriveAuth();
      BackupService.instance.setOverridesForTesting(store: null, auth: auth);

      await BackupService.instance.autoBackup(afterNewTrip: true);

      expect(auth.silentCalls, 1); // the silent attempt was made
      final after = db.getBackupState();
      expect(after.needsReconnect, isTrue);
      expect(after.lastError, contains('Reconnect needed'));
      expect(after.lastAttemptAt, isNotNull);
      expect(after.lastSuccessAt, isNull);
      // accountEmail is kept so Settings can still show whom to reconnect.
      expect(after.accountEmail, 'you@example.com');
    });

    test('disconnect then resume leaves "Not connected"', () async {
      final db = DatabaseService();
      final state = BackupState()
        ..accountEmail = 'you@example.com'
        ..needsReconnect = true
        ..lastError = 'Reconnect needed: Google Drive sign-in expired.';
      await db.saveBackupState(state);

      // Exactly what the Settings Disconnect button does (backup_section.dart).
      final auth = FakeDriveAuth();
      await auth.disconnect();
      final reset = db.getBackupState()..reset();
      await db.saveBackupState(reset);

      BackupService.instance.setOverridesForTesting(store: null, auth: auth);
      await BackupService.instance.autoBackup(afterNewTrip: true);

      expect(auth.silentCalls, 0); // never touched the sign-in plugin
      final after = db.getBackupState();
      expect(after.accountEmail, isNull);
      expect(after.needsReconnect, isFalse);
      expect(after.lastError, isNull);
      expect(after.lastSuccessAt, isNull); // Settings shows "Not connected"
    });
  });

  group('BackupState persistence', () {
    test('round trips through the settings box as JSON', () async {
      final db = DatabaseService();
      final state = BackupState()
        ..lastSuccessAt = DateTime.parse('2026-11-08T12:00:00Z')
        ..lastAttemptAt = DateTime.parse('2026-11-08T12:05:00Z')
        ..lastError = null
        ..accountEmail = 'you@example.com'
        ..needsReconnect = false;
      await db.saveBackupState(state);

      final loaded = db.getBackupState();
      expect(loaded.lastSuccessAt, state.lastSuccessAt);
      expect(loaded.lastAttemptAt, state.lastAttemptAt);
      expect(loaded.accountEmail, 'you@example.com');
      expect(loaded.needsReconnect, isFalse);

      state.lastError = 'boom';
      state.needsReconnect = true;
      await db.saveBackupState(state);
      expect(db.getBackupState().lastError, 'boom');
      expect(db.getBackupState().needsReconnect, isTrue);
    });
  });
}
