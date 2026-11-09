import 'dart:async';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:milemaid/core/config/backup_config.dart';
import 'package:milemaid/core/models/backup_state.dart';

/// Folder all MileMaid backups live in, inside the user's My Drive. Because
/// the app only asks for the drive.file scope, it can only ever see files it
/// created itself.
const String kBackupFolderName = 'MileMaid Backups';

/// [BackupStore] backed by a [drive.DriveApi]. One folder in My Drive; a
/// backup file is updated in place (same name -> same file) so old versions
/// are not piled up.
class DriveBackupStore implements BackupStore {
  DriveBackupStore(this._api);

  final drive.DriveApi _api;

  static const String _folderMimeType = 'application/vnd.google-apps.folder';
  static const String _jsonMimeType = 'application/json';

  Future<String?> _findFolderId() async {
    final result = await _api.files.list(
      q: "mimeType='$_folderMimeType' and name='$kBackupFolderName' "
          'and trashed=false',
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  Future<String> _ensureFolderId() async {
    final existing = await _findFolderId();
    if (existing != null) return existing;
    final created = await _api.files.create(drive.File(name: kBackupFolderName));
    return created.id!;
  }

  Future<drive.File?> _findFile(String name, String folderId) async {
    final result = await _api.files.list(
      q: "'$folderId' in parents and name='$name' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  @override
  Future<void> upload(String name, List<int> bytes) async {
    final folderId = await _ensureFolderId();
    final existing = await _findFile(name, folderId);
    final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);
    if (existing?.id != null) {
      // Update the existing file in place (metadata-only body, media upload).
      await _api.files.update(
        drive.File(mimeType: _jsonMimeType),
        existing!.id!,
        uploadMedia: media,
      );
    } else {
      await _api.files.create(
        drive.File(name: name, parents: [folderId], mimeType: _jsonMimeType),
        uploadMedia: media,
      );
    }
  }

  @override
  Future<List<BackupFile>> list() async {
    final folderId = await _ensureFolderId();
    final result = await _api.files.list(
      q: "'$folderId' in parents and mimeType='$_jsonMimeType' "
          'and trashed=false',
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name, modifiedTime, size)',
    );
    return (result.files ?? const [])
        .map((f) => BackupFile(
              id: f.id!,
              name: f.name ?? 'unnamed',
              modifiedTime: f.modifiedTime,
              // Drive reports int64 sizes as strings.
              sizeBytes: f.size == null ? null : int.tryParse(f.size!),
            ))
        .toList();
  }

  @override
  Future<List<int>> download(String id) async {
    final media = await _api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

/// Sign-in + authorization for Drive backups on top of google_sign_in 7.x.
///
/// Tokens are never logged or stored anywhere — they live only inside the
/// plugin and the short-lived AuthClient returned here.
class GoogleDriveAuth {
  static final GoogleDriveAuth instance = GoogleDriveAuth._internal();

  GoogleDriveAuth._internal();

  bool _initialized = false;

  /// Email of the last successfully connected/silently signed-in account.
  /// Not a credential, just a display string for Settings.
  String? lastAccountEmail;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!driveBackupConfigured) {
      throw StateError(
          'Google Drive backup is not configured in this build.');
    }
    await GoogleSignIn.instance.initialize(clientId: kGoogleIosClientId);
    _initialized = true;
  }

  /// Interactive sign-in: authenticate, then authorize the Drive scope.
  /// Returns the account email.
  Future<String> connect() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: [drive.DriveApi.driveFileScope],
    );
    await account.authorizationClient
        .authorizeScopes([drive.DriveApi.driveFileScope]);
    lastAccountEmail = account.email;
    return account.email;
  }

  /// Silent (no UI) attempt to get a Drive-authorized client. Returns null
  /// when the user is not signed in or has not granted the scope — Settings
  /// then shows "Reconnect needed".
  Future<gapis.AuthClient?> silentClient() async {
    if (!driveBackupConfigured) return null; // never touches the plugin
    await _ensureInitialized();
    final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = attempt == null ? null : await attempt;
    if (account == null) return null;
    final authorization = await account.authorizationClient
        .authorizationForScopes([drive.DriveApi.driveFileScope]);
    if (authorization == null) return null;
    lastAccountEmail = account.email;
    return authorization.authClient(scopes: [drive.DriveApi.driveFileScope]);
  }

  /// Revokes authorization and signs out.
  Future<void> disconnect() async {
    if (!driveBackupConfigured) return; // never touches the plugin
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
    lastAccountEmail = null;
  }
}
