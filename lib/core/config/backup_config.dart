/// Google Drive backup configuration.
///
/// Client IDs come from compile-time defines so that the public repo never
/// contains real credentials (see AGENTS.md). Build with:
///   flutter build ios --dart-define-from-file=config/secrets.json
/// where config/secrets.json (gitignored) holds {"GOOGLE_IOS_CLIENT_ID": "..."}.
/// iOS additionally reads GOOGLE_IOS_CLIENT_ID / GOOGLE_REVERSED_CLIENT_ID from
/// ios/Flutter/Secrets.xcconfig (gitignored; see Secrets.example.xcconfig).
const String kGoogleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// True when this build was compiled with a Google OAuth client ID. When
/// false, all backup features are inert and Settings shows "not configured".
bool get driveBackupConfigured => kGoogleIosClientId.isNotEmpty;
