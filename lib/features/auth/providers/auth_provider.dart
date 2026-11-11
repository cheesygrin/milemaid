import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/services/auth_service.dart';

/// Reactive view of the signed-in Firebase user (null when logged out).
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authChanges();
});
