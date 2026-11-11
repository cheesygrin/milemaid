import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';

/// Syncs trips between the local Hive store and the signed-in user's Firestore
/// documents (users/{uid}/trips/{id}).
///
/// Local is the source of truth for writes: every local mutation is mirrored
/// up. On sign-in we pull-and-merge (add-only, never overwrite) so a fresh or
/// wiped device is restored from the cloud. Sync is best-effort and never
/// throws into the caller.
class TripSyncService {
  TripSyncService._();
  static final TripSyncService instance = TripSyncService._();

  CollectionReference<Map<String, dynamic>> _tripsRef(User user) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trips');

  bool get available => FirebaseAuth.instance.currentUser != null;

  Future<void> upsert(Trip trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _tripsRef(user).doc(trip.id).set(trip.toJson());
    } catch (_) {
      // Network/perms failure must not break the local write.
    }
  }

  Future<void> remove(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _tripsRef(user).doc(id).delete();
    } catch (_) {}
  }

  /// Pulls the user's cloud trips and imports any that are missing locally.
  /// Returns the number of trips restored.
  Future<int> pullAndMerge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snap = await _tripsRef(user).get();
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
}
