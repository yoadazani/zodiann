// ZOD-FND-009: a strict parser for the Zodiann icon SVGs
// (design-reference/zodiann/assets/icons/*.svg), producing an intermediate
// representation that tool/gen_icons.dart emits as Dart drawing data.
//
// Only the subset the design icons use is accepted. Anything else throws
// IconGeneratorException naming the file and the culprit, so no drawing
// instruction is ever dropped silently (product-owner decision, 2026-11-15).
import 'package:xml/xml.dart';

/// A rejected icon source or generator failure.
final class IconGeneratorException implements Exception {
  IconGeneratorException(this.message);

  final String message;

  @override
  String toString() => 'IconGeneratorException: $message';
}

/// One parsed icon.
final class SvgIcon {
  const SvgIcon(this.name, this.viewBoxWidth, this.viewBoxHeight, this.shapes);

  final String name;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final List<SvgShape> shapes;

  @override
  bool operator ==(Object other) =>
      other is SvgIcon &&
      other.name == name &&
      other.viewBoxWidth == viewBoxWidth &&
      other.viewBoxHeight == viewBoxHeight &&
      _listEquals(other.shapes, shapes);

  @override
  int get hashCode =>
      Object.hash(name, viewBoxWidth, viewBoxHeight, Object.hashAll(shapes));
}

/// A shape's paint: filled with the current colour, stroked, or both.
final class SvgPaint {
  const SvgPaint({required this.fill, this.stroke});

  final bool fill;

  /// Null for `stroke="none"`.
  final SvgStroke? stroke;

  @override
  bool operator ==(Object other) =>
      other is SvgPaint && other.fill == fill && other.stroke == stroke;

  @override
  int get hashCode => Object.hash(fill, stroke);

  @override
  String toString() => 'SvgPaint(fill: $fill, stroke: $stroke)';
}

/// A stroke in the current colour.
final class SvgStroke {
  const SvgStroke(this.width, this.cap, this.join);

  /// In viewBox units.
  final double width;

  /// `butt`, `round` or `square`.
  final String cap;

  /// `miter`, `round` or `bevel`.
  final String join;

  @override
  bool operator ==(Object other) =>
      other is SvgStroke &&
      other.width == width &&
      other.cap == cap &&
      other.join == join;

  @override
  int get hashCode => Object.hash(width, cap, join);

  @override
  String toString() => 'SvgStroke($width, $cap, $join)';
}

sealed class SvgShape {
  const SvgShape();

  SvgPaint get paint;
}

final class SvgPath extends SvgShape {
  const SvgPath(this.commands, this.paint);

  /// Absolute commands only.
  final List<SvgCommand> commands;

  @override
  final SvgPaint paint;

  @override
  bool operator ==(Object other) =>
      other is SvgPath &&
      other.paint == paint &&
      _listEquals(other.commands, commands);

  @override
  int get hashCode => Object.hash(Object.hashAll(commands), paint);

  @override
  String toString() => 'SvgPath($commands, $paint)';
}

final class SvgCircle extends SvgShape {
  const SvgCircle(this.cx, this.cy, this.r, this.paint);

  final double cx;
  final double cy;
  final double r;

  @override
  final SvgPaint paint;

  @override
  bool operator ==(Object other) =>
      other is SvgCircle &&
      other.cx == cx &&
      other.cy == cy &&
      other.r == r &&
      other.paint == paint;

  @override
  int get hashCode => Object.hash(cx, cy, r, paint);

  @override
  String toString() => 'SvgCircle($cx, $cy, $r, $paint)';
}

final class SvgRect extends SvgShape {
  const SvgRect(
    this.x,
    this.y,
    this.width,
    this.height,
    this.rx,
    this.ry,
    this.paint,
  );

  final double x;
  final double y;
  final double width;
  final double height;
  final double rx;
  final double ry;

  @override
  final SvgPaint paint;

  @override
  bool operator ==(Object other) =>
      other is SvgRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.rx == rx &&
      other.ry == ry &&
      other.paint == paint;

  @override
  int get hashCode => Object.hash(x, y, width, height, rx, ry, paint);

  @override
  String toString() => 'SvgRect($x, $y, $width, $height, $rx, $ry, $paint)';
}

/// An absolute path command.
sealed class SvgCommand {
  const SvgCommand();
}

final class MoveTo extends SvgCommand {
  const MoveTo(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is MoveTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('M', x, y);

  @override
  String toString() => 'MoveTo($x, $y)';
}

final class LineTo extends SvgCommand {
  const LineTo(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is LineTo && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash('L', x, y);

  @override
  String toString() => 'LineTo($x, $y)';
}

final class CubicTo extends SvgCommand {
  const CubicTo(this.x1, this.y1, this.x2, this.y2, this.x, this.y);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is CubicTo &&
      other.x1 == x1 &&
      other.y1 == y1 &&
      other.x2 == x2 &&
      other.y2 == y2 &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash('C', x1, y1, x2, y2, x, y);

  @override
  String toString() => 'CubicTo($x1, $y1, $x2, $y2, $x, $y)';
}

final class ArcTo extends SvgCommand {
  const ArcTo(
    this.x,
    this.y,
    this.rx,
    this.ry,
    this.rotation,
    this.largeArc,
    this.sweep,
  );

  final double x;
  final double y;
  final double rx;
  final double ry;

  /// The ellipse's x-axis rotation, in degrees.
  final double rotation;
  final bool largeArc;

  /// SVG's sweep flag: true is clockwise on screen (y down).
  final bool sweep;

  @override
  bool operator ==(Object other) =>
      other is ArcTo &&
      other.x == x &&
      other.y == y &&
      other.rx == rx &&
      other.ry == ry &&
      other.rotation == rotation &&
      other.largeArc == largeArc &&
      other.sweep == sweep;

  @override
  int get hashCode => Object.hash('A', x, y, rx, ry, rotation, largeArc, sweep);

  @override
  String toString() => 'ArcTo($x, $y, $rx, $ry, $rotation, $largeArc, $sweep)';
}

final class Close extends SvgCommand {
  const Close();

  @override
  bool operator ==(Object other) => other is Close;

  @override
  int get hashCode => 'Z'.hashCode;

  @override
  String toString() => 'Close()';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const _svgNamespace = 'http://www.w3.org/2000/svg';
const _paintAttributes = {
  'fill',
  'stroke',
  'stroke-width',
  'stroke-linecap',
  'stroke-linejoin',
};
const _rootAttributes = {'xmlns', 'width', 'height', 'viewBox'};
const _geometry = {
  'path': ({'d'}, <String>{}),
  'circle': ({'cx', 'cy', 'r'}, <String>{}),
  'rect': ({'x', 'y', 'width', 'height'}, {'rx', 'ry'}),
};
const _caps = {'butt', 'round', 'square'};
const _joins = {'miter', 'round', 'bevel'};
final _number = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// Parses [source], the contents of `<name>.svg`.
///
/// Throws [IconGeneratorException] for anything outside the supported subset.
SvgIcon parseSvgIcon(String name, String source) {
  final file = '$name.svg';
  Never fail(String message) => throw IconGeneratorException('$file: $message');

  final XmlDocument document;
  try {
    document = XmlDocument.parse(source);
  } on XmlException catch (e) {
    fail('malformed XML: ${e.message}');
  }

  XmlElement? root;
  for (final node in document.children) {
    switch (node) {
      case XmlDeclaration():
        break;
      case XmlElement():
        if (root != null) fail('more than one root element <${node.name}>');
        root = node;
      default:
        _rejectNonElement(node, 'the document', fail);
    }
  }
  if (root == null) fail('no root element');
  if (root.name.qualified != 'svg') {
    fail('root element must be <svg>, found <${root.name.qualified}>');
  }

  final rootAttributes = _attributes(root, {
    ..._rootAttributes,
    ..._paintAttributes,
  }, fail);
  for (final required in [..._rootAttributes, ..._paintAttributes]) {
    if (!rootAttributes.containsKey(required)) {
      fail('<svg> must declare $required');
    }
  }
  if (rootAttributes['xmlns'] != _svgNamespace) {
    fail('<svg> xmlns must be $_svgNamespace');
  }
  final width = _positive(rootAttributes, 'width', '<svg>', fail);
  final height = _positive(rootAttributes, 'height', '<svg>', fail);
  final viewBox = rootAttributes['viewBox']!;
  final parts = viewBox.trim().split(RegExp(r'[\s,]+'));
  final box = [
    for (final p in parts)
      _isNumber(p) ? double.parse(p) : fail('viewBox="$viewBox" is malformed'),
  ];
  if (box.length != 4 ||
      box[0] != 0 ||
      box[1] != 0 ||
      box[2] != width ||
      box[3] != height) {
    fail('viewBox="$viewBox" must be "0 0 $width $height"');
  }
  final rootStyle = _style(rootAttributes, null, '<svg>', fail);

  final shapes = <SvgShape>[];
  for (final node in root.children) {
    if (node is! XmlElement) {
      _rejectNonElement(node, '<svg>', fail);
      continue;
    }
    final tag = node.name.qualified;
    final geometry = _geometry[tag];
    if (geometry == null) fail('unsupported element <$tag>');
    final (required, optional) = geometry;
    for (final child in node.children) {
      if (child is XmlElement) {
        fail('<$tag> must not contain <${child.name.qualified}>');
      }
      _rejectNonElement(child, '<$tag>', fail);
    }
    final attributes = _attributes(node, {
      ...required,
      ...optional,
      ..._paintAttributes,
    }, fail);
    for (final r in required) {
      if (!attributes.containsKey(r)) fail('<$tag> must declare $r');
    }
    final paint = _paintOf(_style(attributes, rootStyle, '<$tag>', fail));
    double number(String key) =>
        _numberAttribute(attributes, key, '<$tag>', fail);
    double positive(String key) => _positive(attributes, key, '<$tag>', fail);
    shapes.add(switch (tag) {
      'path' => SvgPath(
        _PathParser(attributes['d']!, (m) {
          fail('<path d="${attributes['d']}">: $m');
        }).parse(),
        paint,
      ),
      'circle' => SvgCircle(number('cx'), number('cy'), positive('r'), paint),
      _ => () {
        double? radius(String key) {
          if (!attributes.containsKey(key)) return null;
          final v = number(key);
          if (v < 0) fail('<rect> $key="${attributes[key]}" must be ≥ 0');
          return v;
        }

        final rx = radius('rx');
        final ry = radius('ry');
        return SvgRect(
          number('x'),
          number('y'),
          positive('width'),
          positive('height'),
          rx ?? ry ?? 0,
          ry ?? rx ?? 0,
          paint,
        );
      }(),
    });
  }
  return SvgIcon(name, width, height, shapes);
}

void _rejectNonElement(
  XmlNode node,
  String where,
  Never Function(String) fail,
) {
  switch (node) {
    case XmlText(:final value) when value.trim().isEmpty:
      return;
    case XmlCDATA():
      fail('CDATA in $where');
    case XmlText(:final value):
      fail('text "${value.trim()}" in $where');
    case XmlComment():
      fail('comment in $where');
    case XmlDoctype():
      fail('DOCTYPE in $where');
    case XmlProcessing(:final target):
      fail('processing instruction <?$target?> in $where');
    default:
      fail('unsupported ${node.nodeType.name} node in $where');
  }
}

Map<String, String> _attributes(
  XmlElement element,
  Set<String> allowed,
  Never Function(String) fail,
) {
  final tag = element.name.qualified;
  return {
    for (final a in element.attributes)
      if (allowed.contains(a.name.qualified))
        a.name.qualified: a.value
      else
        a.name.qualified: fail(
          'unsupported attribute ${a.name.qualified} '
          'on <$tag>',
        ),
  };
}

/// A resolved paint style: the root's, or a shape's after inheritance.
typedef _Style = ({
  bool fill,
  bool stroked,
  double width,
  String cap,
  String join,
});

/// Resolves [attributes] over [inherited]. The root passes null; it must
/// declare every paint attribute, which the caller checks first.
_Style _style(
  Map<String, String> attributes,
  _Style? inherited,
  String where,
  Never Function(String) fail,
) {
  bool colour(String key, bool? fallback) {
    final value = attributes[key];
    if (value == null) return fallback!;
    return switch (value) {
      'none' => false,
      'currentColor' => true,
      _ => fail('$where $key="$value": only none or currentColor'),
    };
  }

  String keyword(String key, Set<String> allowed, String? fallback) {
    final value = attributes[key];
    if (value == null) return fallback!;
    if (!allowed.contains(value)) {
      fail('$where $key="$value": expected one of ${allowed.join(', ')}');
    }
    return value;
  }

  return (
    fill: colour('fill', inherited?.fill),
    stroked: colour('stroke', inherited?.stroked),
    width: attributes.containsKey('stroke-width')
        ? _positive(attributes, 'stroke-width', where, fail)
        : inherited!.width,
    cap: keyword('stroke-linecap', _caps, inherited?.cap),
    join: keyword('stroke-linejoin', _joins, inherited?.join),
  );
}

SvgPaint _paintOf(_Style style) => SvgPaint(
  fill: style.fill,
  stroke: style.stroked ? SvgStroke(style.width, style.cap, style.join) : null,
);

bool _isNumber(String text) => _number.matchAsPrefix(text)?.end == text.length;

double _numberAttribute(
  Map<String, String> attributes,
  String key,
  String where,
  Never Function(String) fail,
) {
  final text = attributes[key]!.trim();
  if (!_isNumber(text)) fail('$where $key="$text" is not a number');
  return double.parse(text);
}

double _positive(
  Map<String, String> attributes,
  String key,
  String where,
  Never Function(String) fail,
) {
  final value = _numberAttribute(attributes, key, where, fail);
  if (value <= 0) fail('$where $key="${attributes[key]}" must be > 0');
  return value;
}

/// Converts an SVG path's `d` into absolute commands.
final class _PathParser {
  _PathParser(this.d, this.fail);

  final String d;
  final Never Function(String) fail;
  var _i = 0;
  final _out = <SvgCommand>[];
  var _x = 0.0, _y = 0.0;
  var _startX = 0.0, _startY = 0.0;
  double? _lastC2x, _lastC2y;

  static const _arity = {
    'M': 2,
    'L': 2,
    'H': 1,
    'V': 1,
    'C': 6,
    'S': 4,
    'A': 7,
    'Z': 0,
  };

  List<SvgCommand> parse() {
    _skipSeparators();
    if (_i >= d.length) fail('empty path data');
    if (d[_i] != 'M' && d[_i] != 'm') fail('path data must start with M or m');
    while (true) {
      _skipSeparators();
      if (_i >= d.length) break;
      final letter = d[_i];
      if (!_arity.containsKey(letter.toUpperCase())) {
        fail('unsupported command "$letter" at offset $_i');
      }
      _i++;
      _command(letter);
    }
    return _out;
  }

  void _command(String letter) {
    final upper = letter.toUpperCase();
    final relative = letter != upper;
    if (upper == 'Z') {
      _out.add(const Close());
      _x = _startX;
      _y = _startY;
      _lastC2x = _lastC2y = null;
      _skipSeparators();
      if (_i < d.length && _startsNumber()) {
        fail('numbers after $letter without a new command');
      }
      return;
    }
    var segment = upper;
    var first = true;
    do {
      _segment(segment, relative);
      if (first && segment == 'M') segment = 'L';
      first = false;
      _skipSeparators();
    } while (_i < d.length && _startsNumber());
  }

  void _segment(String upper, bool relative) {
    final dx = relative ? _x : 0.0;
    final dy = relative ? _y : 0.0;
    switch (upper) {
      case 'M':
        _x = _num() + dx;
        _y = _num() + dy;
        _startX = _x;
        _startY = _y;
        _out.add(MoveTo(_x, _y));
        _lastC2x = _lastC2y = null;
      case 'L':
        _x = _num() + dx;
        _y = _num() + dy;
        _out.add(LineTo(_x, _y));
        _lastC2x = _lastC2y = null;
      case 'H':
        _x = _num() + dx;
        _out.add(LineTo(_x, _y));
        _lastC2x = _lastC2y = null;
      case 'V':
        _y = _num() + dy;
        _out.add(LineTo(_x, _y));
        _lastC2x = _lastC2y = null;
      case 'C':
        final x1 = _num() + dx, y1 = _num() + dy;
        final x2 = _num() + dx, y2 = _num() + dy;
        _cubic(x1, y1, x2, y2, _num() + dx, _num() + dy);
      case 'S':
        final x1 = _lastC2x == null ? _x : 2 * _x - _lastC2x!;
        final y1 = _lastC2y == null ? _y : 2 * _y - _lastC2y!;
        final x2 = _num() + dx, y2 = _num() + dy;
        _cubic(x1, y1, x2, y2, _num() + dx, _num() + dy);
      case 'A':
        final rx = _num(), ry = _num();
        if (rx < 0 || ry < 0) fail('negative arc radius');
        final rotation = _num();
        final largeArc = _flag();
        final sweep = _flag();
        _x = _num() + dx;
        _y = _num() + dy;
        _out.add(ArcTo(_x, _y, rx, ry, rotation, largeArc, sweep));
        _lastC2x = _lastC2y = null;
    }
  }

  void _cubic(double x1, double y1, double x2, double y2, double x, double y) {
    _out.add(CubicTo(x1, y1, x2, y2, x, y));
    _lastC2x = x2;
    _lastC2y = y2;
    _x = x;
    _y = y;
  }

  bool _startsNumber() {
    final c = d[_i];
    return c == '-' || c == '+' || c == '.' || _isDigit(c);
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

  void _skipSeparators() {
    while (_i < d.length && ' \t\n\r,'.contains(d[_i])) {
      _i++;
    }
  }

  double _num() {
    _skipSeparators();
    final match = _number.matchAsPrefix(d, _i);
    if (match == null) fail('expected a number at offset $_i');
    _i = match.end;
    return double.parse(match[0]!);
  }

  bool _flag() {
    _skipSeparators();
    if (_i >= d.length) fail('expected an arc flag at offset $_i');
    final c = d[_i];
    if (c != '0' && c != '1') fail('arc flag must be 0 or 1 at offset $_i');
    _i++;
    return c == '1';
  }
}
