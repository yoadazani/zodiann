// ZOD-L10-001: unit tests for the ARB key-parity helpers.
import 'dart:io';

import 'package:test/test.dart';

import 'arb_keys.dart';

void main() {
  const en = '{"@@locale":"en","a":"A","@a":{},"b":"B"}';

  group('arbMessageKeys', () {
    test('top-level keys that do not start with @', () {
      expect(arbMessageKeys(en), {'a', 'b'});
    });

    test('invalid JSON throws FormatException', () {
      expect(() => arbMessageKeys('{"a": '), throwsFormatException);
    });

    test('a non-object top level throws FormatException', () {
      expect(() => arbMessageKeys('[1]'), throwsFormatException);
    });
  });

  group('arbLocale', () {
    test('reads @@locale', () => expect(arbLocale(en), 'en'));

    test('null when missing', () => expect(arbLocale('{"a":"A"}'), isNull));
  });

  group('arbHasDescription', () {
    test('true with a non-empty description', () {
      expect(
        arbHasDescription('{"a":"A","@a":{"description":"x"}}', 'a'),
        isTrue,
      );
    });

    test('false without metadata, without description, or empty', () {
      expect(arbHasDescription('{"a":"A"}', 'a'), isFalse);
      expect(arbHasDescription('{"a":"A","@a":{}}', 'a'), isFalse);
      expect(
        arbHasDescription('{"a":"A","@a":{"description":""}}', 'a'),
        isFalse,
      );
    });
  });

  group('keyParityProblems', () {
    test('a key missing from the translation', () {
      expect(
        keyParityProblems('app_en.arb', {
          'app_en.arb': {'a', 'b'},
          'app_he.arb': {'a'},
        }),
        ['app_he.arb is missing: b'],
      );
    });

    test('a key only in the translation', () {
      expect(
        keyParityProblems('app_en.arb', {
          'app_en.arb': {'a', 'b'},
          'app_he.arb': {'a', 'b', 'c'},
        }),
        ['app_he.arb has keys not in app_en.arb: c'],
      );
    });

    test('both directions at once, keys sorted', () {
      expect(
        keyParityProblems('app_en.arb', {
          'app_en.arb': {'a', 'c', 'b'},
          'app_he.arb': {'a', 'z', 'y'},
        }),
        [
          'app_he.arb is missing: b, c',
          'app_he.arb has keys not in app_en.arb: y, z',
        ],
      );
    });

    test('equal sets → no problems', () {
      expect(
        keyParityProblems('app_en.arb', {
          'app_en.arb': {'a'},
          'app_he.arb': {'a'},
        }),
        isEmpty,
      );
    });

    test('every language is checked, sorted by file', () {
      expect(
        keyParityProblems('app_en.arb', {
          'app_en.arb': {'a', 'b'},
          'app_he.arb': {'b'},
          'app_fr.arb': {'b'},
        }),
        ['app_fr.arb is missing: a', 'app_he.arb is missing: a'],
      );
    });
  });

  // ZOD-L10-014: the file-reading wiring (l10n.yaml lookup, directory scan,
  // filename filter) reports a missing key, proven on fixture packages.
  group('loadArbSources + keyParityProblems on a fixture package', () {
    late Directory pkg;

    setUp(() => pkg = Directory.systemTemp.createTempSync('l10n_fixture_'));
    tearDown(() => pkg.deleteSync(recursive: true));

    String arb(String locale, Iterable<String> keys) =>
        '{"@@locale":"$locale",${[for (final k in keys) '"$k":"v","@$k":{"description":"d"}'].join(',')}}';

    void write(String relative, String content) {
      File('${pkg.path}/$relative')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    void yaml({String arbDir = 'arb-dir: lib/l10n\n', String? template}) =>
        write(
          'l10n.yaml',
          '$arbDir${template ?? 'template-arb-file: app_en.arb\n'}',
        );

    List<String> problems() {
      final loaded = loadArbSources(pkg.path);
      return keyParityProblems(loaded.template, {
        for (final e in loaded.sources.entries) e.key: arbMessageKeys(e.value),
      });
    }

    test('all keys present, @key and @@locale not counted → no problems', () {
      yaml();
      write('lib/l10n/app_en.arb', arb('en', ['a', 'b']));
      write('lib/l10n/app_he.arb', arb('he', ['a', 'b']));
      expect(problems(), isEmpty);
    });

    test('a key missing from app_he.arb is named with its file', () {
      yaml();
      write('lib/l10n/app_en.arb', arb('en', ['a', 'b']));
      write('lib/l10n/app_he.arb', arb('he', ['a']));
      expect(problems(), ['app_he.arb is missing: b']);
    });

    test('a key removed from the template is reported on the translation', () {
      yaml();
      write('lib/l10n/app_en.arb', arb('en', ['a']));
      write('lib/l10n/app_he.arb', arb('he', ['a', 'b']));
      expect(problems(), ['app_he.arb has keys not in app_en.arb: b']);
    });

    test('a third language missing a key is reported by name', () {
      yaml();
      write('lib/l10n/app_en.arb', arb('en', ['a', 'b']));
      write('lib/l10n/app_he.arb', arb('he', ['a', 'b']));
      write('lib/l10n/app_fr.arb', arb('fr', ['a']));
      expect(problems(), ['app_fr.arb is missing: b']);
    });

    test('non-ARB files are ignored', () {
      yaml();
      write('lib/l10n/app_en.arb', arb('en', ['a']));
      write('lib/l10n/notes.txt', 'not json');
      write('lib/l10n/app_en.arb.bak', 'not json');
      expect(loadArbSources(pkg.path).sources.keys, ['app_en.arb']);
    });

    test('l10n.yaml without arb-dir fails naming the file', () {
      yaml(arbDir: '');
      expect(() => loadArbSources(pkg.path), throwsA(isA<TestFailure>()));
    });

    test('l10n.yaml without template-arb-file fails naming the file', () {
      yaml(template: '');
      expect(() => loadArbSources(pkg.path), throwsA(isA<TestFailure>()));
    });
  });
}
