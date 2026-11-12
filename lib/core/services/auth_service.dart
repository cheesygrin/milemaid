import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:milemaid/core/config/backup_config.dart';
import 'package:milemaid/core/services/google_sign_in_bootstrap.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thin wrapper over FirebaseAuth for the app's login flows: Google Sign-In
/// and email/password. Emits no user-facing strings; the UI maps error codes.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authChanges() => _auth.authStateChanges();

  /// True when this build has a Google OAuth client ID, so the Google button
  /// can be shown and used.
  bool get googleConfigured => driveBackupConfigured;

  /// Google Sign-In via the shared GoogleSignIn singleton, then exchanged for
  /// a Firebase credential. Returns null corners as thrown [AuthException]s.
  Future<UserCredential> signInWithGoogle() async {
    if (!googleConfigured) {
      throw const AuthException('google-not-configured',
          'Google sign-in is not configured for this build.');
    }
    await ensureGoogleSignInInitialized();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } catch (e) {
      throw const AuthException('google-failed', 'Google sign-in did not complete.');
    }
    final auth = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
          'google-failed', 'Could not sign in with Google.');
    }
  }

  /// Native Sign in with Apple, exchanged for a Firebase credential.
  /// Apple only returns the name on the first authorization.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _randomNonce();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce),
      );
      final idToken = apple.identityToken;
      if (idToken == null) {
        throw const AuthException('apple-failed', 'Apple sign-in did not complete.');
      }
      final credential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final name = [
        apple.givenName,
        apple.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      final current = result.user?.displayName;
      if (name.isNotEmpty && (current == null || current.isEmpty)) {
        await result.user?.updateDisplayName(name);
      }
      return result;
    } on FirebaseAuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('canceled', 'Sign-in canceled.');
      }
      throw const AuthException('apple-failed', 'Apple sign-in did not complete.');
    } catch (_) {
      throw const AuthException('apple-failed', 'Could not sign in with Apple.');
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Deletes the Firebase account and that account's cloud trips.
  /// Trips stored only on this phone are left in place.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('no-user', 'No account is signed in.');
    }
    await TripSyncService.instance.deleteCloudData();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          'requires-recent-login',
          'For your security, sign out, sign in again, then delete the account.',
        );
      }
      rethrow;
    }
    await signOut();
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Maps a FirebaseAuthException to a short, user-readable message.
  static String friendlyMessage(Object error) {
    if (error is AuthException) return error.message;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Sign in instead.';
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with that email.';
        case 'operation-not-allowed':
          return 'That sign-in method is not enabled yet.';
        default:
          return 'Sign-in failed (${error.code}). Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);
  @override
  String toString() => message;
}
