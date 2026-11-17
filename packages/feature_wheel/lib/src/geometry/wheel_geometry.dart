import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

import 'wheel_proportions.dart';

/// A [WheelProportions] table bound to a concrete outer radius and centre:
/// the one place a longitude becomes a pixel (ZOD-WHL-001).
///
/// Pure: it reads no provider and no theme, so every value derived from it is
/// a function of its inputs (ARCH-3).
///
/// **Orientation (L-6, MASTER §7.2):** longitude increases counter-clockwise
/// and the fixed pointer is at 12 o'clock. It never mirrors, whatever the
/// text direction. The formula is the kit's (`kit.js` `wheelSVG`):
/// `angle = 90° + (longitude − pointerLongitude)`, `point = (r·cos, −r·sin)`.
@immutable
final class WheelGeometry {
  /// A geometry with explicit values; see [WheelGeometry.fit].
  const WheelGeometry({
    required this.proportions,
    required this.radius,
    required this.center,
  });

  /// The largest geometry whose extents (the pointer above, the focus ring
  /// around) fit [box], with the drawing centred in it. An empty or
  /// non-finite [box] gives a radius of 0.
  factory WheelGeometry.fit(Size box, WheelProportions proportions) {
    final height = proportions.extentTop + proportions.extentBottom;
    final fitted = math.min(
      box.width / (2 * proportions.extentX),
      box.height / height,
    );
    if (!box.width.isFinite ||
        !box.height.isFinite ||
        !fitted.isFinite ||
        fitted <= 0) {
      return WheelGeometry(
        proportions: proportions,
        radius: 0,
        center: Offset.zero,
      );
    }
    return WheelGeometry(
      proportions: proportions,
      radius: fitted,
      center: Offset(
        box.width / 2,
        (box.height - height * fitted) / 2 + proportions.extentTop * fitted,
      ),
    );
  }

  /// The proportion table this geometry reads from.
  final WheelProportions proportions;

  /// The outer radius `R`, in logical pixels (ARCH-8).
  final double radius;

  /// The wheel's centre in the canvas.
  final Offset center;

  /// A fraction of `R`, in pixels.
  double ringRadius(double fraction) => fraction * radius;

  /// The angle of [longitude], in radians, measured counter-clockwise from the
  /// +x axis, with [pointerLongitude] at 12 o'clock.
  double angleOf(double longitude, {double pointerLongitude = 0}) =>
      (90 + (longitude - pointerLongitude)) * math.pi / 180;

  /// Where [longitude] sits on the ring [ringFraction] (a fraction of `R`),
  /// centre included. Screen y grows downwards.
  Offset offsetOf(
    double longitude,
    double ringFraction, {
    double pointerLongitude = 0,
  }) {
    final angle = angleOf(longitude, pointerLongitude: pointerLongitude);
    final r = ringRadius(ringFraction);
    return center + Offset(r * math.cos(angle), -r * math.sin(angle));
  }

  @override
  bool operator ==(Object other) =>
      other is WheelGeometry &&
      other.proportions == proportions &&
      other.radius == radius &&
      other.center == center;

  @override
  int get hashCode => Object.hash(proportions, radius, center);
}
