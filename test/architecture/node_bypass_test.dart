// ZOD-FND-011 Task 7.2: production code never reaches the raw mean-node API
// (`meanAscendingNode`, `meanAscendingNodeAt`, `MeanAscendingNodeFormula`),
// which has no failure channel and so cannot enforce the supported date
// range. Consumers must go through `position()`, which the
// `SupportedRangeEphemeris` decorator limits. Only the explicitly justified
// formula and source-implementation files may name the raw API. Runs from the
// workspace root on every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

import 'node_bypass.dart';

List<String> names(String source) => [
  for (final f in findNodeBypasses(source, path: 'x.dart')) f.name,
];

void main() {
  group('the scanner flags every syntactic form (controls)', () {
    final flagged = <String, String>{
      'a direct call': 'final p = meanAscendingNode(t);',
      'an instance call': 'final p = port.meanAscendingNode(t);',
      'a null-aware call': 'final p = port?.meanAscendingNode(t);',
      'a cascade': 'port..meanAscendingNode(t);',
      'super.': 'final p = super.meanAscendingNode(t);',
      'this.': 'final p = this.meanAscendingNode(t);',
      'a tear-off': 'final f = ports.map(p.meanAscendingNode);',
      'an alias of the free function': 'final f = meanAscendingNodeAt;',
      'the free function': 'final p = meanAscendingNodeAt(utc);',
      'a prefixed import use': 'final p = m.meanAscendingNodeAt(utc);',
      'a show list': "import 'package:astro_core/astro_core.dart' show meanAscendingNodeAt;",
      'the mixin':
          'class X with MeanAscendingNodeFormula implements EphemerisPort {}',
      'an override declaration':
          'EclipticPosition meanAscendingNode(DateTime utc) => y;',
    };
    flagged.forEach((label, source) {
      test('flags $label', () {
        expect(names(source), isNotEmpty);
      });
    });

    test('reports the name and the line', () {
      final found = findNodeBypasses(
        'void f() {\n  g();\n  p.meanAscendingNodeAt(t);\n}\n',
        path: 'a/b.dart',
      );

      expect(found, hasLength(1));
      expect(found.single.path, 'a/b.dart');
      expect(found.single.line, 3);
      expect(found.single.name, 'meanAscendingNodeAt');
    });
  });

  group('the scanner ignores what is not a use (controls)', () {
    final ignored = <String, String>{
      'a // comment': '// p.meanAscendingNode(t)\nfinal a = 1;',
      'a /* */ comment': '/* p.meanAscendingNode(t) */ final a = 1;',
      'a /// doc line':
          '/// Use [meanAscendingNode] and meanAscendingNodeAt.\nint a;',
      'a plain string': "final s = 'meanAscendingNode';",
      'a double-quoted string': 'final s = "MeanAscendingNodeFormula";',
      'a dollar-interpolated name': r"final s = '$meanAscendingNodeFoo';",
      'a longer identifier': 'final a = meanAscendingNodeFoo(t);',
      'a prefixed identifier': 'final a = xmeanAscendingNode(t);',
      'a raw string with a hole-like text':
          r"final s = r'${p.meanAscendingNode(t)}';",
    };
    ignored.forEach((label, source) {
      test('ignores $label', () {
        expect(names(source), isEmpty);
      });
    });
  });

  group('string interpolation is scanned (controls)', () {
    test(r"flags a call inside ${} of a single-quoted string", () {
      expect(names(r"print('${p.meanAscendingNode(t)}');"), isNotEmpty);
    });

    test(r'flags a call inside ${} of a double-quoted string', () {
      expect(names(r'final s = "x ${meanAscendingNodeAt(t)} y";'), isNotEmpty);
    });

    test('flags a call in a hole nested inside another hole', () {
      expect(
        names('final s = \'\${f("\${p.meanAscendingNode(t)}")}\';'),
        isNotEmpty,
      );
    });

    test('a } inside a nested string does not end the hole early', () {
      expect(
        names('final s = \'\${f(\'}\')} \${p.meanAscendingNode(t)}\';'),
        isNotEmpty,
      );
    });

    test('flags a hole on a later line of a triple-quoted string, at the '
        "string's start line", () {
      const source =
          "final a = 1;\nfinal s = '''\nline\n\${p.meanAscendingNode(t)}\n''';\n";
      final found = findNodeBypasses(source, path: 'x.dart');

      expect(found, hasLength(1));
      expect(found.single.line, 2);
    });

    test('a // inside a string is not a comment', () {
      expect(
        names("final s = 'http://x'; final p = q.meanAscendingNode(t);"),
        isNotEmpty,
      );
    });
  });

  group('interpolationBodies', () {
    test('collects each hole body with its string line', () {
      final bodies = interpolationBodies(
        'final a = 1;\nfinal s = "a \${x} b \${y + 1}";\n',
      );

      expect(bodies.map((b) => b.$2), ['x', 'y + 1']);
      expect(bodies.every((b) => b.$1 == 2), isTrue);
    });

    test('ignores raw strings and comments', () {
      expect(interpolationBodies(r"final s = r'${x}'; // '${y}'"), isEmpty);
    });
  });

  group('paths', () {
    test('normalisation maps every spelling to one relative path', () {
      expect(
        normalizeScanPath(r'.\apps\x\lib\a.dart', root: '.'),
        'apps/x/lib/a.dart',
      );
      expect(
        normalizeScanPath('./apps/x/lib/a.dart', root: '.'),
        'apps/x/lib/a.dart',
      );
      expect(
        normalizeScanPath('apps/x/lib/a.dart', root: '.'),
        'apps/x/lib/a.dart',
      );
      expect(
        normalizeScanPath(r'C:\tmp\r\packages\y\lib\b.dart', root: r'C:\tmp\r'),
        'packages/y/lib/b.dart',
      );
    });
  });

  group('scanProduction on a temporary tree', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('node_bypass_'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String relative, String text) {
      File(
          '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
        )
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }

    test('a call in a feature package is reported with its path and line', () {
      write(
        'packages/feature_wheel/lib/x.dart',
        'void f(p) {\n  p.meanAscendingNode(DateTime.utc(2000));\n}\n',
      );

      final found = scanProduction(root);

      expect(found, hasLength(1));
      expect(found.single.path, 'packages/feature_wheel/lib/x.dart');
      expect(found.single.line, 2);
    });

    test('a call in an allowlisted file is permitted', () {
      write(
        'packages/astro_core/lib/src/ephemeris/mean_node.dart',
        'final a = meanAscendingNodeAt(t);\n',
      );

      expect(scanProduction(root), isEmpty);
    });

    test(
      'the same call under another path of the same package is reported',
      () {
        write(
          'packages/astro_core/lib/src/ephemeris/other.dart',
          'final a = meanAscendingNodeAt(t);\n',
        );

        expect(scanProduction(root), hasLength(1));
      },
    );

    test('test, integration_test, tool and hook code is not production', () {
      for (final dir in ['test', 'integration_test', 'tool', 'hook']) {
        write('packages/x/$dir/a.dart', 'final a = meanAscendingNodeAt(t);\n');
        write('apps/y/$dir/a.dart', 'final a = meanAscendingNodeAt(t);\n');
      }

      expect(scanProduction(root), isEmpty);
    });

    test('an interpolated call is found through the scan too', () {
      write(
        'apps/astro_mobile/lib/a.dart',
        "String s(p) => 'node \${p.meanAscendingNode(t)}';\n",
      );

      expect(scanProduction(root), hasLength(1));
    });
  });

  group('the real repository', () {
    test('production code never reaches the raw mean-node API', () {
      final found = scanProduction(Directory('.'));

      expect(
        found,
        isEmpty,
        reason:
            'Use position(Body.node, utc) through the port; the raw API is '
            'unlimited by the supported range. Found: ${found.join('; ')}',
      );
    });

    test('every allowlisted file exists and still names the raw API', () {
      nodeBypassAllowlist.forEach((path, why) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is a stale entry');
        expect(
          findNodeBypasses(file.readAsStringSync(), path: path),
          isNotEmpty,
          reason: '$path no longer names the raw API: remove the entry',
        );
      });
    });

    test('every allowlist entry carries a justification', () {
      expect(nodeBypassAllowlist, isNotEmpty);
      nodeBypassAllowlist.forEach((path, why) {
        expect(why.trim(), isNotEmpty, reason: path);
      });
    });
  });
}
