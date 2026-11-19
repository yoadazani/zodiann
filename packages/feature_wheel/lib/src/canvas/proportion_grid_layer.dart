import 'dart:ui' show Paint, PaintingStyle;

import '../geometry/wheel_proportions.dart';
import 'wheel_layer.dart';

/// The remaining scaffolding rings (ZOD-WHL-001), opt-in since ZOD-WHL-002: the
/// inner disc (filled, then outlined) and the two body rings at 0.64 R and
/// 0.547 R, which have no counterpart in the kit. The sign band's rims and the
/// halo now belong to `SignRingLayer`. The inner-disc fill (the kit's `.inner`)
/// is to be taken by ZOD-WHL-004; the body rings disappear with this layer.
final class ProportionGridLayer implements WheelLayer {
  /// The grid layer.
  const ProportionGridLayer();

  @override
  void paint(WheelPaintContext context) {
    final g = context.geometry;
    final p = g.proportions;
    final s = context.surfaces;
    // One kit unit, so the stroke scales with R like everything else.
    final width = g.radius / WheelProportions.referenceRadius;

    context.canvas.drawCircle(
      g.center,
      g.ringRadius(p.innerDiscRadius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = s.bgRaised,
    );

    final rings = [
      (p.bodyDiscRadiusAt, s.line),
      (p.bodyLabelRadiusAt, s.line),
      (p.innerDiscRadius, s.line),
    ];
    for (final (fraction, color) in rings) {
      context.canvas.drawCircle(
        g.center,
        g.ringRadius(fraction),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color,
      );
    }
  }
}
