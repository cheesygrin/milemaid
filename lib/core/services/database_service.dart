import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milemaid/core/models/backup_state.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/core/models/user_settings.dart';
import 'package:uuid/uuid.dart';

/// Singleton wrapper around Hive.
/// We store complex models as JSON strings because mixing @freezed + @HiveType
/// reliably is fragile across generator versions. JSON roundtrip is simple and robust.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _tripsBox = 'trips_json';
  static const String _vehiclesBox = 'vehicles_json';
  static const String _settingsBox = 'settings_json';
  static const String _locationsBox = 'locations_json';
  static const String _purposesBox = 'purposes_json';

  late Box<String> _trips;
  late Box<String> _vehicles;
  late Box<String> _settings;
  late Box<String> _locations;
  late Box<String> _purposes;

  bool _initialized = false;

  /// Fired after any trip is saved, updated, or deleted. Wire UI refresh here.
  void Function()? onTripsChanged;

  Future<void> init() async {
    if (_initialized) return;

    _trips = await Hive.openBox<String>(_tripsBox);
    _vehicles = await Hive.openBox<String>(_vehiclesBox);
    _settings = await Hive.openBox<String>(_settingsBox);
    _locations = await Hive.openBox<String>(_locationsBox);
    _purposes = await Hive.openBox<String>(_purposesBox);

    _initialized = true;
    await _seedDefaultsIfNeeded();
  }

  /// Starter data every fresh install gets. Cloud sync uses these to tell an
  /// untouched default apart from something the user created.
  static const String defaultVehicleName = 'Primary Vehicle';
  static const String defaultVehicleMakeModel = 'Your Car';
  static const List<(String, TripCategory)> defaultPurposes = [
    ('Client visit', TripCategory.business),
    ('Supplies run', TripCategory.business),
    ('Meeting', TripCategory.business),
    ('Errand', TripCategory.personal),
  ];

  Future<void> _seedDefaultsIfNeeded() async {
    if (_vehicles.isEmpty) {
      final v = Vehicle(
        id: const Uuid().v4(),
        name: defaultVehicleName,
        makeModel: defaultVehicleMakeModel,
        year: DateTime.now().year,
        color: 'Silver',
      );
      await _vehicles.put(v.id, jsonEncode(v.toJson()));
    }
    if (_settings.isEmpty) {
      await _settings.put('main', jsonEncode(const UserSettings().toJson()));
    }
    if (_purposes.isEmpty) {
      await _seedDefaultPurposes();
    }
  }

  /// Generic starter purposes; Tim adds his own on the phone. Seeded only
  /// when the box is empty.
  Future<void> _seedDefaultPurposes() async {
    for (var i = 0; i < defaultPurposes.length; i++) {
      final (name, category) = defaultPurposes[i];
      final p = PurposePreset(
        id: const Uuid().v4(),
        name: name,
        category: category,
        sortOrder: i,
      );
      await _purposes.put(p.id, jsonEncode(p.toJson()));
    }
  }

  // TRIPS
  List<Trip> getAllTrips() {
    return _trips.values
        .map((s) => Trip.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<Trip> saveTrip(Trip trip) async {
    await _trips.put(trip.id, jsonEncode(trip.toJson()));
    onTripsChanged?.call();
    return trip;
  }

  Future<void> updateTrip(Trip trip) => saveTrip(trip);

  Future<void> deleteTrip(String id) async {
    await _trips.delete(id);
    onTripsChanged?.call();
  }

  List<Trip> getTripsInRange(DateTime start, DateTime end) {
    return getAllTrips()
        .where((t) => t.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
                      t.startTime.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  // VEHICLES
  List<Vehicle> getAllVehicles() {
    return _vehicles.values
        .map((s) => Vehicle.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> saveVehicle(Vehicle v) async {
    await _vehicles.put(v.id, jsonEncode(v.toJson()));
    return v;
  }

  Future<void> deleteVehicle(String id) async => _vehicles.delete(id);

  Vehicle? getVehicle(String? id) {
    if (id == null) return null;
    final raw = _vehicles.get(id);
    return raw == null ? null : Vehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // SETTINGS
  UserSettings getSettings() {
    final raw = _settings.get('main');
    if (raw == null) return const UserSettings();
    return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<UserSettings> updateSettings(UserSettings s) async {
    final updated = s.copyWith(lastUpdated: DateTime.now());
    await _settings.put('main', jsonEncode(updated.toJson()));
    return updated;
  }

  // NAMED LOCATIONS
  List<NamedLocation> getAllLocations() {
    return _locations.values
        .map((s) => NamedLocation.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<NamedLocation> saveLocation(NamedLocation place) async {
    await _locations.put(place.id, jsonEncode(place.toJson()));
    onTripsChanged?.call();
    return place;
  }

  Future<void> deleteLocation(String id) async {
    await _locations.delete(id);
    onTripsChanged?.call();
  }

  // PURPOSE PRESETS
  List<PurposePreset> getAllPurposes() {
    return _purposes.values
        .map((s) => PurposePreset.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<PurposePreset> savePurpose(PurposePreset preset) async {
    await _purposes.put(preset.id, jsonEncode(preset.toJson()));
    onTripsChanged?.call();
    return preset;
  }

  Future<void> deletePurpose(String id) async {
    await _purposes.delete(id);
    onTripsChanged?.call();
  }

  // BACKUP STATE
  // Stored under a dedicated key in the settings box (NOT freezed
  // UserSettings): lastSuccessAt/lastAttemptAt/lastError/accountEmail/
  // needsReconnect as JSON.
  static const String _backupStateKey = 'backup_state';

  BackupState getBackupState() {
    final raw = _settings.get(_backupStateKey);
    if (raw == null) return BackupState();
    return BackupState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveBackupState(BackupState state) =>
      _settings.put(_backupStateKey, jsonEncode(state.toJson()));

  // MERGE LOOKUPS (used by BackupService.mergeSnapshot; add-only, never
  // overwrite).
  bool hasTrip(String id) => _trips.containsKey(id);
  bool hasVehicle(String id) => _vehicles.containsKey(id);
  bool hasLocation(String id) => _locations.containsKey(id);
  bool hasPurpose(String id) => _purposes.containsKey(id);

  // PRIVACY
  Future<void> clearAllData() async {
    await _trips.clear();
    await _vehicles.clear();
    await _settings.clear();
    await _locations.clear();
    await _purposes.clear();
    await _seedDefaultsIfNeeded();
  }

  Future<Map<String, dynamic>> exportAllDataAsJson() async {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'MileMaid',
      'version': '1.0.0',
      'trips': getAllTrips().map((t) => t.toJson()).toList(),
      'vehicles': getAllVehicles().map((v) => v.toJson()).toList(),
      'locations': getAllLocations().map((l) => l.toJson()).toList(),
      'purposes': getAllPurposes().map((p) => p.toJson()).toList(),
      'settings': getSettings().toJson(),
    };
  }

  Future<void> close() => Hive.close();
}
