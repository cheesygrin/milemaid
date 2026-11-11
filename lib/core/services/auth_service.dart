import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:milemaid/core/config/backup_config.dart';
import 'package:milemaid/core/services/google_sign_in_bootstrap.dart';

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

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() async {
    await _auth.signOut();
  }

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
          return 'Sign-in failed. Please try again.';
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
