import 'dart:ui';

import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const desktop = WheelProportions.desktop;
  const unit = WheelGeometry(
    proportions: desktop,
    radius: 300,
    center: Offset.zero,
  );

  Matcher at(double x, double y) => predicate<Offset>(
    (o) => (o.dx - x).abs() < 1e-9 && (o.dy - y).abs() < 1e-9,
    'offset ($x, $y)',
  );

  group('longitude increases counter-clockwise, pointer at 12 o\'clock', () {
    test('pointer 0: 0 is up, 90 left, 180 down, 270 right', () {
      expect(unit.offsetOf(0, 1), at(0, -300));
      expect(unit.offsetOf(90, 1), at(-300, 0));
      expect(unit.offsetOf(180, 1), at(0, 300));
      expect(unit.offsetOf(270, 1), at(300, 0));
    });

    test('the pointer longitude is the one at 12 o\'clock', () {
      expect(unit.offsetOf(90, 1, pointerLongitude: 90), at(0, -300));
      expect(unit.offsetOf(10, 1, pointerLongitude: 10), at(0, -300));
    });

    test('40 is 30° counter-clockwise of a pointer at 10', () {
      final expected = unit.offsetOf(30, 1);
      expect(
        unit.offsetOf(40, 1, pointerLongitude: 10),
        at(expected.dx, expected.dy),
      );
    });

    test(
      'negative and >= 360 longitudes land where their normal form does',
      () {
        final a = unit.offsetOf(-30, 1);
        final b = unit.offsetOf(330, 1);
        final c = unit.offsetOf(690, 1);
        expect(b, at(a.dx, a.dy));
        expect(c, at(a.dx, a.dy));
      },
    );

    test('the centre is added', () {
      const g = WheelGeometry(
        proportions: desktop,
        radius: 300,
        center: Offset(100, 50),
      );
      expect(g.offsetOf(0, 1), at(100, -250));
      expect(g.offsetOf(90, 1), at(-200, 50));
      expect(g.offsetOf(180, 1), at(100, 350));
      expect(g.offsetOf(270, 1), at(400, 50));
    });

    test('angleOf is the kit\'s (90 + lon - pointer) degrees in radians', () {
      expect(unit.angleOf(0), closeTo(3.141592653589793 / 2, 1e-12));
      expect(
        unit.angleOf(40, pointerLongitude: 10),
        closeTo((90 + 30) * 3.141592653589793 / 180, 1e-12),
      );
    });
  });

  test('ringRadius scales a fraction by the radius', () {
    expect(unit.ringRadius(desktop.signBandOuter), closeTo(296.0, 1e-9));
    expect(unit.ringRadius(0.5), closeTo(150, 1e-9));
  });

  group('fit', () {
    test('the kit viewBox box (644 x 656) gives R 300, origin (322, 334)', () {
      final g = WheelGeometry.fit(const Size(644, 656), desktop);
      expect(g.radius, closeTo(300, 1e-9));
      expect(g.center.dx, closeTo(322, 1e-9));
      expect(g.center.dy, closeTo(334, 1e-9));
    });

    test('a wider box centres horizontally', () {
      final g = WheelGeometry.fit(const Size(1000, 656), desktop);
      expect(g.radius, closeTo(300, 1e-9));
      expect(g.center.dx, closeTo(500, 1e-9));
      expect(g.center.dy, closeTo(334, 1e-9));
    });

    test('a taller box centres vertically', () {
      final g = WheelGeometry.fit(const Size(644, 1000), desktop);
      expect(g.radius, closeTo(300, 1e-9));
      expect(g.center.dx, closeTo(322, 1e-9));
      expect(g.center.dy, closeTo((1000 - 656) / 2 + 334, 1e-9));
    });

    test('half the box gives half the radius', () {
      final g = WheelGeometry.fit(const Size(322, 328), desktop);
      expect(g.radius, closeTo(150, 1e-9));
    });

    test('empty and non-finite boxes give radius 0', () {
      for (final size in [
        Size.zero,
        const Size(0, 100),
        const Size(100, 0),
        const Size(double.nan, 100),
        const Size(double.infinity, 100),
        const Size(100, double.infinity),
      ]) {
        expect(WheelGeometry.fit(size, desktop).radius, 0, reason: '$size');
      }
    });
  });

  test('value equality and hashCode', () {
    const a = WheelGeometry(
      proportions: desktop,
      radius: 10,
      center: Offset(1, 2),
    );
    const b = WheelGeometry(
      proportions: desktop,
      radius: 10,
      center: Offset(1, 2),
    );
    const c = WheelGeometry(
      proportions: WheelProportions.compact,
      radius: 10,
      center: Offset(1, 2),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
