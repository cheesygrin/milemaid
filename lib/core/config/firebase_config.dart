import 'package:firebase_core/firebase_core.dart';

/// Firebase options from compile-time defines supplied by
/// config/secrets.json (gitignored; see config/secrets.example.json). Keeping
/// the real API key out of the repo, consistent with the OAuth client IDs.
final FirebaseOptions kFirebaseOptions = FirebaseOptions(
  apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
  appId: const String.fromEnvironment('FIREBASE_APP_ID'),
  messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
  iosBundleId: 'com.zerodelta.milemaid',
);
