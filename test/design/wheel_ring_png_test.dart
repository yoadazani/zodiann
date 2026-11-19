// ZOD-WHL-002 criterion 3 (L-6) against the designer's own screenshots: the
// sign ring is the same in the English and Hebrew wheel screens even though
// the surrounding UI mirrors. The wheel panel sits on a different side in each
// file, so each wheel's centre and size are found from the picture itself.
//
// Tolerance (product-owner decision T4, 2026-11-19): equal within 1 per
// channel, compared over the sign band, the 30-degree separator rays (which
// reach 18 units inside the band) and the halo. The designer's pairs differ by
// at most 1 per channel on the Libra separator; the tick zone and the degree
// numbers below it are WHL-003's and are outside the mask.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

const _screens = 'design-reference/zodiann/screens';

/// The four element colours blended at the sign tint over the wheel panel's
/// surface (kit.css: dark --surface #111114, tint .10; light #FFFFFF, .09).
List<List<int>> _tints(bool dark) {
  const elements = {
    true: [0xF2735A, 0x7CC47F, 0xE8D06E, 0x5AA9FF],
    false: [0xD9472B, 0x2F8F3E, 0xA88600, 0x1F6FD6],
  };
  final surface = dark ? 0x111114 : 0xFFFFFF;
  final tint = dark ? 0.10 : 0.09;
  return [
    for (final e in elements[dark]!)
      [
        for (final shift in [16, 8, 0])
          (((e >> shift) & 255) * tint +
                  ((surface >> shift) & 255) * (1 - tint))
              .round(),
      ],
  ];
}

/// A wheel found in a screenshot: centre and the sign band's outer radius.
class _Wheel {
  _Wheel(this.cx, this.cy, this.rim, this.tintPixels);
  final double cx, cy, rim;
  final int tintPixels;

  /// Pixels per kit unit (the band's outer edge is 296 units).
  double get unit => rim / 296;
}

_Wheel _find(img.Image image, bool dark) {
  final tints = _tints(dark);

  final hits = <(int, int)>[];
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      for (final t in tints) {
        if ((p.r - t[0]).abs() <= 1 &&
            (p.g - t[1]).abs() <= 1 &&
            (p.b - t[2]).abs() <= 1) {
          hits.add((x, y));
          break;
        }
      }
    }
  }
  expect(hits.length, greaterThan(20000), reason: 'sign tints not found');
  // Other UI can share a pale tint (light theme): iteratively keep only the
  // pixels within 1.3 x the median distance of the current centroid.
  var kept = hits;
  var cx = 0.0, cy = 0.0;
  for (var round = 0; round < 6; round++) {
    cx = kept.map((h) => h.$1).reduce((a, b) => a + b) / kept.length;
    cy = kept.map((h) => h.$2).reduce((a, b) => a + b) / kept.length;
    final dist = [
      for (final (x, y) in kept)
        math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)),
    ]..sort();
    final limit = dist[dist.length ~/ 2] * 1.3;
    kept = [
      for (final h in kept)
        if (math.sqrt(math.pow(h.$1 - cx, 2) + math.pow(h.$2 - cy, 2)) <= limit)
          h,
    ];
  }
  var rim = 0.0;
  for (final (x, y) in kept) {
    rim = math.max(rim, math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)));
  }
  return _Wheel(cx, cy, rim, kept.length);
}

void main() {
  for (final theme in ['dark', 'light']) {
    test('the sign ring is the same in English and Hebrew ($theme)', () {
      final dark = theme == 'dark';
      final en = img.decodePng(
        File('$_screens/01-zodiac-wheel_desktop_en_$theme.png')
            .readAsBytesSync(),
      )!;
      final he = img.decodePng(
        File('$_screens/01-zodiac-wheel_desktop_he_$theme.png')
            .readAsBytesSync(),
      )!;
      final a = _find(en, dark);
      final b = _find(he, dark);

      // Self-checks: a failed search must not pass by comparing blanks.
      expect(a.rim, inInclusiveRange(250, 400));
      expect(b.rim, closeTo(a.rim, 1.5), reason: 'same wheel size');
      expect(a.tintPixels, closeTo(b.tintPixels, a.tintPixels * 0.02));
      final dxExact = b.cx - a.cx, dyExact = b.cy - a.cy;
      final dx = dxExact.round(), dy = dyExact.round();
      expect(dx, isNot(0), reason: 'the wheel panel moves between the files');
      expect((dxExact - dx).abs(), lessThan(0.2), reason: 'integer shift');
      expect((dyExact - dy).abs(), lessThan(0.2), reason: 'integer shift');

      // Band, separator rays and halo: 232 .. 308 units.
      final lo = 232 * a.unit, hi = 308 * a.unit;
      var compared = 0, worst = 0, differing = 0;
      for (var y = 0; y < en.height; y++) {
        for (var x = 0; x < en.width; x++) {
          final d = math.sqrt(
            math.pow(x + 0.5 - a.cx, 2) + math.pow(y + 0.5 - a.cy, 2),
          );
          if (d < lo || d > hi) continue;
          final x2 = x + dx, y2 = y + dy;
          if (x2 < 0 || y2 < 0 || x2 >= he.width || y2 >= he.height) continue;
          final p = en.getPixel(x, y), q = he.getPixel(x2, y2);
          final diff = [
            (p.r - q.r).abs(),
            (p.g - q.g).abs(),
            (p.b - q.b).abs(),
          ].reduce(math.max).toInt();
          compared++;
          if (diff > 0) differing++;
          worst = math.max(worst, diff);
        }
      }
      expect(compared, greaterThan(100000), reason: 'ring pixels compared');
      expect(worst, lessThanOrEqualTo(1), reason: '$differing differ');
    });
  }
}
