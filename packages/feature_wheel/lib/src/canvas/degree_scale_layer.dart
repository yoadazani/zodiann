import 'dart:ui' show Offset, Paint, PaintingStyle, StrokeCap;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'wheel_layer.dart';

/// The three tick weights of the degree scale (`kit.js` `wheelSVG`: `t10`,
/// `t5`, and the plain tick).
enum TickClass {
  /// Every degree that is not a multiple of 5: the short tick (5 units).
  degree,

  /// Every multiple of 5° that is not a multiple of 10° (9 units).
  five,

  /// Every multiple of 10° that is not a multiple of 30° (14 units).
  ten,
}

/// One tick of the scale: its degree and its weight.
final class DegreeTick {
  /// The tick at [degree] (1…359, never a multiple of 30°) of class
  /// [tickClass].
  const DegreeTick(this.degree, this.tickClass);

  /// The longitude of the tick, in whole degrees.
  final int degree;

  /// Its weight, which gives its length, width and colour.
  final TickClass tickClass;
}

const int _degreesInCircle = 360;
const int _signDegrees = 30;
const int _tenDegrees = 10;
const int _fiveDegrees = 5;

/// The 348 ticks of the scale, ascending: every whole degree except the
/// multiples of 30°, which are the sign separators (`kit.js:318`).
List<DegreeTick> degreeTicks() => [
  for (var d = 0; d < _degreesInCircle; d++)
    if (d % _signDegrees != 0)
      DegreeTick(
        d,
        d % _tenDegrees == 0
            ? TickClass.ten
            : (d % _fiveDegrees == 0 ? TickClass.five : TickClass.degree),
      ),
];

/// The degree scale (ZOD-WHL-003, WH-2): a tick for every degree except the
/// multiples of 30°, running inward from the sign band's inner edge, and a
/// "10" or "20" label at every multiple of 10° inside each sign.
///
/// The drawing order is the kit's (`kit.js` `wheelSVG`): a tick, then its
/// label when it has one. It follows the kit's colours and widths (decision
/// P1): the 1° and 5° ticks in `text-3`, the 10° ticks in `text-2` and
/// heavier, the labels in `text-3`. The scale never branches on text
/// direction (L-6): the digits are Western and upright, left to right.
final class DegreeScaleLayer implements WheelLayer {
  /// The degree scale layer.
  const DegreeScaleLayer();

  /// Vertical shift of each label, as a fraction of the label size, that makes
  /// a laid-out text box read as the kit's `dominant-baseline: central`. A
  /// fraction (not pixels) so it scales with the wheel. Tuned against the
  /// Chrome reference in ZOD-WHL-003 Task 3.
  static const double labelCentringFactor = 0;

  /// The style of a degree label for [context]: the label role at the table's
  /// size (never scaled by the text scale) in `text-3`.
  static TextStyle labelStyleOf(WheelPaintContext context) =>
      context.labelStyle.copyWith(
        fontSize:
            context.geometry.proportions.degreeNumberFontSize *
            context.geometry.radius,
        color: context.surfaces.text3,
      );

  @override
  void paint(WheelPaintContext context) {
    final g = context.geometry;
    final p = g.proportions;
    final surfaces = context.surfaces;
    final pointer = context.pointerLongitude;
    final labelStyle = labelStyleOf(context);

    for (final tick in degreeTicks()) {
      final (length, width, color) = switch (tick.tickClass) {
        TickClass.degree => (
          p.tickLengthDegree,
          p.tickStrokeDegree,
          surfaces.text3,
        ),
        TickClass.five => (p.tickLengthFive, p.tickStrokeFive, surfaces.text3),
        TickClass.ten => (p.tickLengthTen, p.tickStrokeTen, surfaces.text2),
      };
      final longitude = tick.degree.toDouble();
      // One Paint per line: a recording canvas keeps the object it was given.
      context.canvas.drawLine(
        g.offsetOf(longitude, p.tickInnerEdge, pointerLongitude: pointer),
        g.offsetOf(
          longitude,
          p.tickInnerEdge - length,
          pointerLongitude: pointer,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = width * g.radius
          ..color = color,
      );

      if (tick.tickClass != TickClass.ten) continue;
      final label = TextPainter(
        text: TextSpan(
          text: (tick.degree % _signDegrees).toString(),
          style: labelStyle,
        ),
        textDirection: context.textDirection,
      )..layout();
      final centre =
          g.offsetOf(
            longitude,
            p.degreeNumberRadius,
            pointerLongitude: pointer,
          ) +
          Offset(0, labelCentringFactor * labelStyle.fontSize!);
      label.paint(
        context.canvas,
        centre - Offset(label.width / 2, label.height / 2),
      );
      label.dispose();
    }
  }
}
