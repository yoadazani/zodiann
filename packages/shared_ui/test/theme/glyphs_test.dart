// ZOD-UI-002: every astrological glyph string is one MASTER §3 code point
// followed by U+FE0E, so no platform renders it as emoji.
import 'package:astro_core/astro_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

const _bodies = {
  Body.sun: 0x2609,
  Body.moon: 0x263D,
  Body.mercury: 0x263F,
  Body.venus: 0x2640,
  Body.mars: 0x2642,
  Body.jupiter: 0x2643,
  Body.saturn: 0x2644,
  Body.uranus: 0x2645,
  Body.neptune: 0x2646,
  Body.pluto: 0x2647,
  Body.node: 0x260A,
};

/// The 29 glyphs ZOD-FND-007 proved the bundled glyph fonts cover.
const _fnd007 = {
  0x2648, 0x2649, 0x264A, 0x264B, 0x264C, 0x264D, //
  0x264E, 0x264F, 0x2650, 0x2651, 0x2652, 0x2653,
  0x2609, 0x263D, 0x263F, 0x2640, 0x2642, 0x2643,
  0x2644, 0x2645, 0x2646, 0x2647, 0x260A,
  0x211E,
  0x260C, 0x26B9, 0x25A1, 0x25B3, 0x260D,
};

void main() {
  test('every glyph is one MASTER code point followed by U+FE0E', () {
    expect(ZodiannGlyphs.textPresentation, '\u{FE0E}');
    for (final g in ZodiannGlyphs.all) {
      expect(g.runes, hasLength(2), reason: g);
      expect(g.runes.last, 0xFE0E, reason: g);
    }
  });

  test('signs are ♈…♓ in zodiac order', () {
    expect(ZodiannGlyphs.signs, hasLength(12));
    for (var i = 0; i < 12; i++) {
      expect(ZodiannGlyphs.signs[i].runes.first, 0x2648 + i, reason: '$i');
    }
  });

  test('each body has its glyph', () {
    expect(_bodies.keys.toSet(), Body.values.toSet());
    for (final b in Body.values) {
      expect(ZodiannGlyphs.body(b).runes.first, _bodies[b], reason: b.name);
    }
  });

  test('aspects and retrograde', () {
    expect(ZodiannGlyphs.conjunction.runes.first, 0x260C);
    expect(ZodiannGlyphs.sextile.runes.first, 0x26B9);
    expect(ZodiannGlyphs.square.runes.first, 0x25A1);
    expect(ZodiannGlyphs.trine.runes.first, 0x25B3);
    expect(ZodiannGlyphs.opposition.runes.first, 0x260D);
    expect(ZodiannGlyphs.retrograde.runes.first, 0x211E);
  });

  test('the set is exactly the 29 glyphs the bundled fonts cover', () {
    final bases = ZodiannGlyphs.all.map((g) => g.runes.first).toList();
    expect(bases, hasLength(29));
    expect(bases.toSet(), _fnd007);
  });
}
