import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/wheel_harness.dart';

/// One `drawCircle` of the given [style] at [center] with a radius within
/// [tolerance]. The `circle` matcher compares exactly and cannot take a
/// tolerance, hence the predicate.
bool Function(Symbol, List<dynamic>) circle({
  required Offset center,
  required double radius,
  required double tolerance,
  required PaintingStyle style,
}) => (method, args) {
  if (method != #drawCircle) return false;
  final c = args[0] as Offset;
  final r = args[1] as double;
  final paint = args[2] as Paint;
  return (c.dx - center.dx).abs() < 1e-6 &&
      (c.dy - center.dy).abs() < 1e-6 &&
      (r - radius).abs() <= tolerance &&
      paint.style == style;
};

void main() {
  // MASTER §7.2's printed fractions, in grid order: halo, rim, band inner,
  // body discs, body labels, inner disc. Not read from the table object.
  const printed = {
    'desktop': [1.02, 0.987, 0.833, 0.64, 0.547, 0.453],
    'compact': [1.02, 0.987, 0.80, 0.60, 0.467, 0.373],
  };
  const tables = {
    'desktop': WheelProportions.desktop,
    'compact': WheelProportions.compact,
  };
  // (box, R, centre): the kit viewBox at 1:1 and at half size.
  const boxes = [
    (Size(644, 656), 300.0, Offset(322, 334)),
    (Size(322, 328), 150.0, Offset(161, 167)),
  ];

  for (final name in tables.keys) {
    for (final (box, r, center) in boxes) {
      testWidgets('$name grid at ${box.width.toInt()} x ${box.height.toInt()} '
          'draws the six rings at the printed fractions', (tester) async {
        await pumpWheelCanvas(tester, size: box, proportions: tables[name]!);
        final f = printed[name]!;
        final tol = 0.0005 * r;
        var pattern = paints
          ..something(
            circle(
              center: center,
              radius: f[5] * r,
              tolerance: tol,
              style: PaintingStyle.fill,
            ),
          );
        for (final fraction in f) {
          pattern = pattern
            ..something(
              circle(
                center: center,
                radius: fraction * r,
                tolerance: tol,
                style: PaintingStyle.stroke,
              ),
            );
        }
        expect(wheelRenderObject(tester), pattern);
      });
    }
  }

  testWidgets('a ring 2 % off the printed radius is rejected', (tester) async {
    await pumpWheelCanvas(tester);
    final tol = 0.0005 * 300;
    expect(
      wheelRenderObject(tester),
      isNot(
        paints..something(
          circle(
            center: const Offset(322, 334),
            radius: 0.987 * 300 * 1.02,
            tolerance: tol,
            style: PaintingStyle.stroke,
          ),
        ),
      ),
    );
  });
}
