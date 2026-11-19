// ZOD-WHL-003 criterion 3 against the designer's own screenshots: the degree
// scale in `01-zodiac-wheel_desktop_*` has the tick weights the rule gives
// (5 / 9 / 14 kit units, none at multiples of 30°) and the "10" / "20" labels
// where the kit puts them (the Chrome reference, which is the kit rendered
// alone, is the oracle for the label centres). The English and Hebrew scales
// are the same although the surrounding UI mirrors.
//
// The wheel panel sits on a different side in each file and at about 1.06 x
// the kit's scale, so each wheel's centre and size are found from the picture
// itself (the finder is shared with the sign ring test). The root package is
// pure Dart, so the tick rule is written here, not imported from
// `feature_wheel`. Thresholds are calibrated from the measured values (see
// the table in `fixtures/degree_scale/README.md`).
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../support/wheel_png.dart';

const _screens = 'design-reference/zodiann/screens';
const _refs = 'packages/feature_wheel/test/fixtures/degree_scale';

/// `kit.js` `BODIES` longitudes (the connectors and the pointer line cross
/// the scale near them, so the checks skip those degrees).
const _bodies = [
  227.05, 228.69, 216.20, 202.80, 138.45, 143.60, //
  3.74, 61.97, 359.69, 302.87, 326.32,
];
const _pointer = 227.05;

// The wheel panel's surface (kit.css `--surface`).
const _surface = {'dark': 0x111114, 'light': 0xFFFFFF};

// The tick rule (kit.js:318-321), independent of the layer.
bool _hasTick(int d) => d % 30 != 0;
double _length(int d) => d % 10 == 0 ? 14 : (d % 5 == 0 ? 9 : 5);

bool _nearBody(double degree, double window) => _bodies.any((b) {
  final gap = ((degree - b) % 360 + 360) % 360;
  return math.min(gap, 360 - gap) <= window;
});

double _lum(img.Pixel p) => 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

double _surfaceLum(String theme) {
  final s = _surface[theme]!;
  return 0.299 * ((s >> 16) & 255) +
      0.587 * ((s >> 8) & 255) +
      0.114 * (s & 255);
}

/// A scale as measured in one picture: pixels per kit unit and the centre
/// (in pixel-index coordinates, the finder's).
class _Scale {
  _Scale(this.image, this.cx, this.cy, this.unit, this.bg);
  final img.Image image;
  final double cx, cy, unit, bg;

  /// The point [units] from the centre along longitude [d].
  (double, double) at(double d, double units) {
    final a = (90 + d - _pointer) * math.pi / 180;
    return (cx + math.cos(a) * units * unit, cy - math.sin(a) * units * unit);
  }

  double _delta(int x, int y) => (_lum(image.getPixel(x, y)) - bg).abs();

  double bilinear(double x, double y) {
    final x0 = x.floor(), y0 = y.floor();
    final fx = x - x0, fy = y - y0;
    return _delta(x0, y0) * (1 - fx) * (1 - fy) +
        _delta(x0 + 1, y0) * fx * (1 - fy) +
        _delta(x0, y0 + 1) * (1 - fx) * fy +
        _delta(x0 + 1, y0 + 1) * fx * fy;
  }

  /// The tick tip of longitude [d], in kit units inside the band's inner edge
  /// (250), found where the interpolated ink along the ray drops below 45 % of
  /// its peak, scanning in from just past the longest tick.
  double tip(int d) {
    double ink(double inside) {
      final (x, y) = at(d.toDouble(), 250 - inside);
      return bilinear(x, y);
    }

    var peak = 0.0;
    for (var inside = 1.0; inside <= 4.0; inside += 0.25) {
      peak = math.max(peak, ink(inside));
    }
    for (var inside = 15.5; inside >= 0; inside -= 0.25) {
      if (ink(inside) >= 0.45 * peak) return inside;
    }
    return 0;
  }

  /// The luminance-weighted ink centroid of the label at longitude [d], in
  /// kit units from the wheel's centre, or null if there is no ink.
  (double, double)? label(int d) {
    final (ex, ey) = at(d.toDouble(), 224);
    var sx = 0.0, sy = 0.0, sw = 0.0;
    final hx = (10 * unit).ceil(), hy = (8 * unit).ceil();
    for (var y = ey.round() - hy; y <= ey.round() + hy; y++) {
      for (var x = ex.round() - hx; x <= ex.round() + hx; x++) {
        final w = _delta(x, y);
        if (w < 25) continue;
        sx += x * w;
        sy += y * w;
        sw += w;
      }
    }
    if (sw == 0) return null;
    return ((sx / sw - cx) / unit, (sy / sw - cy) / unit);
  }
}

_Scale _scaleOf(img.Image image, String theme) {
  final wheel = findWheel(image, theme == 'dark');
  expect(wheel.rim, inInclusiveRange(250, 400), reason: 'wheel not found');
  return _Scale(image, wheel.cx, wheel.cy, wheel.unit, _surfaceLum(theme));
}

img.Image _load(String path) => img.decodePng(File(path).readAsBytesSync())!;

void main() {
  for (final theme in ['dark', 'light']) {
    for (final language in ['en', 'he']) {
      test('the tick weights are 5 / 9 / 14 ($language, $theme)', () {
        final scale = _scaleOf(
          _load('$_screens/01-zodiac-wheel_desktop_${language}_$theme.png'),
          theme,
        );
        var checked = 0;
        var worst = 0.0;
        for (var d = 1; d < 360; d++) {
          if (!_hasTick(d) || _nearBody(d.toDouble(), 1.5)) continue;
          final tip = scale.tip(d);
          worst = math.max(worst, (tip - _length(d)).abs());
          expect(tip, closeTo(_length(d), 1.5), reason: 'tick at $d degrees');
          checked++;
        }
        expect(checked, greaterThan(300), reason: 'ticks measured');
        print('scale tip worst error $language $theme: $worst');
      });

      test('the labels sit where the kit puts them ($language, $theme)', () {
        final scale = _scaleOf(
          _load('$_screens/01-zodiac-wheel_desktop_${language}_$theme.png'),
          theme,
        );
        // The Chrome reference is the kit alone at 1:1: centre (322, 334).
        final reference = _Scale(
          _load('$_refs/scale_${theme}_desktop.png'),
          322,
          334,
          1,
          _surfaceLum(theme),
        );
        var checked = 0;
        var worst = 0.0;
        for (var d = 10; d < 360; d += 10) {
          if (d % 30 == 0 || _nearBody(d.toDouble(), 4)) continue;
          final a = scale.label(d), e = reference.label(d);
          expect(a, isNotNull, reason: 'no label at $d degrees');
          expect(e, isNotNull, reason: 'the reference has no label at $d');
          final distance = math.sqrt(
            math.pow(a!.$1 - e!.$1, 2) + math.pow(a.$2 - e.$2, 2),
          );
          worst = math.max(worst, distance);
          expect(distance, lessThanOrEqualTo(2.0), reason: 'label at $d');
          checked++;
        }
        expect(checked, greaterThan(14), reason: 'labels measured');
        print('scale label worst distance $language $theme: $worst');
      });
    }

    test('the labels are in the same place in English and Hebrew ($theme)', () {
      final en = _scaleOf(
        _load('$_screens/01-zodiac-wheel_desktop_en_$theme.png'),
        theme,
      );
      final he = _scaleOf(
        _load('$_screens/01-zodiac-wheel_desktop_he_$theme.png'),
        theme,
      );
      var checked = 0;
      var worst = 0.0;
      for (var d = 10; d < 360; d += 10) {
        if (d % 30 == 0 || _nearBody(d.toDouble(), 4)) continue;
        final a = en.label(d), b = he.label(d);
        expect(a, isNotNull, reason: 'no English label at $d degrees');
        expect(b, isNotNull, reason: 'no Hebrew label at $d degrees');
        final distance = math.sqrt(
          math.pow(a!.$1 - b!.$1, 2) + math.pow(a.$2 - b.$2, 2),
        );
        worst = math.max(worst, distance);
        expect(distance, lessThanOrEqualTo(0.75), reason: 'label at $d');
        checked++;
      }
      expect(checked, greaterThan(14), reason: 'labels measured');
      print('scale label en vs he $theme: worst $worst');
    });

    test('the ticks are the same in English and Hebrew ($theme)', () {
      final en = _load('$_screens/01-zodiac-wheel_desktop_en_$theme.png');
      final he = _load('$_screens/01-zodiac-wheel_desktop_he_$theme.png');
      final a = findWheel(en, theme == 'dark');
      final b = findWheel(he, theme == 'dark');
      final dxExact = b.cx - a.cx, dyExact = b.cy - a.cy;
      final dx = dxExact.round(), dy = dyExact.round();
      expect(dx, isNot(0), reason: 'the wheel panel moves between the files');
      expect((dxExact - dx).abs(), lessThan(0.2), reason: 'integer shift');
      expect((dyExact - dy).abs(), lessThan(0.2), reason: 'integer shift');

      // The tick zone: 233 .. 251 units. The label ring (about 217 .. 231) is left
      // out: the designer's two renders differ there in subpixel text
      // antialiasing (the labels are checked by centroid, below).
      final lo = 233 * a.unit, hi = 251 * a.unit;
      var compared = 0, worst = 0, differing = 0;
      for (var y = 0; y < en.height; y++) {
        for (var x = 0; x < en.width; x++) {
          final d = math.sqrt(math.pow(x - a.cx, 2) + math.pow(y - a.cy, 2));
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
      expect(compared, greaterThan(20000), reason: 'tick pixels compared');
      print('scale en vs he $theme: worst $worst, $differing differ');
      expect(worst, lessThanOrEqualTo(1), reason: '$differing differ');
    });
  }
}
