// Unit tests for the ZOD-UI-003 layout-dimension scanner
// (dimension_literals.dart).
import 'package:test/test.dart';

import 'dimension_literals.dart';

void main() {
  group('flags a numeric literal in', () {
    const flagged = [
      'EdgeInsets.all(8)',
      'EdgeInsets.symmetric(horizontal: 12)',
      'EdgeInsetsDirectional.only(start: 4.5)',
      'EdgeInsets.fromLTRB(0, 8, 0, 0)',
      'SizedBox(height: 40)',
      'SizedBox.square(dimension: 24)',
      'SizedBox.fromSize(size: Size(4, 4))',
      'Radius.circular(12)',
      'Radius.elliptical(4, 2)',
      'BorderRadius.circular(8)',
      'BoxShadow(blurRadius: 4)',
      'Size(46, 46)',
      'Size.square(46)',
      'Size.fromHeight(40)',
      'BorderSide(width: 2)',
      'BoxConstraints(minHeight: 40)',
      'BoxConstraints.tightFor(height: 44)',
      'Icon(Icons.add, size: 20)',
      'IconButton(iconSize: 20, onPressed: null, icon: x)',
      'Row(spacing: 8, children: [])',
      'Wrap(runSpacing: 4, children: [])',
      'const EdgeInsets.symmetric(\n  horizontal: 12,\n  vertical: 8,\n)',
      'SizedBox(\n  height: 40,\n  child: x,\n)',
    ];
    for (final sample in flagged) {
      test(sample.replaceAll('\n', r'\n'), () {
        expect(findDimensionLiterals(sample), isNotEmpty);
      });
    }
  });

  group('allows', () {
    const allowed = [
      'EdgeInsets.all(ZodiannSpace.s2)',
      'EdgeInsets.zero',
      'EdgeInsets.fromLTRB(0, 0, 0, 0)',
      'EdgeInsets.all(0.0)',
      'SizedBox(height: ZodiannSize.control)',
      "SizedBox(height: ZodiannSize.control, child: Text('Step 1'))",
      'Icon(Icons.filter_1)',
      'Row(flex: 2)',
      'SizedBox(\n  child: Column(\n    children: [\n      a,\n      b,\n    ],\n  ),\n)',
      'final x = 1; // EdgeInsets.all(8)',
      'IconButton(onPressed: () { _page = 2; }, iconSize: ZodiannSize.icon)',
      'ImageIcon(asset, size: ZodiannSize.icon)',
      'SizedBox(width: list[3])',
    ];
    for (final sample in allowed) {
      test(sample.replaceAll('\n', r'\n'), () {
        expect(findDimensionLiterals(sample), isEmpty);
      });
    }
  });

  test('BorderRadius.circular(8) is exactly one finding', () {
    expect(findDimensionLiterals('BorderRadius.circular(8)'), hasLength(1));
  });

  test('a nested constructor is found by its own pattern only', () {
    final found = findDimensionLiterals('SizedBox.fromSize(size: Size(4, 6))');
    expect(found.map((f) => f.text), ['4', '6']);
  });

  test('reports the line of the literal', () {
    final found = findDimensionLiterals(
      'final a = 1;\nconst p = EdgeInsets.symmetric(\n  horizontal: 12,\n'
      '  vertical: 8,\n);\n',
    );
    expect(found.map((f) => (f.line, f.text)), [(3, '12'), (4, '8')]);
  });

  test('blanks string contents, including interpolations', () {
    expect(findDimensionLiterals(r"SizedBox(key: Key('h ${40}'))"), isEmpty);
    expect(findDimensionLiterals("Text('EdgeInsets.all(8)')"), isEmpty);
    expect(
      findDimensionLiterals("Text('''\nSizedBox(height: 4)\n''')"),
      isEmpty,
    );
  });

  test('named-argument patterns check only their own arguments', () {
    expect(findDimensionLiterals('Icon(Icons.add, size: 20)'), hasLength(1));
    expect(findDimensionLiterals('Icon(Icons.add, semanticLabel: x)'), isEmpty);
    expect(
      findDimensionLiterals('Column(spacing: 8, runSpacing: 4)'),
      hasLength(2),
    );
  });

  test('arithmetic on tokens fails loudly (documented)', () {
    expect(
      findDimensionLiterals('EdgeInsets.all(ZodiannSpace.s2 * 1.5)'),
      hasLength(1),
    );
  });

  test('the exemption covers only the token directory', () {
    expect(
      isDimensionLiteralAllowed(
        'packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart',
      ),
      isTrue,
    );
    expect(
      isDimensionLiteralAllowed(
        r'packages\shared_ui\lib\src\theme\tokens\graphite_tokens.dart',
      ),
      isTrue,
    );
    expect(
      isDimensionLiteralAllowed(
        'packages/shared_ui/lib/src/theme/zodiann_layout.dart',
      ),
      isFalse,
    );
    expect(
      isDimensionLiteralAllowed('apps/astro_mobile/lib/main.dart'),
      isFalse,
    );
  });
}
