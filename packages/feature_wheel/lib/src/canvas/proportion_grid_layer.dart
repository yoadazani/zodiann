import 'dart:ui' show Paint, PaintingStyle;

import '../geometry/wheel_proportions.dart';
import 'wheel_layer.dart';

/// The rings-only proportion grid (ZOD-WHL-001): the six radii of MASTER
/// §7.2's table, as thin concentric circles, with the inner disc filled.
///
/// Scaffolding: later layers draw the real sign band, ticks and bodies at
/// these radii.
final class ProportionGridLayer implements WheelLayer {
  /// The grid layer.
  const ProportionGridLayer();

  /// The halo is `line` at 50 % (MASTER §7.2).
  static const double _haloOpacity = 0.5;

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
      (p.haloRadius, s.line.withValues(alpha: s.line.a * _haloOpacity)),
      (p.signBandOuter, s.accentLine),
      (p.signBandInner, s.line),
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
