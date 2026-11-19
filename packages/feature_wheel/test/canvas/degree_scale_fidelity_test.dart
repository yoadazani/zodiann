import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';

import '../support/load_wheel_fonts.dart';
import '../support/repo_root.dart';
import '../support/wheel_capture.dart';
import '../support/wheel_harness.dart';

// Fidelity of the degree scale against Chrome's rendering of the design kit
// (tool/wheel/render_degree_scale_references.dart): one reference per table
// and theme at 644 x 656, R = 300 px, centre (322, 334), pointer 227.05 (the
// kit's own default). Ceilings are calibrated as max(round_up(worst x 1.5), floor)
// and recorded in fixtures/degree_scale/README.md.

const _w = 644;
const _centre = Offset(322, 334);
const _r = 300.0;
const _pointer = 227.05;

/// The worst values seen, printed at the end for calibration.
final _measured = <String, double>{};
var _sumLabelDx = 0.0, _sumLabelDy = 0.0, _labelCount = 0;

double _lum(List<int> px, int i) =>
    0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];

int _idx(int x, int y) => (y * _w + x) * 4;

/// The kit's point: angle = 90 + lon - pointer, (r cos, -r sin).
Offset _at(double longitude, double units) {
  final a = (90 + longitude - _pointer) * math.pi / 180;
  return _centre + Offset(math.cos(a), -math.sin(a)) * units;
}

// The test-local tick rule (kit.js:318-321), independent of the layer.
bool _hasTick(int d) => d % 30 != 0;
double _length(int d) => d % 10 == 0 ? 14 : (d % 5 == 0 ? 9 : 5);

void main() {
  late Map<String, dynamic> manifest;
  late String fixtures;

  setUpAll(() async {
    await loadWheelGlyphFonts();
    await loadWheelTextFonts();
    fixtures =
        '${repoRoot().path}/packages/feature_wheel/test/fixtures/degree_scale';
    manifest = jsonDecode(
      File('$fixtures/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  // Calibration output: the worst values seen (README.md records them).
  // ignore: avoid_print
  tearDownAll(() => print('degree scale measured: $_measured'));

  test('the reference manifest names the pointer longitude used here', () {
    expect(manifest['pointerLongitude'], _pointer);
    expect(manifest['width'], 644);
    expect(manifest['height'], 656);
    expect(manifest['radius'], 300);
  });

  for (final (table, proportions) in [
    ('desktop', WheelProportions.desktop),
    ('compact', WheelProportions.compact),
  ]) {
    for (final (theme, brightness) in [
      ('dark', Brightness.dark),
      ('light', Brightness.light),
    ]) {
      testWidgets('$table $theme matches the Chrome reference', (tester) async {
        await pumpWheelCanvas(
          tester,
          proportions: proportions,
          state: const WheelState(pointerLongitude: _pointer),
          layers: const [DegreeScaleLayer()],
          brightness: brightness,
          wrap: onSurface(),
        );
        await tester.pump(const Duration(seconds: 1));
        final actual = await captureBytes(tester);
        final expected = await decodePng(
          tester,
          File('$fixtures/scale_${theme}_$table.png').readAsBytesSync(),
        );
        _compare('$table/$theme', actual, expected, proportions);
      });
    }
  }
}

void _compare(
  String tag,
  List<int> actual,
  List<int> expected,
  WheelProportions p,
) {
  final bgActual = _lum(actual, _idx(2, 2));
  final bgExpected = _lum(expected, _idx(2, 2));
  double delta(List<int> px, double bg, int x, int y) =>
      (_lum(px, _idx(x, y)) - bg).abs();

  // 1. The tick length along every ray: the sub-pixel position of the tick's
  // tip (bilinear luminance along the ray), in units inside the band's inner
  // edge. The reference must show the rule's length, and so must the render.
  final edge = p.signBandInner * _r;
  double bilinear(List<int> px, double bg, Offset at) {
    final x0 = at.dx.floor(), y0 = at.dy.floor();
    final fx = at.dx - x0, fy = at.dy - y0;
    double v(int dx, int dy) => delta(px, bg, x0 + dx, y0 + dy);
    return v(0, 0) * (1 - fx) * (1 - fy) +
        v(1, 0) * fx * (1 - fy) +
        v(0, 1) * (1 - fx) * fy +
        v(1, 1) * fx * fy;
  }

  double tipOf(List<int> px, double bg, int d) {
    // Pixel centres sit at +0.5, so a point is sampled at its own position.
    double at(double inside) => bilinear(
      px,
      bg,
      _at(d.toDouble(), edge - inside) - const Offset(0.5, 0.5),
    );
    var peak = 0.0;
    for (var inside = 1.0; inside <= 4.0; inside += 0.25) {
      peak = math.max(peak, at(inside));
    }
    // Scan from just past the longest tick (14); the compact labels start at
    // about 17 units.
    for (var inside = 15.5; inside >= 0; inside -= 0.25) {
      if (at(inside) >= 0.45 * peak) return inside;
    }
    return 0;
  }

  var worstTickCentroid = 0.0;
  var worstTipError = 0.0;
  for (var d = 1; d < 360; d++) {
    if (!_hasTick(d)) continue;
    final tipExpected = tipOf(expected, bgExpected, d);
    final tipActual = tipOf(actual, bgActual, d);
    expect(
      tipExpected,
      closeTo(_length(d), 1),
      reason: '$tag: the reference tick at $d',
    );
    expect(
      tipActual,
      closeTo(_length(d), 1),
      reason: '$tag: the rendered tick at $d',
    );
    worstTipError = math.max(worstTipError, (tipActual - tipExpected).abs());

    // 2. Position: the luminance-weighted centroid of a 5 x 5 box around the
    // tick's point 2 units inside the edge, render against reference.
    final c = _at(d.toDouble(), edge - 2);
    Offset centroid(List<int> px, double bg) {
      var sx = 0.0, sy = 0.0, sw = 0.0;
      for (var y = c.dy.round() - 2; y <= c.dy.round() + 2; y++) {
        for (var x = c.dx.round() - 2; x <= c.dx.round() + 2; x++) {
          final w = delta(px, bg, x, y);
          sx += x * w;
          sy += y * w;
          sw += w;
        }
      }
      return Offset(sx / sw, sy / sw);
    }

    worstTickCentroid = math.max(
      worstTickCentroid,
      (centroid(actual, bgActual) - centroid(expected, bgExpected)).distance,
    );
  }
  _measured['$tag tick centroid'] = worstTickCentroid;
  _measured['$tag tick tip error'] = worstTipError;

  // 3. Labels: the luminance-weighted ink centroid of each of the 24 labels,
  // render against reference, and the reference's measured radius against the
  // table's label radius (WHL-001 confirmed it by eye only).
  var worstLabel = 0.0;
  var worstRadius = 0.0;
  for (var d = 10; d < 360; d += 10) {
    if (d % 30 == 0) continue;
    final c = _at(d.toDouble(), p.degreeNumberRadius * _r);
    Offset? centroid(List<int> px, double bg) {
      var sx = 0.0, sy = 0.0, sw = 0.0;
      for (var y = c.dy.round() - 8; y <= c.dy.round() + 8; y++) {
        for (var x = c.dx.round() - 10; x <= c.dx.round() + 10; x++) {
          final w = delta(px, bg, x, y);
          if (w < 25) continue;
          sx += x * w;
          sy += y * w;
          sw += w;
        }
      }
      return sw == 0 ? null : Offset(sx / sw, sy / sw);
    }

    final a = centroid(actual, bgActual);
    final e = centroid(expected, bgExpected);
    expect(a, isNotNull, reason: '$tag: the render has no label at $d');
    expect(e, isNotNull, reason: '$tag: the reference has no label at $d');
    worstLabel = math.max(worstLabel, (a! - e!).distance);
    _sumLabelDx += a.dx - e.dx;
    _sumLabelDy += a.dy - e.dy;
    _labelCount++;
    worstRadius = math.max(
      worstRadius,
      ((e - _centre).distance - p.degreeNumberRadius * _r).abs(),
    );
  }
  _measured["$tag label centroid"] = worstLabel;
  _measured["$tag mean dx"] = _sumLabelDx / _labelCount;
  _measured["$tag mean dy"] = _sumLabelDy / _labelCount;
  _sumLabelDx = _sumLabelDy = 0;
  _labelCount = 0;
  _measured['$tag label radius error'] = worstRadius;

  // 4. Mean absolute difference over the scale annulus.
  final lo = edge - 40;
  final hi = edge + 1;
  var sum = 0.0;
  var n = 0;
  for (var y = 0; y < 656; y++) {
    for (var x = 0; x < _w; x++) {
      final dist = (Offset(x + 0.5, y + 0.5) - _centre).distance;
      if (dist < lo || dist > hi) continue;
      var diff = 0.0;
      for (var k = 0; k < 3; k++) {
        diff += (actual[_idx(x, y) + k] - expected[_idx(x, y) + k]).abs();
      }
      sum += diff / 3;
      n++;
    }
  }
  _measured['$tag mean'] = sum / n;

  final ceilings = _ceilings[tag]!;
  expect(sum / n, lessThanOrEqualTo(ceilings['mean']!), reason: '$tag mean');
  expect(worstTickCentroid, lessThanOrEqualTo(1), reason: '$tag tick centroid');
  expect(worstLabel, lessThanOrEqualTo(2), reason: '$tag label centroid');
  expect(worstRadius, lessThanOrEqualTo(2), reason: '$tag label radius');
}

/// Calibrated 2026-11-19: worst measured x 1.5, rounded up to 0.05 (measured
/// 1.00 / 1.30 / 0.75 / 0.98; see fixtures/degree_scale/README.md).
const _ceilings = <String, Map<String, double>>{
  'desktop/dark': {'mean': 1.55},
  'desktop/light': {'mean': 2.0},
  'compact/dark': {'mean': 1.15},
  'compact/light': {'mean': 1.5},
};
