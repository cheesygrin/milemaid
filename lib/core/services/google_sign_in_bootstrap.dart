import 'package:google_sign_in/google_sign_in.dart';
import 'package:milemaid/core/config/backup_config.dart';

bool _initialized = false;

/// Initializes the shared [GoogleSignIn.instance] exactly once, guarded so the
/// login flow and the Drive-backup flow can both use the singleton without
/// tripping over a double `initialize()`.
Future<void> ensureGoogleSignInInitialized() async {
  if (_initialized) return;
  if (!driveBackupConfigured) return;
  await GoogleSignIn.instance.initialize(clientId: kGoogleIosClientId);
  _initialized = true;
}
