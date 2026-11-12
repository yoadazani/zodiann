// ARCH-2: the computation core is pure Dart. It must not depend on Flutter
// (directly or transitively, via regular or dev dependencies) and must not
// import dart:ui. Runs from the workspace root on every `melos run test`.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'dependency_closure.dart';

const corePackages = ['astro_core', 'gann_core'];

void main() {
  // Platform.resolvedExecutable is the Dart VM running this test, i.e. the
  // pinned SDK, so `pub deps` sees the same resolution as the test run.
  final pubDeps = Process.runSync(Platform.resolvedExecutable, [
    'pub',
    'deps',
    '--json',
  ]);

  test('`dart pub deps --json` succeeds', () {
    expect(pubDeps.exitCode, 0, reason: '${pubDeps.stderr}');
  });

  for (final package in corePackages) {
    group('ARCH-2: $package is pure Dart', () {
      test('has no Flutter SDK package in its dependency closure', () {
        final deps =
            jsonDecode(pubDeps.stdout as String) as Map<String, Object?>;
        final violations = findForbiddenDependencies(deps, package);

        expect(
          violations,
          isEmpty,
          reason: violations.values.map((path) => path.join(' -> ')).join('\n'),
        );
      });

      test('lib/ imports neither dart:ui nor package:flutter', () {
        expect(
          findForbiddenImports(Directory('packages/$package/lib')),
          isEmpty,
        );
      });
    });
  }
}
