// ZOD-UI-002 (MASTER.md §3): sentence case for every label, no all-caps.
// Flutter has no text-transform, so all-caps can only come from upper-casing
// strings in code. Walks apps/*/lib and packages/*/lib like
// no_color_literals_test.dart; unlike it, skips the pure-Dart members, which
// hold no UI text. Runs from the workspace root on every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

const _pureDart = {
  'astro_core',
  'gann_core',
  'ephemeris_swiss',
  'ephemeris_astronomy',
};

void main() {
  test('no UI source upper-cases text (sentence case)', () {
    final roots = [
      for (final parent in ['apps', 'packages'])
        for (final dir in Directory(parent).listSync().whereType<Directory>())
          if (!_pureDart.contains(
                dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
              ) &&
              Directory('${dir.path}/lib').existsSync())
            '${dir.path}/lib',
    ];
    expect(roots, isNotEmpty);
    final hits = <String>[];
    for (final root in roots) {
      for (final file
          in Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          var code = lines[i];
          final comment = code.indexOf('//');
          if (comment >= 0) code = code.substring(0, comment);
          if (code.contains('toUpperCase(')) {
            hits.add('${file.path.replaceAll(r'\', '/')}:${i + 1}');
          }
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'MASTER §3: sentence case; write the string in sentence case '
          'instead.\n${hits.join('\n')}',
    );
  });
}
