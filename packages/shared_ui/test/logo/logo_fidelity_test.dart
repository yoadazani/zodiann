// ZOD-FND-008: ZodiannLogo at the drawer (40) and About (132) sizes, at device
// pixel ratios 1, 2 and 3, matches Chrome's rendering of the source SVG (the
// references in test/fixtures/logo, made by tool/logo/render_logo_references.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/icon_capture.dart';

const _fixtures = 'test/fixtures/logo';
const _assets = '../../design-reference/zodiann/assets';

/// (logical size, device pixel ratio): the reference pixel size is the
/// product.
const _cases = [(40, 1), (40, 2), (40, 3), (132, 1), (132, 2), (132, 3)];

/// Ceilings per reference pixel size, about 20 % above the worst measured on
/// 2026-11-16 (Flutter 3.50.0 tester vs Chrome 157; α in [0, 1], both
/// themes, decode at `size × dpr`). Measured worst (mean α / max α / mean
/// colour): 40: 0.0398 / 0.576 / 0.0283; 80: 0.0236 / 0.635 / 0.0169;
/// 120: 0.0180 / 0.467 / 0.0131; 132: 0.0179 / 0.561 / 0.0129;
/// 264: 0.0058 / 0.404 / 0.0043; 396: 0.0042 / 0.278 / 0.0032. The other
/// decode strategy (full 1024 decode) measured worse at 40 (0.0454 / 0.710 /
/// 0.0328). Rerun with ZODIANN_LOGO_CALIBRATE=1 to print the values.
const _meanAlphaCeiling = <int, double>{
  40: 0.048,
  80: 0.029,
  120: 0.022,
  132: 0.022,
  264: 0.0075,
  396: 0.0055,
};
const _maxAlphaCeiling = <int, double>{
  40: 0.70,
  80: 0.76,
  120: 0.57,
  132: 0.68,
  264: 0.50,
  396: 0.34,
};
const _meanColourCeiling = <int, double>{
  40: 0.035,
  80: 0.021,
  120: 0.016,
  132: 0.016,
  264: 0.0055,
  396: 0.004,
};

/// The outer band (radius ≥ 0.40 · side: the hairline ring and the ticks)
/// must keep between these shares of Chrome's ink (measured 0.86 … 1.24):
/// the hairlines must neither vanish nor bloat. Whole-image ink stays within
/// 0.95 … 1.10 (measured 0.99 … 1.06).
const _outerInkFloor = 0.75;
const _outerInkCeiling = 1.35;

typedef _Diff = ({
  double meanAlpha,
  double maxAlpha,
  double meanColour,
  double outerInk,
  double totalInk,
});

Future<Pixels> _reference(WidgetTester tester, String variant, int px) async {
  final bytes = File('$_fixtures/${variant}_$px.png').readAsBytesSync();
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

Future<Pixels> _render(
  WidgetTester tester,
  int logical,
  int dpr,
  ThemeData theme,
) async {
  final media = MediaQueryData(devicePixelRatio: dpr.toDouble());
  Widget around(Widget child) => MediaQuery(
    data: media,
    child: Theme(data: theme, child: child),
  );
  // Decode the mark before capturing: images decode outside fake-async.
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: around(ZodiannLogo(size: logical.toDouble())),
    ),
  );
  final image = tester.widget<Image>(find.byType(Image));
  await tester.runAsync(
    () => precacheImage(image.image, tester.element(find.byType(Image))),
  );
  return captureWidget(
    tester,
    ZodiannLogo(size: logical.toDouble()),
    width: logical,
    height: logical,
    devicePixelRatio: dpr.toDouble(),
    wrap: around,
  );
}

/// Summed alpha: (over the whole image, over the outer band).
(double, double) _ink(Pixels p) {
  final side = p.width.toDouble();
  final lo = 0.40 * side;
  var total = 0.0, outer = 0.0;
  for (var y = 0; y < p.height; y++) {
    for (var x = 0; x < p.width; x++) {
      final dx = x + 0.5 - side / 2;
      final dy = y + 0.5 - side / 2;
      final a = p.a(x, y) / 255;
      total += a;
      if (dx * dx + dy * dy >= lo * lo) outer += a;
    }
  }
  return (total, outer);
}

_Diff _compare(Pixels ref, Pixels actual) {
  expect((actual.width, actual.height), (ref.width, ref.height));
  var sumA = 0.0, maxA = 0.0, sumC = 0.0;
  for (var y = 0; y < ref.height; y++) {
    for (var x = 0; x < ref.width; x++) {
      final ra = ref.a(x, y) / 255;
      final aa = actual.a(x, y) / 255;
      final da = (ra - aa).abs();
      sumA += da;
      if (da > maxA) maxA = da;
      sumC +=
          ((ref.r(x, y) / 255 * ra - actual.r(x, y) / 255 * aa).abs() +
              (ref.g(x, y) / 255 * ra - actual.g(x, y) / 255 * aa).abs() +
              (ref.b(x, y) / 255 * ra - actual.b(x, y) / 255 * aa).abs()) /
          3;
    }
  }
  final n = ref.width * ref.height;
  final (refTotal, refOuter) = _ink(ref);
  final (total, outer) = _ink(actual);
  return (
    meanAlpha: sumA / n,
    maxAlpha: maxA,
    meanColour: sumC / n,
    outerInk: outer / refOuter,
    totalInk: total / refTotal,
  );
}

void main() {
  test('references match the current SVGs', () {
    final manifest = jsonDecode(
      File('$_fixtures/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final hashes = (manifest['svgSha256']! as Map<String, Object?>)
        .cast<String, String>();
    expect(manifest['sizes'], [for (final (l, d) in _cases) l * d]..sort());
    for (final variant in ['dark', 'light']) {
      final name = 'zodiann-logo-on-$variant.svg';
      final current = sha256
          .convert(
            utf8.encode(
              File('$_assets/$name')
                  .readAsStringSync()
                  .replaceAll('\r\n', '\n'),
            ),
          )
          .toString();
      expect(
        hashes[name],
        current,
        reason:
            '$name changed; regenerate references: '
            'fvm dart run tool/logo/render_logo_references.dart',
      );
    }
  });

  final themes = {
    'dark': ZodiannTheme.graphite,
    'light': ZodiannTheme.porcelain,
  };
  for (final MapEntry(key: variant, value: theme) in themes.entries) {
    for (final (logical, dpr) in _cases) {
      final px = logical * dpr;
      testWidgets(
        'ZodiannLogo at $logical px, dpr $dpr, $variant theme matches Chrome',
        (tester) async {
          final ref = await _reference(tester, variant, px);
          final actual = await _render(tester, logical, dpr, theme);
          final d = _compare(ref, actual);
          if (Platform.environment['ZODIANN_LOGO_CALIBRATE'] != null) {
            stdout.writeln(
              'calibration $variant $px px: '
              'mean α ${d.meanAlpha.toStringAsFixed(5)}, '
              'max α ${d.maxAlpha.toStringAsFixed(3)}, '
              'mean colour ${d.meanColour.toStringAsFixed(5)}, '
              'outer ink ${d.outerInk.toStringAsFixed(3)}, '
              'total ink ${d.totalInk.toStringAsFixed(3)}',
            );
          }
          expect(d.meanAlpha, lessThanOrEqualTo(_meanAlphaCeiling[px]!));
          expect(d.maxAlpha, lessThanOrEqualTo(_maxAlphaCeiling[px]!));
          expect(d.meanColour, lessThanOrEqualTo(_meanColourCeiling[px]!));
          expect(
            d.outerInk,
            inInclusiveRange(_outerInkFloor, _outerInkCeiling),
          );
          expect(d.totalInk, inInclusiveRange(0.95, 1.10));
        },
      );
    }
  }
}
