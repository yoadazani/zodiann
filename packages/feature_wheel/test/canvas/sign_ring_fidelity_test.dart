import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeData;
import 'package:shared_ui/shared_ui.dart';

import '../support/load_wheel_fonts.dart';
import '../support/repo_root.dart';
import '../support/wheel_capture.dart';
import '../support/wheel_harness.dart';

// Fidelity of the sign ring against Chrome's rendering of the design kit
// (tool/wheel/render_sign_ring_references.dart): one reference per table and
// theme at 644 x 656, R = 300 px, centre (322, 334), pointer 227.05 (the kit's
// own default). Ceilings are calibrated as max(round_up(worst x 1.5), floor)
// and recorded in fixtures/sign_ring/README.md.

const _w = 644;
const _centre = Offset(322, 334);
const _r = 300.0;

/// A calibrated ceiling and a record of the worst value seen.
final _measured = <String, double>{};

double _lum(List<int> px, int i) =>
    0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];

void main() {
  late Map<String, dynamic> manifest;
  late String fixtures;

  setUpAll(() async {
    await loadWheelGlyphFonts();
    fixtures =
        '${repoRoot().path}/packages/feature_wheel/test/fixtures/sign_ring';
    manifest = jsonDecode(
      File('$fixtures/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('the reference manifest names the pointer longitude used here', () {
    expect(manifest['pointerLongitude'], 227.05);
    expect(manifest['width'], 644);
    expect(manifest['height'], 656);
    expect(manifest['radius'], 300);
  });

  for (final (table, proportions) in [
    ('desktop', WheelProportions.desktop),
    ('compact', WheelProportions.compact),
  ]) {
    for (final (theme, brightness, themeData) in [
      ('dark', Brightness.dark, ZodiannTheme.graphite),
      ('light', Brightness.light, ZodiannTheme.porcelain),
    ]) {
      testWidgets('$table $theme matches the Chrome reference', (tester) async {
        await pumpWheelCanvas(
          tester,
          proportions: proportions,
          state: const WheelState(pointerLongitude: 227.05),
          layers: const [SignRingLayer()],
          brightness: brightness,
          wrap: onSurface(),
        );
        await tester.pump(const Duration(seconds: 1));
        final actual = await captureBytes(tester);
        final expected = await decodePng(
          tester,
          File('$fixtures/ring_${theme}_$table.png').readAsBytesSync(),
        );
        _compare('$table/$theme', actual, expected, proportions, themeData);
      });
    }
  }
}

Offset _at(double longitude, double fraction) {
  // pointer 227.05; kit: angle = 90 + lon - pointer, point = (r cos, -r sin).
  final a = (90 + longitude - 227.05) * math.pi / 180;
  return _centre + Offset(math.cos(a), -math.sin(a)) * (fraction * _r);
}

void _compare(
  String tag,
  List<int> actual,
  List<int> expected,
  WheelProportions p,
  ThemeData theme,
) {
  int idx(int x, int y) => (y * _w + x) * 4;

  // 1. Mean absolute difference over the annulus signBandInner-20 .. halo+2.
  final lo = (p.signBandInner * _r) - 20;
  final hi = p.haloRadius * _r + 2;
  var sum = 0.0;
  var n = 0;
  var rimOuter = 0.0, rimOuterN = 0;
  var rimInner = 0.0, rimInnerN = 0;
  var halo = 0.0, haloN = 0;
  for (var y = 0; y < 656; y++) {
    for (var x = 0; x < _w; x++) {
      final d = (Offset(x + 0.5, y + 0.5) - _centre).distance;
      if (d < lo || d > hi) continue;
      var diff = 0.0;
      for (var k = 0; k < 3; k++) {
        diff += (actual[idx(x, y) + k] - expected[idx(x, y) + k]).abs();
      }
      diff /= 3;
      sum += diff;
      n++;
      if ((d - p.signBandOuter * _r).abs() <= 2) {
        rimOuter += diff;
        rimOuterN++;
      }
      if ((d - p.signBandInner * _r).abs() <= 2) {
        rimInner += diff;
        rimInnerN++;
      }
      if ((d - p.haloRadius * _r).abs() <= 2) {
        halo += diff;
        haloN++;
      }
    }
  }
  _measured['$tag mean'] = sum / n;
  _measured['$tag outer rim'] = rimOuter / rimOuterN;
  _measured['$tag inner rim'] = rimInner / rimInnerN;
  _measured['$tag halo'] = halo / haloN;

  // 2. Sector fill at 12 points per sign, clear of glyphs, separators, rims.
  final mid = (p.signBandOuter + p.signBandInner) / 2;
  var worstFill = 0;
  for (var i = 0; i < 12; i++) {
    for (final offset in [4.0, 6.0, 8.0, 22.0, 24.0, 26.0]) {
      for (final dr in [-10 / _r, 10 / _r]) {
        final c = _at(i * 30 + offset, mid + dr);
        final at = idx(c.dx.round(), c.dy.round());
        for (var k = 0; k < 3; k++) {
          worstFill = math.max(
            worstFill,
            (actual[at + k] - expected[at + k]).abs(),
          );
        }
      }
    }
  }
  _measured['$tag fill'] = worstFill.toDouble();

  // 3. Glyph ink: luminance-weighted centroid and extent around each glyph.
  var worstCentroid = 0.0;
  var worstBox = 0.0;
  for (var i = 0; i < 12; i++) {
    final c = _at(i * 30 + 15, mid);
    (Offset, double, double, double, double)? stats(List<int> px) {
      var sx = 0.0, sy = 0.0, sw = 0.0;
      var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
      final cx = c.dx.round(), cy = c.dy.round();
      // Background luminance: the corner of the window.
      final bg = _lum(px, idx(cx - 14, cy - 14));
      for (var y = cy - 14; y <= cy + 14; y++) {
        for (var x = cx - 14; x <= cx + 14; x++) {
          final w = (_lum(px, idx(x, y)) - bg).abs();
          if (w < 25) continue;
          sx += x * w;
          sy += y * w;
          sw += w;
          x0 = math.min(x0, x.toDouble());
          x1 = math.max(x1, x.toDouble());
          y0 = math.min(y0, y.toDouble());
          y1 = math.max(y1, y.toDouble());
        }
      }
      if (sw == 0) return null;
      return (Offset(sx / sw, sy / sw), x0, x1, y0, y1);
    }

    final a = stats(actual), e = stats(expected);
    expect(a, isNotNull, reason: '$tag sign $i has no ink');
    expect(e, isNotNull, reason: '$tag reference sign $i has no ink');
    worstCentroid = math.max(worstCentroid, (a!.$1 - e!.$1).distance);
    for (final (x, y) in [
      (a.$2, e.$2),
      (a.$3, e.$3),
      (a.$4, e.$4),
      (a.$5, e.$5),
    ]) {
      worstBox = math.max(worstBox, (x - y).abs());
    }
  }
  _measured['$tag centroid'] = worstCentroid;
  _measured['$tag box'] = worstBox;

  final ceilings = _ceilings[tag]!;
  expect(sum / n, lessThanOrEqualTo(ceilings['mean']!), reason: '$tag mean');
  expect(rimOuter / rimOuterN, lessThanOrEqualTo(ceilings['outer rim']!));
  expect(rimInner / rimInnerN, lessThanOrEqualTo(ceilings['inner rim']!));
  expect(halo / haloN, lessThanOrEqualTo(ceilings['halo']!));
  expect(worstFill, lessThanOrEqualTo(2), reason: '$tag fill');
  expect(worstCentroid, lessThanOrEqualTo(2), reason: '$tag centroid');
  expect(worstBox, lessThanOrEqualTo(2), reason: '$tag box');
}

/// Calibrated 2026-11-19 (worst measured x 1.5, rounded up; floor 0.2).
const _ceilings = <String, Map<String, double>>{
  'desktop/dark': {
    'mean': 0.75,
    'outer rim': 0.75,
    'inner rim': 0.7,
    'halo': 0.35,
  },
  'desktop/light': {
    'mean': 0.45,
    'outer rim': 0.35,
    'inner rim': 0.35,
    'halo': 0.2,
  },
  'compact/dark': {
    'mean': 1.4,
    'outer rim': 0.75,
    'inner rim': 0.7,
    'halo': 0.35,
  },
  'compact/light': {
    'mean': 1.15,
    'outer rim': 0.35,
    'inner rim': 0.4,
    'halo': 0.2,
  },
};
