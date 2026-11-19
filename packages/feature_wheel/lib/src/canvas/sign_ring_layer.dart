import 'dart:math' as math;
import 'dart:ui' show Color, Offset, Paint, PaintingStyle, Path, Rect;

import 'package:astro_core/astro_core.dart' show ZodiacSign;
import 'package:flutter/painting.dart' show TextPainter, TextSpan;
import 'package:shared_ui/shared_ui.dart' show ZodiacColors, ZodiannGlyphs;

import '../geometry/wheel_proportions.dart';
import 'sign_element.dart';
import 'wheel_layer.dart';

/// The outer ring of 12 signs (ZOD-WHL-002, WH-1): twelve 30° sectors in
/// zodiacal order from Aries, each tinted by its element, with its glyph, its
/// 30° separator, and the sign band's two rims and the halo.
///
/// The drawing order is the kit's (`kit.js` `wheelSVG`): all sectors with
/// their glyphs and separators first, then the rims and the halo on top. The
/// ring never branches on text direction (L-6): signs run counter-clockwise
/// from the pointer-relative 0° in every language.
final class SignRingLayer implements WheelLayer {
  /// The sign ring layer.
  const SignRingLayer();

  /// Vertical shift of each glyph, as a fraction of the glyph size, that makes
  /// a laid-out text box read as the kit's `dominant-baseline: central`. A
  /// fraction (not pixels) so it scales with the wheel. Tuned against the
  /// Chrome reference in ZOD-WHL-002 Task 4.
  static const double glyphCentringFactor = 0;

  /// The halo is `line` at 50 % (`kit.js` `opacity:.5`, MASTER §7.2).
  static const double _haloOpacity = 0.5;

  static const double _sectorDegrees = 30;

  @override
  void paint(WheelPaintContext context) {
    final g = context.geometry;
    final p = g.proportions;
    final surfaces = context.surfaces;
    final zodiac = context.zodiac;
    final pointer = context.pointerLongitude;
    // One kit unit, so strokes scale with R like everything else.
    final unit = g.radius / WheelProportions.referenceRadius;
    final outer = g.ringRadius(p.signBandOuter);
    final inner = g.ringRadius(p.signBandInner);
    final outerRect = Rect.fromCircle(center: g.center, radius: outer);
    final innerRect = Rect.fromCircle(center: g.center, radius: inner);
    final midRing = (p.signBandOuter + p.signBandInner) / 2;
    final glyphSize = p.signGlyphSize * g.radius;
    Paint separator() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit
      ..color = surfaces.line;

    for (final sign in ZodiacSign.values) {
      final a0 = sign.index * _sectorDegrees;
      final a1 = a0 + _sectorDegrees;
      final color = _elementColor(zodiac, elementOf(sign));

      // The canvas measures arc angles clockwise from +x; a longitude's angle
      // is counter-clockwise (WheelGeometry.angleOf), hence the negations.
      final start = -g.angleOf(a0, pointerLongitude: pointer);
      const sweep = _sectorDegrees * math.pi / 180;
      final sector = Path()
        ..moveTo(
          g.offsetOf(a0, p.signBandOuter, pointerLongitude: pointer).dx,
          g.offsetOf(a0, p.signBandOuter, pointerLongitude: pointer).dy,
        )
        ..arcTo(outerRect, start, -sweep, false)
        ..lineTo(
          g.offsetOf(a1, p.signBandInner, pointerLongitude: pointer).dx,
          g.offsetOf(a1, p.signBandInner, pointerLongitude: pointer).dy,
        )
        ..arcTo(innerRect, start - sweep, sweep, false)
        ..close();
      context.canvas.drawPath(
        sector,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: zodiac.signTintOpacity),
      );

      final glyph = TextPainter(
        text: TextSpan(
          text: ZodiannGlyphs.signs[sign.index],
          style: context.glyphStyle.copyWith(fontSize: glyphSize, color: color),
        ),
        textDirection: context.textDirection,
      )..layout();
      final centre =
          g.offsetOf(
            a0 + _sectorDegrees / 2,
            midRing,
            pointerLongitude: pointer,
          ) +
          Offset(0, glyphCentringFactor * glyphSize);
      glyph.paint(
        context.canvas,
        centre - Offset(glyph.width / 2, glyph.height / 2),
      );
      glyph.dispose();

      context.canvas.drawLine(
        g.offsetOf(a0, p.signBandOuter, pointerLongitude: pointer),
        g.offsetOf(a0, p.signSeparatorInner, pointerLongitude: pointer),
        separator(),
      );
    }

    // One Paint per circle: a recording canvas keeps the object it was given.
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit
      ..color = color;
    context.canvas
      ..drawCircle(g.center, outer, stroke(surfaces.accentLine))
      ..drawCircle(g.center, inner, stroke(surfaces.line))
      ..drawCircle(
        g.center,
        g.ringRadius(p.haloRadius),
        stroke(surfaces.line.withValues(alpha: surfaces.line.a * _haloOpacity)),
      );
  }

  static Color _elementColor(ZodiacColors zodiac, ZodiacElement element) =>
      switch (element) {
        ZodiacElement.fire => zodiac.fire,
        ZodiacElement.earth => zodiac.earth,
        ZodiacElement.air => zodiac.air,
        ZodiacElement.water => zodiac.water,
      };
}
