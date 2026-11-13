import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'dependency_closure.dart';

/// Real `dart pub deps --json` output from a scratch pub workspace (trimmed),
/// shaped like this repo's: members have kind "root" and
/// dependencies/directDependencies/devDependencies; `root` is the workspace.
///
///   core_reg   → mid → uipkg → flutter → sky_engine        (regular path)
///   core_dev   ⇢dev helper → uipkg → flutter               (dev path)
///   core_fp    → devonly ⇢dev uipkg                        (dev of a dep: clean)
///   core_clean (no dependencies)
Map<String, Object?> loadFixture() => jsonDecode(
  File('test/architecture/fixtures/pub_deps_workspace.json').readAsStringSync(),
) as Map<String, Object?>;

void main() {
  group('findForbiddenDependencies', () {
    late Map<String, Object?> deps;
    setUp(() => deps = loadFixture());

    test('detects Flutter reached indirectly through a regular dependency', () {
      final result = findForbiddenDependencies(deps, 'core_reg');

      expect(result.keys, unorderedEquals(['flutter', 'sky_engine']));
      expect(result['flutter'], ['core_reg', 'mid', 'uipkg', 'flutter']);
    });

    test('detects Flutter reached indirectly through a dev dependency', () {
      final result = findForbiddenDependencies(deps, 'core_dev');

      expect(result['flutter'], ['core_dev', 'helper', 'uipkg', 'flutter']);
    });

    test('includeDevDependencies: false follows regular dependencies only', () {
      expect(findForbiddenDependencies(deps, 'core_dev'), contains('flutter'));
      expect(
        findForbiddenDependencies(
          deps,
          'core_dev',
          includeDevDependencies: false,
        ),
        isEmpty,
      );
      expect(
        findForbiddenDependencies(
          deps,
          'core_reg',
          includeDevDependencies: false,
        )['flutter'],
        ['core_reg', 'mid', 'uipkg', 'flutter'],
      );
    });

    test('passes a package with no Flutter in its closure', () {
      expect(findForbiddenDependencies(deps, 'core_clean'), isEmpty);
    });

    test('ignores dev dependencies of dependencies', () {
      expect(findForbiddenDependencies(deps, 'core_fp'), isEmpty);
    });

    test('starts from the named member, not the workspace root', () {
      expect(findForbiddenDependencies(deps, 'ws'), isEmpty);
      expect(findForbiddenDependencies(deps, 'core_reg'), isNotEmpty);
    });

    test('throws for a package missing from the output', () {
      expect(
        () => findForbiddenDependencies(deps, 'nope'),
        throwsArgumentError,
      );
    });
  });

  group('findForbiddenImports', () {
    late Directory lib;
    setUp(() => lib = Directory.systemTemp.createTempSync('arch2_lib_'));
    tearDown(() => lib.deleteSync(recursive: true));

    void write(String path, String content) => File('${lib.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    List<String> names() =>
        findForbiddenImports(lib)
            .map((p) => p.replaceAll(r'\', '/').split('/').last)
            .toList();

    test('reports a package:flutter import, including in subdirectories', () {
      write('src/widgets.dart', "import 'package:flutter/widgets.dart';\n");

      expect(names(), ['widgets.dart']);
    });

    test('reports dart:ui imports and exports', () {
      write('a.dart', "import 'dart:ui';\n");
      write('b.dart', 'export "dart:ui" show Color;\n');

      expect(names(), unorderedEquals(['a.dart', 'b.dart']));
    });

    test('reports a conditional import whose alternative is dart:ui', () {
      write(
        'platform.dart',
        "import 'stub.dart'\n"
            "    if (dart.library.ui) 'dart:ui';\n",
      );

      expect(names(), ['platform.dart']);
    });

    test('ignores other imports and mid-line mentions', () {
      write(
        'ok.dart',
        "import 'dart:math';\n"
            "// never import 'package:flutter/widgets.dart' here\n"
            "const note = 'dart:ui is forbidden';\n",
      );

      expect(names(), isEmpty);
    });
  });
}
