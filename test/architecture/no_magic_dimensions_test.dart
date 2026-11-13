// ZOD-UI-003: no layout magic number in any component. Spacing, radius and
// sizes come from ZodiannSpace / ZodiannRadius / ZodiannSize / ZodiannLayout;
// numeric layout literals may appear only in the token files
// (packages/shared_ui/lib/src/theme/tokens/). Runs from the workspace root
// on every `melos run test`. The scanner's gaps are documented in
// dimension_literals.dart.
import 'dart:io';

import 'package:test/test.dart';

import 'dimension_literals.dart';

void main() {
  final scanned = <String>[];
  final skipped = <String>[];
  final bad = <String>[];

  for (final top in ['apps', 'packages']) {
    final root = Directory(top);
    if (!root.existsSync()) continue;
    for (final member in root.listSync().whereType<Directory>()) {
      final lib = Directory('${member.path}/lib');
      if (!lib.existsSync()) continue;
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;
        if (isDimensionLiteralAllowed(path)) {
          skipped.add(path);
          continue;
        }
        scanned.add(path);
        for (final literal in findDimensionLiterals(file.readAsStringSync())) {
          bad.add('$path:${literal.line} ${literal.call} … ${literal.text}');
        }
      }
    }
  }

  test(
    'no workspace lib/ source has a layout magic number outside tokens/',
    () {
      expect(bad, isEmpty);
    },
  );

  test('scans a non-trivial set of files', () {
    expect(scanned.length, greaterThanOrEqualTo(10));
  });

  test('the token directory is exempted by the walk', () {
    expect(
      skipped,
      contains(
        'packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart',
      ),
    );
  });
}
