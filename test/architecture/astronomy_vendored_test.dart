// ZOD-EPH-004: the vendored astronomy-engine C source and its licence are
// byte-for-byte the upstream files (MIT; the licence text must stay with the
// source). Runs from the workspace root on every `melos run test`, including
// the Windows job, where git checks text files out with CRLF unless the scoped
// `.gitattributes` says `-text`.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _manifestPath = 'native/astronomy_c/MANIFEST.json';
const _vendoredNote = 'native/astronomy_c/VENDORED.md';
const _upstreamDir = 'native/astronomy_c/upstream';

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
    expect(manifest['upstreamTag'], 'v2.1.19');
    expect(
      manifest['upstreamCommit'],
      '61dc07020aaa6885d2c7f688a4d82beaf6edb9ef',
    );
  });

  test('the manifest lists exactly the three vendored files', () {
    expect(
      {for (final e in files) e['path']! as String},
      {
        'native/astronomy_c/upstream/astronomy.c',
        'native/astronomy_c/upstream/astronomy.h',
        'native/astronomy_c/upstream/LICENSE',
      },
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

  test('the MIT licence text is vendored with the source', () {
    final text = File('$_upstreamDir/LICENSE').readAsStringSync();
    expect(text, contains('MIT License'));
    expect(text, contains('Don Cross'));
    expect(
      text,
      contains(
        'The above copyright notice and this permission notice shall be '
        'included in all',
      ),
    );
  });

  test('VENDORED.md names the tag and the commit', () {
    final text = File(_vendoredNote).readAsStringSync();
    expect(text, contains('v2.1.19'));
    expect(text, contains('61dc07020aaa6885d2c7f688a4d82beaf6edb9ef'));
  });
}
