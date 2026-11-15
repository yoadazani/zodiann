// ZOD-FND-009: every icon, drawn by ZodiannIcon from the generated data,
// matches Chrome's rendering of the source SVG (the references in
// test/fixtures/icons, made by tool/icons/render_icon_references.dart).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/icon_capture.dart';
import '../support/icon_sheet.dart';

const _black = Color(0xFF000000);

/// Per-size ceilings (plan Task 4 Step 3): max(round_up(worst × 1.5, 3),
/// floor), never above the starting value. Measured worst on 2026-11-15
/// (Flutter 3.50.0 tester vs Chrome 157), α in [0, 1]:
///   16: mean 0.0004, max 0.004, |ink−1| 0.0014
///   20: mean 0.0026, max 0.122, |ink−1| 0.0016
///   48: mean 0.0023, max 0.396, |ink−1| 0.0090 (max capped at 0.45)
///   60: mean 0.0011, max 0.145, |ink−1| 0.0004
///   96: mean 0.0013, max 0.290, |ink−1| 0.0011 (max capped at 0.35)
/// Floors: mean 0.002, max 0.10, ink 0.005. Rerun with
/// ZODIANN_ICON_CALIBRATE=1 to print the worst values.
const _meanCeiling = {16: 0.002, 20: 0.004, 48: 0.004, 60: 0.002, 96: 0.003};
const _maxCeiling = {16: 0.10, 20: 0.184, 48: 0.45, 60: 0.219, 96: 0.35};
const _inkTol = {16: 0.005, 20: 0.005, 48: 0.014, 60: 0.005, 96: 0.005};

/// Join tolerance in summed alpha (plan: 0.5, never above 1.0).
const _joinTolerance = 0.5;

Future<(Pixels, Pixels)> _both(WidgetTester tester, int s) async => (
  await loadReference(tester, s),
  await renderIconSheet(tester, s, color: _black),
);

void main() {
  test('references match the current SVGs', () {
    final manifest = jsonDecode(
      File('$fixturesDir/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final hashes = (manifest['svgSha256']! as Map<String, Object?>)
        .cast<String, String>();
    expect(manifest['sizes'], referenceSizes);
    final files = Directory(iconsSourceDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'));
    final current = {
      for (final f in files)
        f.uri.pathSegments.last.replaceAll('.svg', ''): sha256
            .convert(utf8.encode(f.readAsStringSync().replaceAll('\r\n', '\n')))
            .toString(),
    };
    expect(current, hasLength(33));
    expect(hashes.keys.toSet(), current.keys.toSet());
    current.forEach((name, hash) {
      expect(
        hashes[name],
        hash,
        reason:
            '$name.svg changed; regenerate references: '
            'fvm dart run tool/icons/render_icon_references.dart',
      );
    });
    expect([
      for (final icon in ZodiannIcons.values) icon.name,
    ], hashes.keys.toList()..sort());
  });

  for (final s in referenceSizes) {
    testWidgets('every icon matches Chrome at $s px', (tester) async {
      final (ref, actual) = await _both(tester, s);
      expect(ref.width, actual.width);
      final report = <String>[];
      var worstMean = 0.0, worstMax = 0.0, worstInk = 0.0;
      for (final (i, icon) in ZodiannIcons.values.indexed) {
        final d = compareCell(ref, actual, i, s);
        worstMean = d.meanAbsAlpha > worstMean ? d.meanAbsAlpha : worstMean;
        worstMax = d.maxAbsAlpha > worstMax ? d.maxAbsAlpha : worstMax;
        final ink = (d.inkRatio - 1).abs();
        worstInk = ink > worstInk ? ink : worstInk;
        if (d.meanAbsAlpha > _meanCeiling[s]! ||
            d.maxAbsAlpha > _maxCeiling[s]! ||
            ink > _inkTol[s]!) {
          report.add('${icon.name} at $s px: $d');
        }
      }
      if (Platform.environment['ZODIANN_ICON_CALIBRATE'] != null) {
        stdout.writeln(
          'calibration $s px: worst mean ${worstMean.toStringAsFixed(4)}, '
          'max ${worstMax.toStringAsFixed(3)}, '
          '|ink−1| ${worstInk.toStringAsFixed(4)}',
        );
      }
      expect(report, isEmpty, reason: report.join('\n'));
    });
  }

  for (final s in [16, 20]) {
    testWidgets('crisp: ink stays inside the stroke envelope at $s px', (
      tester,
    ) async {
      final (ref, actual) = await _both(tester, s);
      for (final icon in [
        ZodiannIcons.menu,
        ZodiannIcons.x,
        ZodiannIcons.check,
        ZodiannIcons.chevL,
        ZodiannIcons.chevR,
        ZodiannIcons.chevD,
        ZodiannIcons.grid,
      ]) {
        final cell = cellOf(icon);
        expect(
          peakAlpha(actual, cell, s),
          greaterThanOrEqualTo(0.85 * peakAlpha(ref, cell, s)),
          reason: icon.name,
        );
      }
    });
  }

  for (final s in [16, 20, 96]) {
    testWidgets('round caps match Chrome at $s px', (tester) async {
      final (ref, actual) = await _both(tester, s);
      final cell = cellOf(ZodiannIcons.menu);
      bool caps(double ux, double uy) => ux < 4 || ux > 20;
      final chrome = inkWhere(ref, cell, s, caps);
      expect(chrome, greaterThan(0), reason: 'empty caps region');
      expect(
        inkWhere(actual, cell, s, caps),
        greaterThanOrEqualTo(0.7 * chrome),
      );
    });
  }

  testWidgets('round joins match Chrome at 96 px', (tester) async {
    const s = 96;
    final (ref, actual) = await _both(tester, s);
    // chevL: vertex (8.5, 12), outer bisector −x; round apex at x = 7.7.
    // check: vertex (9.5, 17), outer bisector +y; round apex at y = 17.8.
    final regions = {
      ZodiannIcons.chevL: (double ux, double uy) => ux < 8.5 - 0.8,
      ZodiannIcons.check: (double ux, double uy) => uy > 17 + 0.8,
    };
    regions.forEach((icon, region) {
      final cell = cellOf(icon);
      final chrome = inkWhere(ref, cell, s, region);
      final ours = inkWhere(actual, cell, s, region);
      if (Platform.environment['ZODIANN_ICON_CALIBRATE'] != null) {
        stdout.writeln(
          'calibration join ${icon.name}: ours ${ours.toStringAsFixed(3)}, '
          'chrome ${chrome.toStringAsFixed(3)}',
        );
      }
      expect(
        ours,
        lessThanOrEqualTo(chrome + _joinTolerance),
        reason: icon.name,
      );
    });
  });
}
