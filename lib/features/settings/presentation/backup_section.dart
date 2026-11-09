import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:milemaid/core/config/backup_config.dart';
import 'package:milemaid/core/models/backup_state.dart';
import 'package:milemaid/core/services/backup_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/drive_backup_store.dart';

/// Settings section for Google Drive backup. Everything is inert (one line)
/// when the build has no client ID compiled in.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  BackupState _state() => DatabaseService().getBackupState();

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('Backup error: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _guard(() async {
        final email = await GoogleDriveAuth.instance.connect();
        final db = DatabaseService();
        final state = db.getBackupState();
        state.accountEmail = email;
        state.needsReconnect = false;
        state.lastError = null;
        await db.saveBackupState(state);
        _snack('Connected to Google Drive ($email)');
      });

  Future<void> _backUpNow() => _guard(() async {
        await BackupService.instance.backupNow();
        final state = _state();
        if (state.lastError != null) {
          _snack('Backup failed: ${state.lastError}', error: true);
        } else {
          _snack('Backup complete.');
        }
      });

  Future<void> _restore() => _guard(() async {
        final auth = GoogleDriveAuth.instance;
        final client = await auth.silentClient();
        if (client == null) {
          _snack('Reconnect needed: sign in again to restore.', error: true);
          return;
        }
        final store = DriveBackupStore(drive.DriveApi(client));
        final files = await store.list();
        if (!mounted) return;
        if (files.isEmpty) {
          _snack('No backups found in Google Drive yet.');
          return;
        }
        final picked = await showDialog<BackupFile>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Restore from Drive'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final day = file.modifiedTime == null
                      ? file.name
                      : DateFormat('EEE, MMM d yyyy – jm')
                          .format(file.modifiedTime!);
                  return ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(day),
                    onTap: () => Navigator.pop(dialogContext, file),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        if (picked == null || !mounted) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Restore ${picked.name}?'),
            content: const Text(
                'Adds drives that are missing on this phone. Nothing on the '
                'phone is changed or deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;

        final result = await BackupService.instance.restoreFrom(store, picked);
        _snack(
          'Restored: ${result.tripsAdded} trips, ${result.vehiclesAdded} '
          'vehicles, ${result.placesAdded} places, ${result.purposesAdded} '
          'purposes added.',
        );
      });

  Future<void> _disconnect() => _guard(() async {
        await GoogleDriveAuth.instance.disconnect();
        final db = DatabaseService();
        final state = db.getBackupState();
        state.reset();
        await db.saveBackupState(state);
        _snack('Disconnected from Google Drive.');
      });

  @override
  Widget build(BuildContext context) {
    if (!driveBackupConfigured) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Google Drive backup isn\'t set up in this build.'),
      );
    }

    final state = _state();
    final statusText = state.needsReconnect
        ? 'Reconnect needed'
        : state.lastSuccessAt == null
            ? 'Not connected'
            : 'Backed up ${DateFormat.jm().format(state.lastSuccessAt!)}'
                ' to ${state.accountEmail ?? 'Google Drive'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text('Backup',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(statusText),
          subtitle: state.lastError != null
              ? Text(state.lastError!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _connect,
                child: const Text('Connect Google Drive'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _backUpNow,
                child: const Text('Back up now'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore from Drive'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _disconnect,
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
