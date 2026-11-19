import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;
import 'package:shared_ui/shared_ui.dart'
    show ZodiacColors, ZodiannSurfaces, ZodiannTextStyles;

import '../geometry/wheel_proportions.dart';
import '../state/wheel_state.dart';
import 'degree_scale_layer.dart';
import 'sign_ring_layer.dart';
import 'wheel_layer.dart';
import 'wheel_painter.dart';

/// The wheel's single canvas (ARCH-5, L-6): one [RepaintBoundary] around one
/// [CustomPaint], in a fixed LTR island so the drawing never mirrors.
///
/// It fills the space it is given, the drawing fitted and centred in it. With
/// one unbounded side it takes that side from the other and the drawing's
/// aspect ratio; with both unbounded it is empty.
class WheelCanvas extends StatelessWidget {
  /// A canvas drawing [state] with the [proportions] table.
  const WheelCanvas({
    super.key,
    required this.proportions,
    required this.state,
    this.layers = const [SignRingLayer(), DegreeScaleLayer()],
  });

  /// The desktop or compact table.
  final WheelProportions proportions;

  /// The screen state.
  final WheelState state;

  /// The paint steps, bottom first.
  final List<WheelLayer> layers;

  Size _sizeFor(BoxConstraints c) {
    final aspect = proportions.aspectRatio;
    if (c.hasBoundedWidth && c.hasBoundedHeight) return c.biggest;
    if (c.hasBoundedWidth) return Size(c.maxWidth, c.maxWidth / aspect);
    if (c.hasBoundedHeight) return Size(c.maxHeight * aspect, c.maxHeight);
    return Size.zero;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => CustomPaint(
            size: _sizeFor(constraints),
            painter: WheelPainter(
              proportions: proportions,
              state: state,
              surfaces: Theme.of(context).extension<ZodiannSurfaces>()!,
              zodiac: Theme.of(context).extension<ZodiacColors>()!,
              glyphStyle: Theme.of(context)
                  .extension<ZodiannTextStyles>()!
                  .glyph,
              labelStyle: Theme.of(context)
                  .extension<ZodiannTextStyles>()!
                  .micro,
              textDirection: Directionality.of(context),
              layers: layers,
            ),
          ),
        ),
      ),
    ),
  );
}
