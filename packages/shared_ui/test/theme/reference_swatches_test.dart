// ZOD-UI-001: the token values match the design reference's rendered
// "Colour tokens" swatch grid (design-reference/zodiann/components/
// components_{dark,light}.png), pixel by pixel at each tile's centre.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// The reference grid, by MASTER token name, in reference order.
const _rows = [
  [
    'bg',
    'bg-raised',
    'surface',
    'surface-2',
    'surface-3',
    'line',
    'text',
    'text-2',
  ],
  [
    'accent',
    'accent-line',
    'text-3',
    'focus',
    'danger',
    'ok',
    'line-soft',
    'on-accent',
  ],
  [
    'axis-fill',
    'axis',
    'diag-fill',
    'diag',
    'eighth-fill',
    'today',
    'center',
    'sel-outer',
  ],
  [
    'fire',
    'earth',
    'air',
    'water',
    'asp-conj',
    'asp-soft',
    'asp-hard',
    'cell-fill',
  ],
  [
    'sun',
    'moon',
    'mercury',
    'venus',
    'mars',
    'jupiter',
    'saturn',
    'uranus',
    'neptune',
    'pluto',
    'node',
  ],
];

const _x8 = [141, 306, 472, 637, 802, 967, 1133, 1298];
const _x11 = [119, 239, 359, 480, 600, 720, 840, 960, 1080, 1201, 1321];

/// Per theme: PNG name, expected size, row y-centres (measured; rows 3–5
/// sit higher in the light PNG).
const _themes = {
  'graphite': ('components_dark.png', (1440, 5586), [288, 440, 606, 756, 906]),
  'porcelain': (
    'components_light.png',
    (1440, 5569),
    [288, 440, 590, 740, 890],
  ),
};

final class _Png {
  _Png(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final ByteData rgba;

  /// The pixel at (x, y) as 8-bit ARGB.
  int argb(int x, int y) {
    final i = (y * width + x) * 4;
    return (rgba.getUint8(i + 3) << 24) |
        (rgba.getUint8(i) << 16) |
        (rgba.getUint8(i + 1) << 8) |
        rgba.getUint8(i + 2);
  }
}

Future<_Png> _decode(String name) async {
  final bytes = File('../../design-reference/zodiann/components/$name')
      .readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final png = _Png(image.width, image.height, data!);
  image.dispose();
  return png;
}

Map<String, Color> _all(ZodiannTokens t) => {
  ...t.surfaces.tokens,
  ...t.square.tokens,
  ...t.zodiac.tokens,
  ...t.aspects.tokens,
  ...t.bodies.tokens,
};

String _hex(int argb) => argb.toRadixString(16).padLeft(8, '0').toUpperCase();

void main() {
  final pngs = <String, _Png>{};
  final tokens = {'graphite': graphiteTokens, 'porcelain': porcelainTokens};

  setUpAll(() async {
    for (final MapEntry(:key, :value) in _themes.entries) {
      pngs[key] = await _decode(value.$1);
    }
  });

  test('the reference images are the expected size', () {
    _themes.forEach((theme, spec) {
      expect((pngs[theme]!.width, pngs[theme]!.height), spec.$2, reason: theme);
    });
  });

  test('the layout table lists 43 tiles, each a real token', () {
    final names = _rows.expand((r) => r).toList();
    expect(names, hasLength(43));
    expect(names.toSet(), hasLength(43));
    expect(_all(graphiteTokens).keys, containsAll(names));
  });

  for (final theme in _themes.keys) {
    test('the reference "Colour tokens" swatches match $theme', () {
      final png = pngs[theme]!;
      final t = tokens[theme]!;
      final all = _all(t);
      final ys = _themes[theme]!.$3;
      for (final (r, row) in _rows.indexed) {
        final xs = row.length == 11 ? _x11 : _x8;
        for (final (c, name) in row.indexed) {
          final (x, y) = (xs[c], ys[r]);
          final centre = png.argb(x, y);
          for (final (dx, dy) in [(-10, -10), (10, -10), (-10, 10), (10, 10)]) {
            expect(
              _hex(png.argb(x + dx, y + dy)),
              _hex(centre),
              reason: '$name tile not uniform around ($x, $y)',
            );
          }
          final token = all[name]!;
          if (token.a == 1) {
            expect(_hex(centre), _hex(token.toARGB32()), reason: name);
          } else {
            final want = Color.alphaBlend(token, t.surfaces.surface).toARGB32();
            for (final shift in [16, 8, 0]) {
              final got = (centre >> shift) & 0xFF;
              final exp = (want >> shift) & 0xFF;
              expect(
                (got - exp).abs(),
                lessThanOrEqualTo(1),
                reason: '$name composite: ${_hex(centre)} vs ${_hex(want)}',
              );
            }
          }
        }
      }
    });
  }
}
