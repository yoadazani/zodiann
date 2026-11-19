import 'dart:ui' show Canvas;

import 'package:flutter/painting.dart' show TextDirection, TextStyle;
import 'package:shared_ui/shared_ui.dart' show ZodiacColors, ZodiannSurfaces;

import '../geometry/wheel_geometry.dart';
import '../state/wheel_state.dart';

/// What the `WheelPainter` hands a layer: where to draw, how big, with what
/// colours, and in which text direction (always LTR, L-6).
final class WheelPaintContext {
  /// A context for one paint pass.
  const WheelPaintContext({
    required this.canvas,
    required this.geometry,
    required this.state,
    required this.surfaces,
    required this.zodiac,
    required this.glyphStyle,
    required this.labelStyle,
    required this.textDirection,
  });

  /// The canvas to draw on.
  final Canvas canvas;

  /// The proportion table bound to this pass's radius and centre.
  final WheelGeometry geometry;

  /// The screen state being drawn.
  final WheelState state;

  /// The theme's surface colours (ARCH-7: layers never hold colour literals).
  final ZodiannSurfaces surfaces;

  /// The element colours and the sign tint opacity (MASTER §2.3).
  final ZodiacColors zodiac;

  /// The glyph text role (`ZodiannTextStyles.glyph`): the bundled symbol fonts,
  /// line height 1. A layer sets its own size and colour with `copyWith`.
  final TextStyle glyphStyle;

  /// The label text role (`ZodiannTextStyles.micro`: the UI family for the
  /// script, tabular figures). A layer sets its own size and colour with
  /// `copyWith`.
  final TextStyle labelStyle;

  /// The direction for any text a layer draws. Always `TextDirection.ltr`:
  /// the wheel never mirrors.
  final TextDirection textDirection;

  /// The longitude under the fixed pointer.
  double get pointerLongitude => state.pointerLongitude;
}

/// One ordered paint step of the single wheel painter. WHL-002 to WHL-009 each
/// add a layer; none adds a widget (ARCH-5).
abstract interface class WheelLayer {
  /// Paints this layer into [context]'s canvas.
  void paint(WheelPaintContext context);
}
