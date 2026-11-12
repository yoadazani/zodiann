// ARCH-7: no hard-coded colour in any component. Colour literals may appear
// only in the token files (packages/shared_ui/lib/src/theme/tokens/), which
// ZOD-UI-001 fills with MASTER.md §2's values. Runs from the workspace root
// on every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

import 'color_literals.dart';

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
        if (isColorLiteralAllowed(path)) {
          skipped.add(path);
          continue;
        }
        scanned.add(path);
        for (final literal in findColorLiterals(file.readAsStringSync())) {
          bad.add('$path:${literal.line} ${literal.text}');
        }
      }
    }
  }

  test('no color literal in lib/ outside the token files', () {
    expect(bad, isEmpty);
  });

  test('scans a non-trivial set of files', () {
    expect(scanned.length, greaterThanOrEqualTo(10));
  });

  test('the token directory is exempted by the walk', () {
    expect(
      skipped,
      contains('packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart'),
    );
  });
}
