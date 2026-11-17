import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_ui/shared_ui.dart' show ZodiannSurfaces;

import '../geometry/wheel_geometry.dart';
import '../geometry/wheel_proportions.dart';
import '../state/wheel_state.dart';
import 'wheel_layer.dart';

/// The one painter of the whole wheel (ARCH-5): it fits the drawing into its
/// box and runs its [layers] in order. It reads no provider; everything it
/// draws is a function of its fields.
class WheelPainter extends CustomPainter {
  /// A painter for [state], drawn with the [proportions] table.
  const WheelPainter({
    required this.proportions,
    required this.state,
    required this.surfaces,
    required this.textDirection,
    required this.layers,
  });

  /// The desktop or compact table.
  final WheelProportions proportions;

  /// The screen state.
  final WheelState state;

  /// The theme's surface colours.
  final ZodiannSurfaces surfaces;

  /// The direction handed to layers (LTR, L-6).
  final TextDirection textDirection;

  /// The paint steps, bottom first.
  final List<WheelLayer> layers;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = WheelGeometry.fit(size, proportions);
    if (geometry.radius <= 0) return;
    final context = WheelPaintContext(
      canvas: canvas,
      geometry: geometry,
      state: state,
      surfaces: surfaces,
      textDirection: textDirection,
    );
    for (final layer in layers) {
      layer.paint(context);
    }
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.proportions != proportions ||
      oldDelegate.state != state ||
      oldDelegate.surfaces != surfaces ||
      oldDelegate.textDirection != textDirection ||
      !listEquals(oldDelegate.layers, layers);
}
