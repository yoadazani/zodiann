// ZOD-FND-007 criterion 2: the bundled glyph fonts cover every astrological
// glyph in MASTER.md §3's Glyphs row, and the text families cover their
// scripts.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/sfnt.dart';

const _signs = [
  0x2648, 0x2649, 0x264A, 0x264B, 0x264C, 0x264D, //
  0x264E, 0x264F, 0x2650, 0x2651, 0x2652, 0x2653,
];
const _bodies = [
  0x2609, 0x263D, 0x263F, 0x2640, 0x2642, 0x2643, //
  0x2644, 0x2645, 0x2646, 0x2647, 0x260A,
];
const _retrograde = 0x211E;
const _aspects = [0x260C, 0x26B9, 0x25A1, 0x25B3, 0x260D];

/// MASTER §3 Glyphs: ♈–♓, ☉☽☿♀♂♃♄♅♆♇☊, ℞, aspect glyphs.
final _glyphs = {..._signs, ..._bodies, _retrograde, ..._aspects};

const _files = {
  ZodiannFonts.notoSansSymbols:
      'assets/fonts/noto-sans-symbols/NotoSansSymbols-Regular.ttf',
  ZodiannFonts.notoSansSymbols2:
      'assets/fonts/noto-sans-symbols-2/NotoSansSymbols2-Regular.ttf',
  ZodiannFonts.notoSans: 'assets/fonts/noto-sans/NotoSans-Regular.ttf',
};

final _plexFiles = [
  for (final w in ['Light', 'Regular', 'Medium', 'SemiBold']) ...[
    'assets/fonts/ibm-plex-sans/IBMPlexSans-$w.ttf',
    'assets/fonts/ibm-plex-sans-hebrew/IBMPlexSansHebrew-$w.ttf',
  ],
];

Set<int> _cover(String path) => Sfnt(File(path).readAsBytesSync()).codePoints;

Iterable<int> _range(int from, int to) => [for (var c = from; c <= to; c++) c];

final _latinAndDigits = [
  ..._range(0x41, 0x5A),
  ..._range(0x61, 0x7A),
  ..._range(0x30, 0x39),
];

String _hex(Iterable<int> cs) =>
    cs.map((c) => 'U+${c.toRadixString(16).toUpperCase()}').join(' ');

void main() {
  test('the glyph set has the 29 MASTER glyphs', () {
    expect(_glyphs, hasLength(29));
  });

  test('the glyph fallback chain covers all 29 MASTER glyphs', () {
    final chain = [
      for (final f in ZodiannFonts.glyphFallback) _cover(_files[f]!),
    ];
    final missing = _glyphs.where((c) => !chain.any((s) => s.contains(c)));
    expect(missing, isEmpty, reason: 'missing ${_hex(missing)}');
  });

  test('each glyph font covers exactly the expected subset of the 29', () {
    const notInSymbols = {0x2609, _retrograde, 0x25A1, 0x25B3};
    final expected = {
      ZodiannFonts.notoSansSymbols: _glyphs.difference(notInSymbols),
      ZodiannFonts.notoSansSymbols2: {0x2609, 0x25A1, 0x25B3},
      ZodiannFonts.notoSans: {_retrograde},
    };
    expected.forEach((family, glyphs) {
      expect(
        _cover(_files[family]!).intersection(_glyphs),
        glyphs,
        reason: family,
      );
    });
    for (final plex in _plexFiles) {
      expect(_cover(plex).intersection(_glyphs), isEmpty, reason: plex);
    }
  });

  test('℞ comes from Noto Sans', () {
    expect(
      _cover(_files[ZodiannFonts.notoSansSymbols]!),
      isNot(contains(_retrograde)),
    );
    expect(
      _cover(_files[ZodiannFonts.notoSansSymbols2]!),
      isNot(contains(_retrograde)),
    );
    expect(_cover(_files[ZodiannFonts.notoSans]!), contains(_retrograde));
  });

  test('IBM Plex Sans Hebrew covers Hebrew letters, Latin and digits', () {
    final cover = _cover(
      'assets/fonts/ibm-plex-sans-hebrew/IBMPlexSansHebrew-Regular.ttf',
    );
    final missing = [
      ..._range(0x05D0, 0x05EA),
      ..._latinAndDigits,
    ].where((c) => !cover.contains(c));
    expect(missing, isEmpty, reason: _hex(missing));
  });

  test('IBM Plex Sans covers Latin and digits', () {
    final cover = _cover('assets/fonts/ibm-plex-sans/IBMPlexSans-Regular.ttf');
    final missing = _latinAndDigits.where((c) => !cover.contains(c));
    expect(missing, isEmpty, reason: _hex(missing));
  });
}
