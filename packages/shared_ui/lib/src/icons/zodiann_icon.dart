// ZOD-FND-009: draws the Zodiann icon set (MASTER §11) from the drawing data
// generated out of design-reference/zodiann/assets/icons/*.svg. No SVG or
// network package is involved (product-owner decision, 2026-11-15).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import 'zodiann_icon_data.dart';
import 'zodiann_icons.g.dart';

/// One Zodiann icon, e.g. `ZodiannIcon(ZodiannIcons.calendar)`.
///
/// Like Material's `Icon`, it takes its size and colour from the ambient
/// `IconTheme` unless given:
/// - size: [size], else the nearest `IconTheme`'s size, else
///   `ZodiannSize.icon` (20). The Zodiann themes set 20; `ZodiannButton`
///   sets `ZodiannSize.iconSmall` (16) for its icon slot. Material
///   containers (`IconButton`, `AppBar`) inject their own size (24), so pass
///   [size] there.
/// - colour: [color], else the `IconTheme` colour (the theme's `text`),
///   multiplied by the `IconTheme` opacity.
///
/// The icon draws at its size, centred in whatever box it is given; it is
/// never stretched. It is never mirrored: for back / forward use
/// [iconBack] / [iconFwd].
class ZodiannIcon extends StatelessWidget {
  const ZodiannIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final ZodiannIconData icon;
  final double? size;
  final Color? color;

  /// Announced by screen readers; without one the icon is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    // IconTheme.of fills a missing size with Material's fallback (24); read
    // the raw inherited data so an unset size means ZodiannSize.icon.
    final resolvedSize =
        size ??
        context.dependOnInheritedWidgetOfExactType<IconTheme>()?.data.size ??
        ZodiannSize.icon;
    final base = color ?? theme.color!;
    final opacity = theme.opacity ?? 1;
    final resolvedColor = opacity == 1
        ? base
        : base.withValues(alpha: base.a * opacity);
    final drawing = ExcludeSemantics(
      child: SizedBox.square(
        dimension: resolvedSize,
        child: CustomPaint(
          painter: ZodiannIconPainter(
            icon: icon,
            size: resolvedSize,
            color: resolvedColor,
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return drawing;
    return Semantics(label: label, image: true, child: drawing);
  }
}

/// Paints [icon] at [size] logical pixels in [color], centred in the canvas.
///
/// SVG semantics: the viewBox is scaled uniformly (stroke widths with it),
/// each shape is filled before it is stroked, and rect corner radii are
/// clamped to half the side.
class ZodiannIconPainter extends CustomPainter {
  const ZodiannIconPainter({
    required this.icon,
    required this.size,
    required this.color,
  });

  final ZodiannIconData icon;
  final double size;
  final Color color;

  @override
  void paint(Canvas canvas, Size box) {
    final scale = size / math.max(icon.viewBoxWidth, icon.viewBoxHeight);
    final left = (box.width - icon.viewBoxWidth * scale) / 2;
    final top = (box.height - icon.viewBoxHeight * scale) / 2;
    canvas
      ..save()
      ..translate(left, top)
      ..scale(scale);
    for (final shape in icon.shapes) {
      final path = _path(shape);
      final paint = shape.paint;
      if (paint.fill) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      }
      final stroke = paint.stroke;
      if (stroke != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.width
            ..strokeCap = stroke.cap
            ..strokeJoin = stroke.join
            ..isAntiAlias = true,
        );
      }
    }
    canvas.restore();
  }

  static Path _path(ZodiannIconShape shape) => switch (shape) {
    ZodiannIconCircle(:final cx, :final cy, :final r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    ZodiannIconRect(
      :final x,
      :final y,
      :final width,
      :final height,
      :final rx,
      :final ry,
    ) =>
      () {
        final halfWidth = width / 2;
        final halfHeight = height / 2;
        final cornerX = math.min(rx, halfWidth);
        final cornerY = math.min(ry, halfHeight);
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, width, height),
            Radius.elliptical(cornerX, cornerY),
          ),
        );
      }(),
    ZodiannIconPath(:final commands) => () {
      final path = Path();
      for (final command in commands) {
        switch (command) {
          case IconMoveTo(:final x, :final y):
            path.moveTo(x, y);
          case IconLineTo(:final x, :final y):
            path.lineTo(x, y);
          case IconCubicTo(
            :final x1,
            :final y1,
            :final x2,
            :final y2,
            :final x,
            :final y,
          ):
            path.cubicTo(x1, y1, x2, y2, x, y);
          case IconArcTo(
            :final x,
            :final y,
            :final rx,
            :final ry,
            :final rotation,
            :final largeArc,
            :final clockwise,
          ):
            path.arcToPoint(
              Offset(x, y),
              radius: Radius.elliptical(rx, ry),
              rotation: rotation,
              largeArc: largeArc,
              clockwise: clockwise,
            );
          case IconClose():
            path.close();
        }
      }
      return path;
    }(),
  };

  @override
  bool shouldRepaint(ZodiannIconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.size != size ||
      oldDelegate.color != color;
}

/// [ltr] or [rtl], whichever matches the nearest `Directionality`, resolved
/// at every build.
class ZodiannDirectionalIcon extends StatelessWidget {
  const ZodiannDirectionalIcon({
    super.key,
    required this.ltr,
    required this.rtl,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final ZodiannIconData ltr;
  final ZodiannIconData rtl;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => ZodiannIcon(
    Directionality.of(context) == TextDirection.rtl ? rtl : ltr,
    size: size,
    color: color,
    semanticLabel: semanticLabel,
  );
}

/// "Back" in the reading direction: `chevL` in English, `chevR` in Hebrew
/// (MASTER §11; kit.js `iconBack`).
///
/// It follows the *nearest* `Directionality`. Keep it outside forced-LTR
/// islands (L-7 dates and numbers), or a Hebrew screen gets the English
/// chevron.
Widget iconBack({double? size, Color? color, String? semanticLabel}) =>
    ZodiannDirectionalIcon(
      ltr: ZodiannIcons.chevL,
      rtl: ZodiannIcons.chevR,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

/// "Forward" in the reading direction: `chevR` in English, `chevL` in
/// Hebrew (MASTER §11; kit.js `iconFwd`). Like [iconBack], it follows the
/// nearest `Directionality`.
Widget iconFwd({double? size, Color? color, String? semanticLabel}) =>
    ZodiannDirectionalIcon(
      ltr: ZodiannIcons.chevR,
      rtl: ZodiannIcons.chevL,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
