// ZOD-FND-009: the drawing data of one Zodiann icon. Instances are generated
// from design-reference/zodiann/assets/icons/*.svg into zodiann_icons.g.dart;
// never write them by hand.
import 'dart:ui' show StrokeCap, StrokeJoin;

import 'package:flutter/foundation.dart' show listEquals;

/// One icon: its viewBox and its shapes, in SVG painting order.
///
/// Draw it with `ZodiannIcon`; the constants live in `ZodiannIcons`.
final class ZodiannIconData {
  const ZodiannIconData({
    required this.name,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.shapes,
  });

  /// The source file's name, without `.svg`.
  final String name;

  final double viewBoxWidth;
  final double viewBoxHeight;
  final List<ZodiannIconShape> shapes;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconData &&
      other.name == name &&
      other.viewBoxWidth == viewBoxWidth &&
      other.viewBoxHeight == viewBoxHeight &&
      listEquals(other.shapes, shapes);

  @override
  int get hashCode =>
      Object.hash(name, viewBoxWidth, viewBoxHeight, Object.hashAll(shapes));

  @override
  String toString() => 'ZodiannIconData($name)';
}

/// How a shape is painted, always in the icon's colour: filled, stroked, or
/// both (fill first, as SVG does).
final class ZodiannIconPaint {
  const ZodiannIconPaint({this.fill = false, this.stroke});

  final bool fill;

  /// Null when the shape is not stroked.
  final ZodiannIconStroke? stroke;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconPaint && other.fill == fill && other.stroke == stroke;

  @override
  int get hashCode => Object.hash(fill, stroke);
}

/// A stroke, its width in viewBox units.
final class ZodiannIconStroke {
  const ZodiannIconStroke(this.width, this.cap, this.join);

  final double width;
  final StrokeCap cap;
  final StrokeJoin join;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconStroke &&
      other.width == width &&
      other.cap == cap &&
      other.join == join;

  @override
  int get hashCode => Object.hash(width, cap, join);
}

/// A shape in viewBox coordinates.
sealed class ZodiannIconShape {
  const ZodiannIconShape(this.paint);

  final ZodiannIconPaint paint;
}

final class ZodiannIconPath extends ZodiannIconShape {
  const ZodiannIconPath(this.commands, super.paint);

  /// Absolute commands.
  final List<ZodiannPathCommand> commands;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconPath &&
      other.paint == paint &&
      listEquals(other.commands, commands);

  @override
  int get hashCode => Object.hash(Object.hashAll(commands), paint);
}

final class ZodiannIconCircle extends ZodiannIconShape {
  const ZodiannIconCircle(this.cx, this.cy, this.r, super.paint);

  final double cx;
  final double cy;
  final double r;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconCircle &&
      other.cx == cx &&
      other.cy == cy &&
      other.r == r &&
      other.paint == paint;

  @override
  int get hashCode => Object.hash(cx, cy, r, paint);
}

final class ZodiannIconRect extends ZodiannIconShape {
  const ZodiannIconRect(
    this.x,
    this.y,
    this.width,
    this.height,
    this.rx,
    this.ry,
    super.paint,
  );

  final double x;
  final double y;
  final double width;
  final double height;

  /// Corner radii, unclamped; the painter clamps them to half the side, as
  /// SVG does.
  final double rx;
  final double ry;

  @override
  bool operator ==(Object other) =>
      other is ZodiannIconRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.rx == rx &&
      other.ry == ry &&
      other.paint == paint;

  @override
  int get hashCode => Object.hash(x, y, width, height, rx, ry, paint);
}

/// An absolute path command in viewBox coordinates.
sealed class ZodiannPathCommand {
  const ZodiannPathCommand();
}

final class IconMoveTo extends ZodiannPathCommand {
  const IconMoveTo(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is IconMoveTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('M', x, y);
}

final class IconLineTo extends ZodiannPathCommand {
  const IconLineTo(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is IconLineTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('L', x, y);
}

final class IconCubicTo extends ZodiannPathCommand {
  const IconCubicTo(this.x1, this.y1, this.x2, this.y2, this.x, this.y);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is IconCubicTo &&
      other.x1 == x1 &&
      other.y1 == y1 &&
      other.x2 == x2 &&
      other.y2 == y2 &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash('C', x1, y1, x2, y2, x, y);
}

/// An elliptical arc to ([x], [y]), with `Path.arcToPoint` semantics.
final class IconArcTo extends ZodiannPathCommand {
  const IconArcTo(
    this.x,
    this.y,
    this.rx,
    this.ry,
    this.rotation,
    this.largeArc,
    this.clockwise,
  );

  final double x;
  final double y;
  final double rx;
  final double ry;

  /// The ellipse's x-axis rotation, in degrees.
  final double rotation;
  final bool largeArc;

  /// SVG's sweep flag 1: clockwise on screen, where y points down.
  final bool clockwise;

  @override
  bool operator ==(Object other) =>
      other is IconArcTo &&
      other.x == x &&
      other.y == y &&
      other.rx == rx &&
      other.ry == ry &&
      other.rotation == rotation &&
      other.largeArc == largeArc &&
      other.clockwise == clockwise;

  @override
  int get hashCode =>
      Object.hash('A', x, y, rx, ry, rotation, largeArc, clockwise);
}

final class IconClose extends ZodiannPathCommand {
  const IconClose();

  @override
  bool operator ==(Object other) => other is IconClose;

  @override
  int get hashCode => 'Z'.hashCode;
}
