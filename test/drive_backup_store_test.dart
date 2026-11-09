import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:milemaid/core/services/drive_backup_store.dart';

/// No network and no client ID: [DriveBackupStore] is exercised over a
/// [drive.DriveApi] built on a package:http [MockClient]. All data is made up
/// (generic names, fake ids) per AGENTS.md.
class _Call {
  final String method;
  final Uri url;
  final String body;

  _Call(this.method, this.url, this.body);
}

/// Minimal in-memory fake of the Drive v3 HTTP API, tracking every request
/// the store makes.
class _FakeDrive {
  final List<_Call> calls = [];

  bool folderExists = false;
  bool fileExists = false;

  String folderId = 'folder-111';
  String fileId = 'file-222';

  http.Client client() => MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    calls.add(_Call(request.method, request.url, request.body));
    final path = request.url.path;
    final responseHeaders = {
      'content-type': 'application/json; charset=utf-8',
    };

    if (request.method == 'GET' && path == '/drive/v3/files') {
      final q = request.url.queryParameters['q'] ?? '';
      final body = q.contains('google-apps.folder')
          ? (folderExists
              ? {
                  'files': [
                    {'id': folderId, 'name': kBackupFolderName},
                  ],
                }
              : const {'files': []})
          : (fileExists
              ? {
                  'files': [
                    {'id': fileId, 'name': 'milemaid-backup-2026-11-09.json'},
                  ],
                }
              : const {'files': []});
      return http.Response(jsonEncode(body), 200, headers: responseHeaders);
    }

    // Folder create: metadata-only JSON POST to /drive/v3/files.
    if (request.method == 'POST' && path == '/drive/v3/files') {
      folderExists = true;
      return http.Response(
        jsonEncode({'id': folderId, 'name': kBackupFolderName}),
        200,
        headers: responseHeaders,
      );
    }

    // Backup file create: multipart POST to /upload/drive/v3/files.
    if (request.method == 'POST' && path == '/upload/drive/v3/files') {
      fileExists = true;
      return http.Response(
        jsonEncode({'id': fileId, 'name': 'milemaid-backup-2026-11-09.json'}),
        200,
        headers: responseHeaders,
      );
    }

    // Backup file update: multipart PATCH to /upload/drive/v3/files/{id}.
    if (request.method == 'PATCH' && path == '/upload/drive/v3/files/$fileId') {
      return http.Response(
        jsonEncode({'id': fileId, 'name': 'milemaid-backup-2026-11-09.json'}),
        200,
        headers: responseHeaders,
      );
    }

    fail('Unexpected ${request.method} $path in test fake');
  }

  List<_Call> callsSince(int mark) => calls.sublist(mark);
}

/// The JSON metadata part of a multipart/related upload body.
Map<String, dynamic> _multipartMetadata(_Call call) {
  final match = RegExp(
    r'Content-Type: application/json[^\r\n]*\r\n\r\n(.+?)\r\n--',
    dotAll: true,
  ).firstMatch(call.body);
  expect(match, isNotNull,
      reason: 'no JSON metadata part in multipart body:\n${call.body}');
  return jsonDecode(match!.group(1)!) as Map<String, dynamic>;
}

void main() {
  late _FakeDrive fake;
  late DriveBackupStore store;

  setUp(() {
    fake = _FakeDrive();
    store = DriveBackupStore(drive.DriveApi(fake.client()));
  });

  group('folder creation', () {
    test('creates "MileMaid Backups" as a real folder (mimeType set)',
        () async {
      await store.upload(
        'milemaid-backup-2026-11-09.json',
        utf8.encode('{"app":"MileMaid"}'),
      );

      final folderCreates = fake.calls
          .where((c) => c.method == 'POST' && c.url.path == '/drive/v3/files')
          .toList();
      expect(folderCreates, hasLength(1), reason: 'exactly one folder create');
      final metadata = jsonDecode(folderCreates.single.body)
          as Map<String, dynamic>;
      expect(metadata['name'], 'MileMaid Backups');
      // R1: without this the "folder" is a plain file and every upload fails
      // because its parent is not a folder.
      expect(metadata['mimeType'], 'application/vnd.google-apps.folder');
    });

    test('does not create the folder when it already exists', () async {
      fake.folderExists = true;
      await store.upload(
        'milemaid-backup-2026-11-09.json',
        utf8.encode('{"app":"MileMaid"}'),
      );

      expect(
        fake.calls.where((c) =>
            c.method == 'POST' && c.url.path == '/drive/v3/files'),
        isEmpty,
      );
    });
  });

  group('upload', () {
    test('file create is multipart and sends parents = the folder id',
        () async {
      await store.upload(
        'milemaid-backup-2026-11-09.json',
        utf8.encode('{"app":"MileMaid"}'),
      );

      final creates = fake.calls
          .where((c) =>
              c.method == 'POST' && c.url.path == '/upload/drive/v3/files')
          .toList();
      expect(creates, hasLength(1));
      final create = creates.single;
      expect(create.url.queryParameters['uploadType'], 'multipart');

      final metadata = _multipartMetadata(create);
      expect(metadata['name'], 'milemaid-backup-2026-11-09.json');
      expect(metadata['parents'], [fake.folderId]);
    });

    test('a second upload of the same name issues an update, not a create',
        () async {
      await store.upload(
        'milemaid-backup-2026-11-09.json',
        utf8.encode('{"app":"MileMaid","v":1}'),
      );
      final afterFirst = fake.calls.length;

      await store.upload(
        'milemaid-backup-2026-11-09.json',
        utf8.encode('{"app":"MileMaid","v":2}'),
      );
      final second = fake.callsSince(afterFirst);

      expect(second.any((c) => c.method == 'POST'), isFalse,
          reason: 'the second upload must not create anything');
      final updates =
          second.where((c) => c.method == 'PATCH').toList();
      expect(updates, hasLength(1));
      final update = updates.single;
      expect(update.url.path, '/upload/drive/v3/files/${fake.fileId}');
      expect(update.url.queryParameters['uploadType'], 'multipart');
      expect(_multipartMetadata(update)['name'], isNull,
          reason: 'the name is unchanged; update sends metadata only');
    });
  });

  group('list', () {
    test('queries the folder id, newest first, and maps the result',
        () async {
      fake.folderExists = true;
      fake.fileExists = true;

      final files = await store.list();

      final lists = fake.calls
          .where((c) => c.method == 'GET' && c.url.path == '/drive/v3/files')
          .toList();
      // First the folder lookup, then the actual listing.
      expect(lists, hasLength(2));

      final folderSearch = lists.first.url.queryParameters['q'];
      expect(folderSearch, contains("mimeType='application/vnd.google-apps.folder'"));
      expect(folderSearch, contains("name='MileMaid Backups'"));

      final listing = lists.last;
      final q = listing.url.queryParameters['q'];
      expect(q, contains("'${fake.folderId}' in parents"));
      expect(q, contains("mimeType='application/json'"));
      expect(q, contains('trashed=false'));
      expect(listing.url.queryParameters['orderBy'], 'modifiedTime desc');
      expect(listing.url.queryParameters['spaces'], 'drive');

      expect(files, hasLength(1));
      expect(files.single.id, fake.fileId);
      expect(files.single.name, 'milemaid-backup-2026-11-09.json');
    });

    test('returns an empty list for a fresh Drive', () async {
      expect(await store.list(), isEmpty);
    });
  });
}
