import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kit units: `design-reference/zodiann/_source/kit.js` `wheelSVG`, R = 300.
double units(double fraction) => fraction * WheelProportions.referenceRadius;

void main() {
  signSeparatorTests();
  tickStrokeTests();
  const desktop = WheelProportions.desktop;
  const compact = WheelProportions.compact;

  group('MASTER §7.2 printed fractions (tolerance 0.0005)', () {
    test('desktop', () {
      expect(desktop.haloRadius, closeTo(1.02, 0.0005));
      expect(desktop.signBandOuter, closeTo(0.987, 0.0005));
      expect(desktop.signBandInner, closeTo(0.833, 0.0005));
      expect(desktop.bodyDiscRadiusAt, closeTo(0.64, 0.0005));
      expect(desktop.bodyLabelRadiusAt, closeTo(0.547, 0.0005));
      expect(desktop.innerDiscRadius, closeTo(0.453, 0.0005));
    });

    test('compact', () {
      expect(compact.haloRadius, closeTo(1.02, 0.0005));
      expect(compact.signBandOuter, closeTo(0.987, 0.0005));
      expect(compact.signBandInner, closeTo(0.80, 0.0005));
      expect(compact.bodyDiscRadiusAt, closeTo(0.60, 0.0005));
      expect(compact.bodyLabelRadiusAt, closeTo(0.467, 0.0005));
      expect(compact.innerDiscRadius, closeTo(0.373, 0.0005));
    });
  });

  group('kit units (closeTo, never ==)', () {
    test('desktop rings', () {
      expect(units(desktop.haloRadius), closeTo(306, 1e-9));
      expect(units(desktop.signBandOuter), closeTo(296, 1e-9));
      expect(units(desktop.signBandInner), closeTo(250, 1e-9));
      expect(units(desktop.tickInnerEdge), closeTo(250, 1e-9));
      expect(units(desktop.degreeNumberRadius), closeTo(224, 1e-9));
      expect(units(desktop.bodyDiscRadiusAt), closeTo(192, 1e-9));
      expect(units(desktop.bodyLabelRadiusAt), closeTo(164, 1e-9));
      expect(units(desktop.innerDiscRadius), closeTo(136, 1e-9));
    });

    test('compact rings', () {
      expect(units(compact.haloRadius), closeTo(306, 1e-9));
      expect(units(compact.signBandOuter), closeTo(296, 1e-9));
      expect(units(compact.signBandInner), closeTo(240, 1e-9));
      expect(units(compact.tickInnerEdge), closeTo(240, 1e-9));
      expect(units(compact.degreeNumberRadius), closeTo(214, 1e-9));
      expect(units(compact.bodyDiscRadiusAt), closeTo(180, 1e-9));
      expect(units(compact.bodyLabelRadiusAt), closeTo(140, 1e-9));
      expect(units(compact.innerDiscRadius), closeTo(112, 1e-9));
    });

    test('tick lengths are the same in both tables', () {
      for (final p in [desktop, compact]) {
        expect(units(p.tickLengthDegree), closeTo(5, 1e-9));
        expect(units(p.tickLengthFive), closeTo(9, 1e-9));
        expect(units(p.tickLengthTen), closeTo(14, 1e-9));
      }
    });

    test('sizes: desktop | compact', () {
      expect(units(desktop.signGlyphSize), closeTo(21, 1e-9));
      expect(units(compact.signGlyphSize), closeTo(30, 1e-9));
      expect(units(desktop.bodyGlyphSize), closeTo(17, 1e-9));
      expect(units(compact.bodyGlyphSize), closeTo(27, 1e-9));
      expect(units(desktop.bodyDiscRadius), closeTo(14, 1e-9));
      expect(units(compact.bodyDiscRadius), closeTo(21, 1e-9));
      expect(units(desktop.bodyLabelFontSize), closeTo(11.5, 1e-9));
      expect(units(compact.bodyLabelFontSize), closeTo(19, 1e-9));
      expect(units(desktop.degreeNumberFontSize), closeTo(9.5, 1e-9));
      expect(units(compact.degreeNumberFontSize), closeTo(14, 1e-9));
      expect(units(desktop.trueDotRadius), closeTo(3.2, 1e-9));
      expect(units(compact.trueDotRadius), closeTo(4.5, 1e-9));
    });
  });

  test('halo, rim and extents are shared by the two tables', () {
    expect(compact.haloRadius, desktop.haloRadius);
    expect(compact.signBandOuter, desktop.signBandOuter);
    expect(compact.extentX, desktop.extentX);
    expect(compact.extentTop, desktop.extentTop);
    expect(compact.extentBottom, desktop.extentBottom);
  });

  test('extents are the kit viewBox (-322 -334 644 656) over R', () {
    expect(units(desktop.extentX), closeTo(322, 1e-9));
    expect(units(desktop.extentTop), closeTo(334, 1e-9));
    expect(units(desktop.extentBottom), closeTo(322, 1e-9));
    expect(desktop.aspectRatio, closeTo(644 / 656, 1e-9));
  });

  test('rings are strictly nested in both tables', () {
    for (final p in [desktop, compact]) {
      expect(p.haloRadius, greaterThan(p.signBandOuter));
      expect(p.signBandOuter, greaterThan(p.signBandInner));
      expect(p.signBandInner, greaterThan(p.bodyDiscRadiusAt));
      expect(p.bodyDiscRadiusAt, greaterThan(p.bodyLabelRadiusAt));
      expect(p.bodyLabelRadiusAt, greaterThan(p.innerDiscRadius));
      expect(p.innerDiscRadius, greaterThan(0));
    }
  });
}

void signSeparatorTests() {
  group('sign separator inner radius (kit rTick - 18)', () {
    test('exact literals', () {
      expect(WheelProportions.desktop.signSeparatorInner, 232 / 300);
      expect(WheelProportions.compact.signSeparatorInner, 222 / 300);
    });

    test('is 18 kit units inside the band edge (closeTo, never ==)', () {
      for (final p in [WheelProportions.desktop, WheelProportions.compact]) {
        expect(
          p.signSeparatorInner,
          closeTo(p.signBandInner - 18 / 300, 1e-12),
        );
      }
    });

    test('takes part in equality and hash', () {
      const d = WheelProportions.desktop;
      final other = variant(d, signSeparatorInner: d.signSeparatorInner + 0.01);
      expect(other == d, isFalse);
      expect(other.hashCode, isNot(d.hashCode));
    });
  });
}

/// [base] with some fields replaced (every field listed, so a field added to
/// the table is a compile error here until it is handled).
WheelProportions variant(
  WheelProportions base, {
  double? signSeparatorInner,
  double? tickStrokeDegree,
  double? tickStrokeFive,
  double? tickStrokeTen,
}) => WheelProportions(
  haloRadius: base.haloRadius,
  signBandOuter: base.signBandOuter,
  signBandInner: base.signBandInner,
  signSeparatorInner: signSeparatorInner ?? base.signSeparatorInner,
  tickInnerEdge: base.tickInnerEdge,
  tickLengthDegree: base.tickLengthDegree,
  tickLengthFive: base.tickLengthFive,
  tickLengthTen: base.tickLengthTen,
  tickStrokeDegree: tickStrokeDegree ?? base.tickStrokeDegree,
  tickStrokeFive: tickStrokeFive ?? base.tickStrokeFive,
  tickStrokeTen: tickStrokeTen ?? base.tickStrokeTen,
  degreeNumberRadius: base.degreeNumberRadius,
  degreeNumberFontSize: base.degreeNumberFontSize,
  signGlyphSize: base.signGlyphSize,
  bodyDiscRadiusAt: base.bodyDiscRadiusAt,
  bodyDiscRadius: base.bodyDiscRadius,
  bodyGlyphSize: base.bodyGlyphSize,
  bodyLabelRadiusAt: base.bodyLabelRadiusAt,
  bodyLabelFontSize: base.bodyLabelFontSize,
  innerDiscRadius: base.innerDiscRadius,
  trueDotRadius: base.trueDotRadius,
  extentX: base.extentX,
  extentTop: base.extentTop,
  extentBottom: base.extentBottom,
);

void tickStrokeTests() {
  group('tick stroke widths (kit.css .tick 0.8, .t5 1, .t10 1.2)', () {
    test('exact literals, both tables', () {
      for (final p in [WheelProportions.desktop, WheelProportions.compact]) {
        expect(p.tickStrokeDegree, 0.8 / 300);
        expect(p.tickStrokeFive, 1 / 300);
        expect(p.tickStrokeTen, 1.2 / 300);
      }
    });

    test('each takes part in equality and hash', () {
      const d = WheelProportions.desktop;
      for (final other in [
        variant(d, tickStrokeDegree: d.tickStrokeDegree + 0.01),
        variant(d, tickStrokeFive: d.tickStrokeFive + 0.01),
        variant(d, tickStrokeTen: d.tickStrokeTen + 0.01),
      ]) {
        expect(other == d, isFalse);
        expect(other.hashCode, isNot(d.hashCode));
      }
    });
  });
}
