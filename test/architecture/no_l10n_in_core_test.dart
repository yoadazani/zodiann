// ZOD-L10-007 criterion 1 (L-9): storage and computation code never reaches
// localization, so it can't produce a translated string. Entity-valued model
// fields are enum-typed (Crossing.body: Body), so stored values hold keys.
// The app and the feature packages may use localization. Runs from the
// workspace root on every `melos run test`.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'dependency_closure.dart';
import 'l10n_references.dart';

const _forbidden = {'shared_ui', 'flutter_localizations'};

void main() {
  test('scans every key-only package', () {
    for (final pkg in keyOnlyPackages) {
      expect(Directory('packages/$pkg/lib').existsSync(), isTrue, reason: pkg);
    }
    for (final pkg in ['astro_core', 'gann_core']) {
      expect(_dartFiles(pkg), isNotEmpty, reason: pkg);
    }
  });

  test('key-only sources never reach localization', () {
    final hits = [
      for (final pkg in keyOnlyPackages)
        for (final file in _dartFiles(pkg))
          for (final hit in l10nReferences(file.readAsStringSync()))
            '${file.path.replaceAll(r'\', '/')}: $hit',
    ];
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('positive control: the app uses localization', () {
    expect(
      l10nReferences(
        File('apps/astro_mobile/lib/src/app.dart').readAsStringSync(),
      ),
      isNotEmpty,
    );
  });

  group('runtime dependencies', () {
    late Map<String, Object?> deps;

    setUpAll(() {
      // The pinned Dart running this test, as no_network_test.dart does.
      final result = Process.runSync(Platform.resolvedExecutable, [
        'pub',
        'deps',
        '--json',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      deps = jsonDecode(result.stdout as String) as Map<String, Object?>;
    });

    test('key-only packages never depend on localization at runtime', () {
      for (final pkg in keyOnlyPackages) {
        final hits = findForbiddenDependencies(
          deps,
          pkg,
          forbidden: _forbidden,
          includeDevDependencies: false,
        );
        expect(
          hits,
          isEmpty,
          reason: hits.values.map((p) => p.join(' -> ')).join('\n'),
        );
      }
    });

    test('positive control: the app depends on localization', () {
      expect(
        findForbiddenDependencies(
          deps,
          'astro_mobile',
          forbidden: _forbidden,
          includeDevDependencies: false,
        ).keys,
        unorderedEquals(_forbidden),
      );
    });
  });
}

List<File> _dartFiles(String pkg) => [
  for (final f in Directory(
    'packages/$pkg/lib',
  ).listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart')) f,
];
