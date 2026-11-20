// ZOD-FND-003: the vendored Swiss Ephemeris source, licence files and data
// subset are byte-for-byte the upstream files (AGPL path, ZOD-FND-010 and
// ZOD-FND-015: notices and files stay unchanged). Runs from the workspace root
// on every `melos run test`, including the Windows job, where git checks text
// files out with CRLF unless the scoped `.gitattributes` says `-text`.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _manifestPath = 'native/swisseph/MANIFEST.json';
const _vendoredNote = 'native/swisseph/VENDORED.md';
const _upstreamDir = 'native/swisseph/upstream';

Map<String, Object?> _loadManifest() =>
    jsonDecode(File(_manifestPath).readAsStringSync()) as Map<String, Object?>;

/// The git blob id of [bytes]: sha1 of `blob <length>\0` followed by the bytes.
String gitBlobSha1(List<int> bytes) => sha1.convert([
  ...utf8.encode('blob ${bytes.length}\u0000'),
  ...bytes,
]).toString();

void main() {
  late Map<String, Object?> manifest;
  late List<Map<String, Object?>> files;

  setUpAll(() {
    manifest = _loadManifest();
    files = (manifest['files']! as List<Object?>).cast<Map<String, Object?>>();
  });

  test('the manifest names the upstream tag and commit', () {
    expect(manifest['upstreamTag'], 'v2.10.3bfinal');
    expect(
      manifest['upstreamCommit'],
      'f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0',
    );
  });

  test(
    'every manifest file exists and matches its upstream blob and SHA-256',
    () {
      expect(files, isNotEmpty);
      for (final entry in files) {
        final path = entry['path']! as String;
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is missing');
        final bytes = file.readAsBytesSync();
        expect(
          gitBlobSha1(bytes),
          entry['blobSha1'],
          reason: '$path differs from the upstream git blob (line endings?)',
        );
        expect(
          sha256.convert(bytes).toString(),
          entry['sha256'],
          reason: '$path differs from its recorded SHA-256',
        );
      }
    },
  );

  test('no file under upstream/ is missing from the manifest', () {
    final listed = {for (final e in files) e['path']! as String};
    final onDisk = Directory(_upstreamDir)
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toSet();
    expect(onDisk.difference(listed), isEmpty);
  });

  test('the licence and copyright files are present', () {
    for (final name in [
      'LICENSE',
      'LICENSE.TXT',
      'agpl-3.0.txt',
      'readme.md',
    ]) {
      expect(
        File('$_upstreamDir/$name').existsSync(),
        isTrue,
        reason: '$name must be vendored unchanged',
      );
    }
  });

  test('LICENSE has the SHA-256 recorded in the inventory by ZOD-FND-015', () {
    final digest = sha256
        .convert(File('$_upstreamDir/LICENSE').readAsBytesSync())
        .toString();
    expect(digest, startsWith('b6345743292c'));
  });

  test('VENDORED.md names the tag and the commit', () {
    final text = File(_vendoredNote).readAsStringSync();
    expect(text, contains('v2.10.3bfinal'));
    expect(text, contains('f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0'));
  });
}
