import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/core/services/database_service.dart';

/// What one pull should change on this phone for a single collection.
class MergePlan<T> {
  const MergePlan({required this.toAdd, required this.toDrop});

  /// Cloud items this phone does not have yet.
  final List<T> toAdd;

  /// Local starter items to remove because the account has its own list.
  final List<T> toDrop;
}

/// Add-only merge: cloud items missing locally are added, and nothing the
/// user made is ever removed.
///
/// Every fresh install seeds starter data with new random ids. Without
/// [isUntouchedDefault], signing in on a second phone would add those starters
/// next to the account's real list, and then upload them as duplicates. So a
/// local item that is still an untouched starter is dropped, but only when the
/// account already has at least one item of that kind.
MergePlan<T> planMerge<T>({
  required List<T> local,
  required List<T> cloud,
  required String Function(T item) idOf,
  bool Function(T item)? isUntouchedDefault,
}) {
  final localIds = local.map(idOf).toSet();
  final cloudIds = cloud.map(idOf).toSet();
  final toAdd = cloud.where((c) => !localIds.contains(idOf(c))).toList();
  final toDrop = cloud.isEmpty || isUntouchedDefault == null
      ? <T>[]
      : local
          .where((l) => !cloudIds.contains(idOf(l)) && isUntouchedDefault(l))
          .toList();
  return MergePlan(toAdd: toAdd, toDrop: toDrop);
}

/// Syncs trips, vehicles, saved places and trip purposes between the local
/// Hive store and the signed-in user's Firestore documents
/// (users/{uid}/{trips|vehicles|places|purposes}/{id}).
///
/// Local is the source of truth for writes: every local mutation is mirrored
/// up. On sign-in we pull-and-merge (add-only, never overwrite) so a fresh or
/// wiped device is restored from the cloud. Sync is best-effort and never
/// throws into the caller.
class TripSyncService {
  TripSyncService._();
  static final TripSyncService instance = TripSyncService._();

  static const String _trips = 'trips';
  static const String _vehicles = 'vehicles';
  static const String _places = 'places';
  static const String _purposes = 'purposes';
  static const List<String> _allCollections = [
    _trips,
    _vehicles,
    _places,
    _purposes,
  ];

  CollectionReference<Map<String, dynamic>> _ref(User user, String name) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(name);

  bool get available => _currentUser != null;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase isn't configured in unit tests and some builds.
      return null;
    }
  }

  Future<void> _set(String collection, String id, Map<String, dynamic> json) async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _ref(user, collection).doc(id).set(json);
    } catch (_) {
      // Network/perms failure must not break the local write.
    }
  }

  Future<void> _delete(String collection, String id) async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _ref(user, collection).doc(id).delete();
    } catch (_) {}
  }

  Future<void> upsert(Trip trip) => _set(_trips, trip.id, trip.toJson());
  Future<void> remove(String id) => _delete(_trips, id);

  Future<void> upsertVehicle(Vehicle v) => _set(_vehicles, v.id, v.toJson());
  Future<void> removeVehicle(String id) => _delete(_vehicles, id);

  Future<void> upsertPlace(NamedLocation p) => _set(_places, p.id, p.toJson());
  Future<void> removePlace(String id) => _delete(_places, id);

  Future<void> upsertPurpose(PurposePreset p) => _set(_purposes, p.id, p.toJson());
  Future<void> removePurpose(String id) => _delete(_purposes, id);

  /// Uploads everything stored on this phone. Covers drives recorded before
  /// sign-in and automatic drives that were saved outside the trips screen.
  ///
  /// Pass `extras: false` to upload trips only (used when the account's
  /// vehicles, places and purposes could not be read first, so starter data
  /// is not uploaded on top of them).
  Future<void> pushAllLocal({bool extras = true}) async {
    if (_currentUser == null) return;
    final db = DatabaseService();
    for (final trip in db.getAllTrips()) {
      await upsert(trip);
    }
    if (!extras) return;
    for (final v in db.getAllVehicles()) {
      await upsertVehicle(v);
    }
    for (final p in db.getAllLocations()) {
      await upsertPlace(p);
    }
    for (final p in db.getAllPurposes()) {
      await upsertPurpose(p);
    }
  }

  /// Pull what this phone doesn't have, then upload what the cloud doesn't
  /// have. Returns how many trips were restored.
  Future<int> syncOnSignIn() async {
    var restored = 0;
    try {
      restored = await pullAndMerge();
    } catch (_) {}
    var extrasPulled = false;
    try {
      await _pullExtras();
      extrasPulled = true;
    } catch (_) {}
    await pushAllLocal(extras: extrasPulled);
    return restored;
  }

  /// Deletes everything the signed-in user has in the cloud. Used by account
  /// deletion.
  Future<void> deleteCloudData() async {
    final user = _currentUser;
    if (user == null) return;
    for (final name in _allCollections) {
      final ref = _ref(user, name);
      while (true) {
        final snap = await ref.limit(400).get();
        if (snap.docs.isEmpty) break;
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
  }

  /// Pulls the user's cloud trips and imports any that are missing locally.
  /// Returns the number of trips restored.
  Future<int> pullAndMerge() async {
    final user = _currentUser;
    if (user == null) return 0;
    final snap = await _ref(user, _trips).get();
    final db = DatabaseService();
    var added = 0;
    for (final doc in snap.docs) {
      try {
        final trip = Trip.fromJson(doc.data());
        if (!db.hasTrip(trip.id)) {
          await db.saveTrip(trip);
          added++;
        }
      } catch (_) {
        // Skip malformed docs rather than failing the whole pull.
      }
    }
    return added;
  }

  /// Reads one collection, skipping documents that fail to parse.
  Future<List<T>> _fetch<T>(
    User user,
    String collection,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final snap = await _ref(user, collection).get();
    final items = <T>[];
    for (final doc in snap.docs) {
      try {
        items.add(fromJson(doc.data()));
      } catch (_) {}
    }
    return items;
  }

  /// Pulls vehicles, places and purposes. Throws if the cloud cannot be read,
  /// so the caller knows not to upload local starter data over it.
  Future<void> _pullExtras() async {
    final user = _currentUser;
    if (user == null) return;
    final db = DatabaseService();

    final cloudVehicles = await _fetch(user, _vehicles, Vehicle.fromJson);
    final cloudPlaces = await _fetch(user, _places, NamedLocation.fromJson);
    final cloudPurposes = await _fetch(user, _purposes, PurposePreset.fromJson);

    final usedVehicleIds = {
      for (final t in db.getAllTrips())
        if (t.vehicleId != null) t.vehicleId!,
      db.getSettings().defaultVehicleId,
    };
    final vehicles = planMerge<Vehicle>(
      local: db.getAllVehicles(),
      cloud: cloudVehicles,
      idOf: (v) => v.id,
      isUntouchedDefault: (v) =>
          v.name == DatabaseService.defaultVehicleName &&
          v.makeModel == DatabaseService.defaultVehicleMakeModel &&
          v.licensePlate == null &&
          v.customRatePerMile == null &&
          !usedVehicleIds.contains(v.id),
    );
    for (final v in vehicles.toDrop) {
      await db.deleteVehicle(v.id);
    }
    for (final v in vehicles.toAdd) {
      await db.saveVehicle(v);
    }

    final places = planMerge<NamedLocation>(
      local: db.getAllLocations(),
      cloud: cloudPlaces,
      idOf: (p) => p.id,
    );
    for (final p in places.toAdd) {
      await db.saveLocation(p);
    }

    final purposes = planMerge<PurposePreset>(
      local: db.getAllPurposes(),
      cloud: cloudPurposes,
      idOf: (p) => p.id,
      isUntouchedDefault: (p) => DatabaseService.defaultPurposes
          .any((d) => d.$1 == p.name && d.$2 == p.category),
    );
    for (final p in purposes.toDrop) {
      await db.deletePurpose(p.id);
    }
    for (final p in purposes.toAdd) {
      await db.savePurpose(p);
    }
  }
}
