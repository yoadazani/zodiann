// ZOD-FND-009: the strict SVG parser behind tool/gen_icons.dart. Anything
// outside the subset the 33 design icons use must fail loudly, never be
// dropped (product-owner decision, 2026-11-15).
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/icons/svg_icon.dart';

const _rootAttributes = {
  'xmlns': 'http://www.w3.org/2000/svg',
  'width': '24',
  'height': '24',
  'viewBox': '0 0 24 24',
  'fill': 'none',
  'stroke': 'currentColor',
  'stroke-width': '1.6',
  'stroke-linecap': 'round',
  'stroke-linejoin': 'round',
};

/// [body] inside the exact root of the design files, with [remove]d and
/// [set] root attributes for the failure cases.
String svg(String body, {String? remove, Map<String, String> set = const {}}) {
  final attributes = {..._rootAttributes, ...set}..remove(remove);
  final rendered = attributes.entries
      .map((e) => '${e.key}="${e.value}"')
      .join(' ');
  return '<svg $rendered>$body</svg>';
}

SvgIcon parse(String source) => parseSvgIcon('t', source);

List<SvgCommand> commands(String d) =>
    (parse(svg('<path d="$d"/>')).shapes.single as SvgPath).commands;

const _roundStroke = SvgStroke(1.6, 'round', 'round');

/// The fields of [c], for comparisons with a tolerance.
List<Object> _fields(SvgCommand c) => switch (c) {
  MoveTo(:final x, :final y) => ['M', x, y],
  LineTo(:final x, :final y) => ['L', x, y],
  CubicTo(:final x1, :final y1, :final x2, :final y2, :final x, :final y) => [
    'C',
    x1,
    y1,
    x2,
    y2,
    x,
    y,
  ],
  ArcTo(
    :final x,
    :final y,
    :final rx,
    :final ry,
    :final rotation,
    :final largeArc,
    :final sweep,
  ) =>
    ['A', x, y, rx, ry, rotation, largeArc, sweep],
  Close() => ['Z'],
};

void expectCommands(List<SvgCommand> actual, List<SvgCommand> expected) {
  expect(actual, hasLength(expected.length), reason: '$actual');
  for (var i = 0; i < expected.length; i++) {
    final a = _fields(actual[i]);
    final e = _fields(expected[i]);
    expect(a, hasLength(e.length), reason: 'command $i: $a vs $e');
    for (var j = 0; j < e.length; j++) {
      final ej = e[j];
      expect(
        a[j],
        ej is double ? closeTo(ej, 1e-9) : ej,
        reason: 'command $i field $j: $a vs $e',
      );
    }
  }
}

/// A [parse] of [source] fails, naming the file and [culprit].
void expectFailure(String source, String culprit) {
  expect(
    () => parse(source),
    throwsA(
      isA<IconGeneratorException>().having(
        (e) => e.message,
        'message',
        allOf(contains('t.svg'), contains(culprit)),
      ),
    ),
  );
}

void main() {
  group('paint', () {
    test('root style: stroke-only path inherits 1.6 / round / round', () {
      expect(
        parse(svg('<path d="M4 7h16"/>')).shapes.single.paint,
        const SvgPaint(fill: false, stroke: _roundStroke),
      );
    });

    test('fill="currentColor" stroke="none" → fill only', () {
      final icon = parse(
        svg('<path d="M9 6.5v11l9-5.5z" fill="currentColor" stroke="none"/>'),
      );
      expect(icon.shapes.single.paint, const SvgPaint(fill: true));
    });

    test('fill="currentColor" alone → fill and inherited stroke', () {
      final icon = parse(
        svg('<circle cx="12" cy="5.5" r="1.3" fill="currentColor"/>'),
      );
      expect(
        icon.shapes.single,
        const SvgCircle(
          12,
          5.5,
          1.3,
          SvgPaint(fill: true, stroke: _roundStroke),
        ),
      );
    });

    test('element stroke attributes override the root', () {
      final icon = parse(
        svg(
          '<path d="M1 1h2" stroke-width="2" stroke-linecap="square" '
          'stroke-linejoin="bevel"/>',
        ),
      );
      expect(
        icon.shapes.single.paint,
        const SvgPaint(fill: false, stroke: SvgStroke(2, 'square', 'bevel')),
      );
    });
  });

  group('path commands', () {
    test('relative and H/V commands become absolute', () {
      expectCommands(commands('M4 7h16M4 12h16M4 17h16'), const [
        MoveTo(4, 7),
        LineTo(20, 7),
        MoveTo(4, 12),
        LineTo(20, 12),
        MoveTo(4, 17),
        LineTo(20, 17),
      ]);
      expectCommands(commands('M12 3.5V7'), const [
        MoveTo(12, 3.5),
        LineTo(12, 7),
      ]);
      expectCommands(commands('M1 1L3 4l1 1H9v2h-1V1'), const [
        MoveTo(1, 1),
        LineTo(3, 4),
        LineTo(4, 5),
        LineTo(9, 5),
        LineTo(9, 7),
        LineTo(8, 7),
        LineTo(8, 1),
      ]);
    });

    test('implicit repeats', () {
      expectCommands(commands('M7 10l5 5 5-5'), const [
        MoveTo(7, 10),
        LineTo(12, 15),
        LineTo(17, 10),
      ]);
      expectCommands(commands('M1 1 2 2'), const [MoveTo(1, 1), LineTo(2, 2)]);
      expectCommands(commands('m1 1 2 2'), const [MoveTo(1, 1), LineTo(3, 3)]);
    });

    test('z returns to the subpath start for the next relative command', () {
      expectCommands(commands('M8.5 6h2.5v12H8.5zM13 6h2.5v12H13z'), const [
        MoveTo(8.5, 6),
        LineTo(11, 6),
        LineTo(11, 18),
        LineTo(8.5, 18),
        Close(),
        MoveTo(13, 6),
        LineTo(15.5, 6),
        LineTo(15.5, 18),
        LineTo(13, 18),
        Close(),
      ]);
      expectCommands(commands('M2 2h4zm1 1h1'), const [
        MoveTo(2, 2),
        LineTo(6, 2),
        Close(),
        MoveTo(3, 3),
        LineTo(4, 3),
      ]);
    });

    test('compact arc flags', () {
      expectCommands(commands('M19.5 12a7.5 7.5 0 11-2.2-5.3M19.5 4.5v4h-4'), [
        const MoveTo(19.5, 12),
        const ArcTo(17.3, 6.7, 7.5, 7.5, 0, true, true),
        const MoveTo(19.5, 4.5),
        const LineTo(19.5, 8.5),
        const LineTo(15.5, 8.5),
      ]);
    });

    test('absolute arcs', () {
      // anchor.svg's second path.
      expectCommands(commands('M12 7.5V20M5 13a7 7 0 0014 0M9 10.5h6'), const [
        MoveTo(12, 7.5),
        LineTo(12, 20),
        MoveTo(5, 13),
        ArcTo(19, 13, 7, 7, 0, false, false),
        MoveTo(9, 10.5),
        LineTo(15, 10.5),
      ]);
      // moon.svg.
      expectCommands(
        commands('M19 14.5A7.5 7.5 0 019.5 5a7.5 7.5 0 109.5 9.5z'),
        const [
          MoveTo(19, 14.5),
          ArcTo(9.5, 5, 7.5, 7.5, 0, false, true),
          ArcTo(19, 14.5, 7.5, 7.5, 0, true, false),
          Close(),
        ],
      );
    });

    test('s reflects the previous cubic control point', () {
      // globe.svg's second path.
      expectCommands(
        commands(
          'M12 3.5c2.5 2.3 3.5 5.3 3.5 8.5s-1 6.2-3.5 8.5'
          'c-2.5-2.3-3.5-5.3-3.5-8.5s1-6.2 3.5-8.5z',
        ),
        const [
          MoveTo(12, 3.5),
          CubicTo(14.5, 5.8, 15.5, 8.8, 15.5, 12),
          CubicTo(15.5, 15.2, 14.5, 18.2, 12, 20.5),
          CubicTo(9.5, 18.2, 8.5, 15.2, 8.5, 12),
          CubicTo(8.5, 8.8, 9.5, 5.8, 12, 3.5),
          Close(),
        ],
      );
    });

    test('s after a non-cubic uses the current point as first control', () {
      expectCommands(commands('M1 1L2 2s3 3 4 4'), const [
        MoveTo(1, 1),
        LineTo(2, 2),
        CubicTo(2, 2, 5, 5, 6, 6),
      ]);
      expectCommands(commands('M1 1C1 2 3 4 5 5L6 6S7 7 8 8'), const [
        MoveTo(1, 1),
        CubicTo(1, 2, 3, 4, 5, 5),
        LineTo(6, 6),
        CubicTo(6, 6, 7, 7, 8, 8),
      ]);
    });

    test('numbers: .4, -.5, 2.2-5.3, 1e-1, commas', () {
      expectCommands(commands('M.4-.5L2.2-5.3l1e-1,+1E1'), const [
        MoveTo(0.4, -0.5),
        LineTo(2.2, -5.3),
        LineTo(2.3, 4.7),
      ]);
    });
  });

  group('shapes', () {
    test('circle and rect', () {
      final icon = parse(
        svg(
          '<rect x="4" y="5.5" width="16" height="14.5" rx="2"/>'
          '<rect x="1" y="2" width="3" height="4"/>'
          '<rect x="1" y="2" width="3" height="4" ry="0.5"/>'
          '<circle cx="12" cy="12" r="8.5"/>',
        ),
      );
      const paint = SvgPaint(fill: false, stroke: _roundStroke);
      expect(icon.shapes, const [
        SvgRect(4, 5.5, 16, 14.5, 2, 2, paint),
        SvgRect(1, 2, 3, 4, 0, 0, paint),
        SvgRect(1, 2, 3, 4, 0.5, 0.5, paint),
        SvgCircle(12, 12, 8.5, paint),
      ]);
    });

    test('name and viewBox', () {
      final icon = parseSvgIcon(
        'wheel',
        svg('<path d="M1 1h1"/>', set: {'viewBox': '0,0,24,24'}),
      );
      expect(icon.name, 'wheel');
      expect(icon.viewBoxWidth, 24);
      expect(icon.viewBoxHeight, 24);
    });

    test('an XML declaration and whitespace are accepted', () {
      final icon = parse(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '${svg('\n  <path d="M1 1h1"/>\n')}\n',
      );
      expect(icon.shapes, hasLength(1));
    });

    test('value equality', () {
      expect(const MoveTo(1, 2), const MoveTo(1, 2));
      expect(const MoveTo(1, 2), isNot(const MoveTo(2, 1)));
      expect(const MoveTo(1, 2).hashCode, const MoveTo(1, 2).hashCode);
      expect(const MoveTo(1, 2), isNot(const LineTo(1, 2)));
      expect(
        const SvgPath([MoveTo(1, 2)], SvgPaint(fill: true)),
        const SvgPath([MoveTo(1, 2)], SvgPaint(fill: true)),
      );
      expect(
        const SvgPath([MoveTo(1, 2)], SvgPaint(fill: true)).hashCode,
        const SvgPath([MoveTo(1, 2)], SvgPaint(fill: true)).hashCode,
      );
      expect(
        const SvgPath([MoveTo(1, 2)], SvgPaint(fill: true)),
        isNot(const SvgPath([MoveTo(1, 3)], SvgPaint(fill: true))),
      );
    });
  });

  group('explicit failures', () {
    for (final element in ['g', 'line', 'polyline', 'ellipse', 'text']) {
      test('element <$element>', () {
        expectFailure(svg('<$element/>'), element);
      });
    }

    for (final attribute in [
      'transform',
      'opacity',
      'class',
      'style',
      'stroke-dasharray',
      'fill-rule',
      'stroke-miterlimit',
    ]) {
      test('attribute $attribute on a shape', () {
        expectFailure(svg('<path d="M1 1h1" $attribute="1"/>'), attribute);
      });
      test('attribute $attribute on the root', () {
        expectFailure(svg('', set: {attribute: '1'}), attribute);
      });
    }

    test('fill="#f00"', () {
      expectFailure(svg('<path d="M1 1h1" fill="#f00"/>'), '#f00');
    });

    test('stroke="red"', () {
      expectFailure(svg('<path d="M1 1h1" stroke="red"/>'), 'red');
    });

    test('stroke-linecap="foo"', () {
      expectFailure(svg('<path d="M1 1h1" stroke-linecap="foo"/>'), 'foo');
    });

    test('stroke-linejoin="foo"', () {
      expectFailure(svg('', set: {'stroke-linejoin': 'foo'}), 'foo');
    });

    test('viewBox height differs from height', () {
      expectFailure(svg('', set: {'viewBox': '0 0 24 20'}), 'viewBox');
    });

    test('viewBox origin not 0 0', () {
      expectFailure(svg('', set: {'viewBox': '2 0 24 24'}), 'viewBox');
    });

    test('missing viewBox', () {
      expectFailure(svg('', remove: 'viewBox'), 'viewBox');
    });

    for (final attribute in [
      'width',
      'fill',
      'stroke',
      'stroke-width',
      'stroke-linecap',
      'stroke-linejoin',
    ]) {
      test('root missing $attribute', () {
        expectFailure(svg('', remove: attribute), attribute);
      });
    }

    test('root <path>', () {
      expectFailure('<path d="M1 1h1"/>', 'path');
    });

    test('circle without r', () {
      expectFailure(svg('<circle cx="1" cy="1"/>'), 'r');
    });

    test('circle without cx', () {
      expectFailure(svg('<circle cy="1" r="1"/>'), 'cx');
    });

    test('rect without width', () {
      expectFailure(svg('<rect x="1" y="1" height="1"/>'), 'width');
    });

    test('rect without y', () {
      expectFailure(svg('<rect x="1" width="1" height="1"/>'), 'y');
    });

    test('path without d', () {
      expectFailure(svg('<path/>'), 'd');
    });

    for (final d in [
      'M1 1Q2 2 3 3',
      'M1 1T2 2',
      'M4 x',
      'M4',
      '',
      'L1 1',
      'M1 1z 2 2',
      'M1 1a1 1 0 21 2 2',
      'M1 -',
      'M1 1e',
      'M1 1a-1 1 0 0 1 2 2',
    ]) {
      test('d="$d"', () {
        expectFailure(svg('<path d="$d"/>'), 'd="$d"');
      });
    }

    test('text inside a <path>', () {
      expectFailure(svg('<path d="M1 1h1">hi</path>'), 'hi');
    });

    test('a child element inside a <circle>', () {
      expectFailure(
        svg('<circle cx="1" cy="1" r="1"><path/></circle>'),
        'path',
      );
    });

    test('a comment between shapes', () {
      expectFailure(svg('<path d="M1 1h1"/><!-- note -->'), 'comment');
    });

    test('a comment outside the root', () {
      expectFailure('<!-- note -->${svg('')}', 'comment');
    });

    test('a DOCTYPE', () {
      expectFailure('<!DOCTYPE svg>${svg('')}', 'DOCTYPE');
    });

    test('CDATA', () {
      expectFailure(svg('<![CDATA[x]]>'), 'CDATA');
    });

    test('a processing instruction', () {
      expectFailure(svg('<?foo bar?>'), 'processing instruction');
    });

    test('stray text between shapes', () {
      expectFailure(svg('<path d="M1 1h1"/>stray'), 'stray');
    });

    test('r="0"', () {
      expectFailure(svg('<circle cx="1" cy="1" r="0"/>'), 'r');
    });

    test('width="-1" on a rect', () {
      expectFailure(svg('<rect x="1" y="1" width="-1" height="1"/>'), 'width');
    });

    test('rx="-1"', () {
      expectFailure(
        svg('<rect x="1" y="1" width="1" height="1" rx="-1"/>'),
        'rx',
      );
    });

    test('stroke-width="0"', () {
      expectFailure(svg('<path d="M1 1h1" stroke-width="0"/>'), 'stroke-width');
    });

    test('a malformed number attribute', () {
      expectFailure(svg('<circle cx="1px" cy="1" r="1"/>'), '1px');
    });

    test('malformed XML', () {
      expectFailure('<svg', 'XML');
    });
  });

  test('all 33 design files parse', () {
    final files = Directory('design-reference/zodiann/assets/icons')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList();
    expect(files, hasLength(33));
    for (final file in files) {
      final name = file.uri.pathSegments.last.replaceAll('.svg', '');
      expect(
        parseSvgIcon(name, file.readAsStringSync()).shapes,
        isNotEmpty,
        reason: name,
      );
    }
  });
}
