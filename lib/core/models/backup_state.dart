/// Backup/restore state kept under the key `backup_state` in the settings
/// Hive box (see DatabaseService). Deliberately NOT part of the freezed
/// [UserSettings] — it is service bookkeeping, not user preferences.
class BackupState {
  BackupState({
    this.lastSuccessAt,
    this.lastAttemptAt,
    this.lastError,
    this.accountEmail,
    this.needsReconnect = false,
  });

  factory BackupState.fromJson(Map<String, dynamic> json) {
    return BackupState(
      lastSuccessAt: _parseDate(json['lastSuccessAt']),
      lastAttemptAt: _parseDate(json['lastAttemptAt']),
      lastError: json['lastError'] as String?,
      accountEmail: json['accountEmail'] as String?,
      needsReconnect: (json['needsReconnect'] as bool?) ?? false,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw is String && raw.isNotEmpty ? DateTime.parse(raw) : null;

  /// Last time a backup upload fully succeeded (null = never).
  DateTime? lastSuccessAt;

  /// Last time an automatic or manual backup was attempted, success or not.
  DateTime? lastAttemptAt;

  /// Human-readable description of the last failure, null after a success.
  String? lastError;

  /// Google account the backups go to, for display in Settings. Never a token.
  String? accountEmail;

  /// True when Drive says the user must re-authorize (silent sign-in failed).
  bool needsReconnect;

  Map<String, dynamic> toJson() => {
        'lastSuccessAt': lastSuccessAt?.toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'lastError': lastError,
        'accountEmail': accountEmail,
        'needsReconnect': needsReconnect,
      };

  /// Fresh state, e.g. after disconnecting.
  void reset({String? accountEmail}) {
    lastSuccessAt = null;
    lastAttemptAt = null;
    lastError = null;
    this.accountEmail = accountEmail;
    needsReconnect = false;
  }
}

/// One file as reported by a [BackupStore].
class BackupFile {
  const BackupFile({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? sizeBytes;
}

/// Abstraction over the remote backup destination so all of BackupService's
/// logic is testable with no network (see test/backup_test.dart).
abstract class BackupStore {
  /// Creates or updates the file [name] with [bytes] (an overwrite, not a copy).
  Future<void> upload(String name, List<int> bytes);

  /// All backup files, newest first.
  Future<List<BackupFile>> list();

  /// Full contents of the file with the given id.
  Future<List<int>> download(String id);
}

/// Result of merging a downloaded snapshot into local data.
class MergeResult {
  const MergeResult({
    required this.tripsAdded,
    required this.vehiclesAdded,
    required this.placesAdded,
    required this.purposesAdded,
  });

  final int tripsAdded;
  final int vehiclesAdded;
  final int placesAdded;
  final int purposesAdded;

  @override
  String toString() =>
      'MergeResult(trips: $tripsAdded, vehicles: $vehiclesAdded, '
      'places: $placesAdded, purposes: $purposesAdded)';
}
