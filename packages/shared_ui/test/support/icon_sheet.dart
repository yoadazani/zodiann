// ZOD-FND-009, test only: renders every icon in one row exactly as
// tool/icons/render_icon_references.dart lays out the Chrome reference
// sheets (cell i at x ∈ [i·S, (i+1)·S), page 33·S × max(S, 64)), loads those
// references, and compares cells.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'icon_capture.dart';

const fixturesDir = 'test/fixtures/icons';
const iconsSourceDir = '../../design-reference/zodiann/assets/icons';
const referenceSizes = [16, 20, 48, 60, 96];

int sheetHeight(int s) => math.max(s, 64);

/// All icons at [s] px in [color] (the theme default when null).
Future<Pixels> renderIconSheet(
  WidgetTester tester,
  int s, {
  Color? color,
  ThemeData? theme,
}) => captureWidget(
  tester,
  Stack(
    children: [
      for (final (i, icon) in ZodiannIcons.values.indexed)
        Positioned(
          left: (i * s).toDouble(),
          top: 0,
          child: ZodiannIcon(icon, size: s.toDouble(), color: color),
        ),
    ],
  ),
  width: ZodiannIcons.values.length * s,
  height: sheetHeight(s),
  wrap: theme == null ? null : (child) => Theme(data: theme, child: child),
);

/// The committed Chrome reference sheet for [s].
Future<Pixels> loadReference(WidgetTester tester, int s) async {
  final bytes = File('$fixturesDir/sheet_$s.png').readAsBytesSync();
  late Pixels pixels;
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    pixels = Pixels(data!, image.width, image.height);
    image.dispose();
    codec.dispose();
  });
  return pixels;
}

/// Alpha differences between a reference and an actual cell.
final class IconDiff {
  const IconDiff(this.meanAbsAlpha, this.maxAbsAlpha, this.inkRatio);

  /// Mean |Δα| over the cell, α in [0, 1].
  final double meanAbsAlpha;

  /// Max |Δα| over the cell.
  final double maxAbsAlpha;

  /// Σα_actual / Σα_ref.
  final double inkRatio;

  @override
  String toString() =>
      'mean ${meanAbsAlpha.toStringAsFixed(4)}, '
      'max ${maxAbsAlpha.toStringAsFixed(3)}, '
      'ink ${inkRatio.toStringAsFixed(4)}';
}

/// Compares cell [cell] (S = [s]) of [ref] and [actual].
IconDiff compareCell(Pixels ref, Pixels actual, int cell, int s) {
  var sum = 0.0, max = 0.0, inkRef = 0.0, inkActual = 0.0;
  for (var y = 0; y < s; y++) {
    for (var x = cell * s; x < (cell + 1) * s; x++) {
      final r = ref.a(x, y) / 255;
      final a = actual.a(x, y) / 255;
      final d = (a - r).abs();
      sum += d;
      max = math.max(max, d);
      inkRef += r;
      inkActual += a;
    }
  }
  return IconDiff(sum / (s * s), max, inkActual / inkRef);
}

/// Σα over the pixels of cell [cell] whose centre, in viewBox units
/// (24 per cell), satisfies [where].
double inkWhere(
  Pixels p,
  int cell,
  int s,
  bool Function(double ux, double uy) where,
) {
  final unit = s / 24;
  var ink = 0.0;
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      if (where((x + 0.5) / unit, (y + 0.5) / unit)) {
        ink += p.a(cell * s + x, y) / 255;
      }
    }
  }
  return ink;
}

/// The peak alpha of cell [cell], in [0, 1].
double peakAlpha(Pixels p, int cell, int s) {
  var peak = 0;
  for (var y = 0; y < s; y++) {
    for (var x = cell * s; x < (cell + 1) * s; x++) {
      peak = math.max(peak, p.a(x, y));
    }
  }
  return peak / 255;
}

/// The index of [icon] in the sheet.
int cellOf(ZodiannIconData icon) => ZodiannIcons.values.indexOf(icon);
