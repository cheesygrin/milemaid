import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
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

  late Box<String> _trips;
  late Box<String> _vehicles;
  late Box<String> _settings;

  bool _initialized = false;

  /// Fired after any trip is saved, updated, or deleted. Wire UI refresh here.
  void Function()? onTripsChanged;

  Future<void> init() async {
    if (_initialized) return;

    _trips = await Hive.openBox<String>(_tripsBox);
    _vehicles = await Hive.openBox<String>(_vehiclesBox);
    _settings = await Hive.openBox<String>(_settingsBox);

    _initialized = true;
    await _seedDefaultsIfNeeded();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_vehicles.isEmpty) {
      final v = Vehicle(
        id: const Uuid().v4(),
        name: 'Primary Vehicle',
        makeModel: 'Your Car',
        year: DateTime.now().year,
        color: 'Silver',
      );
      await _vehicles.put(v.id, jsonEncode(v.toJson()));
    }
    if (_settings.isEmpty) {
      await _settings.put('main', jsonEncode(const UserSettings().toJson()));
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

  // PRIVACY
  Future<void> clearAllData() async {
    await _trips.clear();
    await _vehicles.clear();
    await _settings.clear();
    await _seedDefaultsIfNeeded();
  }

  Future<Map<String, dynamic>> exportAllDataAsJson() async {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'MileMaid',
      'version': '1.0.0',
      'trips': getAllTrips().map((t) => t.toJson()).toList(),
      'vehicles': getAllVehicles().map((v) => v.toJson()).toList(),
      'settings': getSettings().toJson(),
    };
  }

  Future<void> close() => Hive.close();
}
