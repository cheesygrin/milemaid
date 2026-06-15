import 'package:milemaid/core/models/user_settings.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  final DatabaseService _db = DatabaseService();

  @override
  UserSettings build() => _db.getSettings();

  Future<void> update(UserSettings newSettings) async {
    final saved = await _db.updateSettings(newSettings);
    state = saved;
  }

  Future<void> setRate(double rate) async {
    final updated = state.copyWith(mileageRate: rate);
    await update(updated);
  }

  Future<void> setSensitivity(String sensitivity) async {
    final updated = state.copyWith(trackingSensitivity: sensitivity);
    await update(updated);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    await update(updated);
  }

  /// For development and early testing only. In production this will be driven by
  /// successful in-app purchase / subscription validation (e.g. via RevenueCat).
  Future<void> setProStatus(bool isPro) async {
    final updated = state.copyWith(isPro: isPro);
    await update(updated);
  }

  Future<void> setThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    await update(updated);
  }
}

@riverpod
class Vehicles extends _$Vehicles {
  final DatabaseService _db = DatabaseService();

  @override
  List<Vehicle> build() => _db.getAllVehicles();

  Future<void> refresh() async {
    state = _db.getAllVehicles();
  }

  Future<Vehicle> addVehicle(Vehicle v) async {
    final saved = await _db.saveVehicle(v);
    state = _db.getAllVehicles();
    return saved;
  }

  Future<void> deleteVehicle(String id) async {
    await _db.deleteVehicle(id);
    state = _db.getAllVehicles();
  }
}
