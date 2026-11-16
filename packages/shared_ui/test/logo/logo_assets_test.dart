// ZOD-FND-008: the bundled logo marks are byte-for-byte the design
// reference's PNGs, recorded in SOURCES.md and declared as assets.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _dir = 'assets/logo';
const _reference = '../../design-reference/zodiann/assets';
const _files = ['zodiann-logo-on-dark.png', 'zodiann-logo-on-light.png'];

void main() {
  test('each bundled mark equals the design reference file byte for byte', () {
    for (final name in _files) {
      expect(
        File('$_dir/$name').readAsBytesSync(),
        File('$_reference/$name').readAsBytesSync(),
        reason: name,
      );
    }
  });

  test('SOURCES.md records the SHA-256 of each bundled mark', () {
    final rows = RegExp(
      r'^\|\s*`?(zodiann-logo-on-\w+\.png)`?\s*\|.*\b([0-9a-f]{64})\b',
      multiLine: true,
    ).allMatches(File('$_dir/SOURCES.md').readAsStringSync());
    final recorded = {for (final m in rows) m.group(1)!: m.group(2)!};
    expect(recorded.keys.toSet(), _files.toSet());
    for (final name in _files) {
      expect(
        sha256.convert(File('$_dir/$name').readAsBytesSync()).toString(),
        recorded[name],
        reason: name,
      );
    }
  });

  test('both marks are 1024 x 1024 RGBA PNGs', () {
    for (final name in _files) {
      final b = File('$_dir/$name').readAsBytesSync();
      final width = (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
      final height = (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23];
      expect((width, height), (1024, 1024), reason: name);
      expect(b[25], 6, reason: '$name colour type (RGBA)');
    }
  });

  test('both marks are declared as assets in pubspec.yaml', () {
    final flutter =
        loadYaml(File('pubspec.yaml').readAsStringSync())['flutter'] as YamlMap;
    final assets = (flutter['assets'] as YamlList).cast<String>();
    for (final name in _files) {
      expect(assets, contains('$_dir/$name'));
    }
  });
}
