// ZOD-L10-001 (L-8): no shipped UI source passes a string literal to Text,
// SelectableText or TextSpan(text:); user-visible text comes from
// ZodiannLocalizations. Scope (PO decision N2): the lib/ of every
// non-pure-Dart member, generated lib/l10n/ included; test/ and
// integration_test/ may use literal text. Runs from the workspace root on
// every `melos run test`. The scanner's gaps are documented in
// text_literals.dart.
import 'dart:io';

import 'package:test/test.dart';

import 'text_literals.dart';

const _pureDart = {
  'astro_core',
  'gann_core',
  'ephemeris_swiss',
  'ephemeris_astronomy',
};

void main() {
  final scanned = <String>[];
  final hits = <String>[];

  for (final top in ['apps', 'packages']) {
    for (final member in Directory(top).listSync().whereType<Directory>()) {
      if (_pureDart.contains(
        member.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
      )) {
        continue;
      }
      final lib = Directory('${member.path}/lib');
      if (!lib.existsSync()) continue;
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;
        scanned.add(path);
        for (final hit in findTextLiterals(file.readAsStringSync())) {
          hits.add('$path:${hit.line} ${hit.call}');
        }
      }
    }
  }

  test('no shipped UI source passes a string literal to Text, SelectableText '
      'or TextSpan', () {
    expect(
      hits,
      isEmpty,
      reason:
          'L-8: read the text from ZodiannLocalizations.of(context) '
          'instead.\n${hits.join('\n')}',
    );
  });

  test('scans the app, shared_ui and the generated localizations', () {
    expect(
      scanned,
      containsAll([
        'apps/astro_mobile/lib/src/app.dart',
        'packages/shared_ui/lib/src/widgets/zodiann_button.dart',
        'packages/shared_ui/lib/l10n/zodiann_localizations.dart',
      ]),
    );
    expect(scanned.length, greaterThanOrEqualTo(10));
  });
}
