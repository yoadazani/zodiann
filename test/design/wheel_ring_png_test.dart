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

import '../support/wheel_png.dart';

const _screens = 'design-reference/zodiann/screens';

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
      final a = findWheel(en, dark);
      final b = findWheel(he, dark);

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
