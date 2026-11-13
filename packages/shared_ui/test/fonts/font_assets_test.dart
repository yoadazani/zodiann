// ZOD-FND-007: the bundled font files are registered exactly, at the weights
// their own OS/2 tables declare, under their own family names, byte-for-byte
// as recorded in SOURCES.md, and with their OFL licence shipped as an asset.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:yaml/yaml.dart';

import '../support/sfnt.dart';

const _dir = 'assets/fonts';

/// family → {asset path → weight}
const _expected = <String, Map<String, int>>{
  ZodiannFonts.plexSans: {
    '$_dir/ibm-plex-sans/IBMPlexSans-Light.ttf': 300,
    '$_dir/ibm-plex-sans/IBMPlexSans-Regular.ttf': 400,
    '$_dir/ibm-plex-sans/IBMPlexSans-Medium.ttf': 500,
    '$_dir/ibm-plex-sans/IBMPlexSans-SemiBold.ttf': 600,
  },
  ZodiannFonts.plexSansHebrew: {
    '$_dir/ibm-plex-sans-hebrew/IBMPlexSansHebrew-Light.ttf': 300,
    '$_dir/ibm-plex-sans-hebrew/IBMPlexSansHebrew-Regular.ttf': 400,
    '$_dir/ibm-plex-sans-hebrew/IBMPlexSansHebrew-Medium.ttf': 500,
    '$_dir/ibm-plex-sans-hebrew/IBMPlexSansHebrew-SemiBold.ttf': 600,
  },
  ZodiannFonts.notoSansSymbols: {
    '$_dir/noto-sans-symbols/NotoSansSymbols-Regular.ttf': 400,
  },
  ZodiannFonts.notoSansSymbols2: {
    '$_dir/noto-sans-symbols-2/NotoSansSymbols2-Regular.ttf': 400,
  },
  ZodiannFonts.notoSans: {'$_dir/noto-sans/NotoSans-Regular.ttf': 400},
};

const _licences = [
  '$_dir/ibm-plex-sans/OFL.txt',
  '$_dir/ibm-plex-sans-hebrew/OFL.txt',
  '$_dir/noto-sans-symbols/OFL.txt',
  '$_dir/noto-sans-symbols-2/OFL.txt',
  '$_dir/noto-sans/OFL.txt',
];

YamlMap _flutterSection() =>
    (loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap)['flutter']
        as YamlMap;

Iterable<(String, String, int)> _assets() sync* {
  for (final MapEntry(key: family, value: files) in _expected.entries) {
    for (final MapEntry(key: asset, value: weight) in files.entries) {
      yield (family, asset, weight);
    }
  }
}

void main() {
  test('the pubspec registers exactly these families, files and weights', () {
    final fonts = _flutterSection()['fonts'] as YamlList;
    final registered = {
      for (final f in fonts.cast<YamlMap>())
        f['family'] as String: {
          for (final a in (f['fonts'] as YamlList).cast<YamlMap>())
            a['asset'] as String: a['weight'] as int?,
        },
    };
    expect(registered, _expected);
  });

  test('every registered file is a TrueType font whose OS/2 weight matches '
      'its declaration', () {
    for (final (_, asset, weight) in _assets()) {
      final font = Sfnt(File(asset).readAsBytesSync());
      expect(font.isTrueType, isTrue, reason: asset);
      expect(font.weightClass, weight, reason: asset);
    }
  });

  test('every registered file names its own family', () {
    for (final (family, asset, _) in _assets()) {
      expect(
        Sfnt(File(asset).readAsBytesSync()).familyName,
        family,
        reason: asset,
      );
    }
  });

  test('every font folder carries its OFL licence, shipped as an asset', () {
    for (final licence in _licences) {
      expect(
        File(licence).readAsStringSync(),
        contains('SIL OPEN FONT LICENSE Version 1.1'),
        reason: licence,
      );
    }
    final assets = (_flutterSection()['assets'] as YamlList).cast<String>();
    expect(assets.toSet(), _licences.toSet());
  });

  test('every font file matches the SHA-256 recorded in SOURCES.md', () {
    final rows =
        RegExp(
              r'^\|\s*`?([\w-]+\.ttf)`?\s*\|.*\b([0-9a-f]{64})\b',
              multiLine: true,
            )
            .allMatches(File('$_dir/SOURCES.md').readAsStringSync())
            .map((m) => (m.group(1)!, m.group(2)!));
    final recorded = {for (final (file, hash) in rows) file: hash};
    final assets = {for (final (_, a, _) in _assets()) a.split('/').last: a};
    expect(recorded.keys.toSet(), assets.keys.toSet());
    recorded.forEach((file, hash) {
      final actual = sha256.convert(File(assets[file]!).readAsBytesSync());
      expect(actual.toString(), hash, reason: file);
    });
  });
}
