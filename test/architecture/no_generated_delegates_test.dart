// ZOD-L10-001 (final review): nobody registers the generated
// `ZodiannLocalizations.localizationsDelegates`. It is public through
// package:shared_ui and its generated doc comment recommends it, but it lists
// flutter_localizations' deprecated delegates, which register a different
// MaterialLocalizations type than material_ui's widgets read: Hebrew users
// would get English Material strings. Register
// `const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]`
// instead. Scans lib/ and test/ of every member (harnesses copy patterns).
import 'dart:io';

import 'package:test/test.dart';

import 'generated_delegates.dart';

void main() {
  group('findGeneratedDelegateUses', () {
    test('flags a use, with its line', () {
      expect(
        findGeneratedDelegateUses(
          'a;\nlocalizationsDelegates: ZodiannLocalizations.localizationsDelegates,',
        ),
        [2],
      );
    });

    test('flags a spread and an import-prefixed use', () {
      expect(
        findGeneratedDelegateUses(
          '[...ZodiannLocalizations.localizationsDelegates, '
          'ui.ZodiannLocalizations . localizationsDelegates]',
        ),
        [1, 1],
      );
    });

    test('ignores comments, strings, the declaration and the right list', () {
      expect(
        findGeneratedDelegateUses('''
/// localizationsDelegates: ZodiannLocalizations.localizationsDelegates,
// ZodiannLocalizations.localizationsDelegates
final s = 'ZodiannLocalizations.localizationsDelegates';
static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [];
localizationsDelegates: const [ZodiannLocalizations.delegate],
'''),
        isEmpty,
      );
    });
  });

  final scanned = <String>[];
  final hits = <String>[];
  for (final top in ['apps', 'packages']) {
    for (final member in Directory(top).listSync().whereType<Directory>()) {
      for (final sub in ['lib', 'test', 'integration_test']) {
        final dir = Directory('${member.path}/$sub');
        if (!dir.existsSync()) continue;
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          final path = file.path.replaceAll(r'\', '/');
          if (!path.endsWith('.dart')) continue;
          scanned.add(path);
          for (final line in findGeneratedDelegateUses(
            file.readAsStringSync(),
          )) {
            hits.add('$path:$line');
          }
        }
      }
    }
  }

  test('no source registers ZodiannLocalizations.localizationsDelegates', () {
    expect(
      hits,
      isEmpty,
      reason:
          'Use const [ZodiannLocalizations.delegate, '
          '...GlobalMaterialLocalizations.delegates] (material_ui).\n'
          '${hits.join('\n')}',
    );
  });

  test('scans the app, shared_ui tests and the generated file', () {
    expect(
      scanned,
      containsAll([
        'apps/astro_mobile/lib/src/app.dart',
        'apps/astro_mobile/test/l10n_test.dart',
        'packages/shared_ui/test/l10n/zodiann_localizations_test.dart',
        'packages/shared_ui/lib/l10n/zodiann_localizations.dart',
      ]),
    );
  });
}
