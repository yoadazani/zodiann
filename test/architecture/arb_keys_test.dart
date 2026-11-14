// ZOD-L10-001: unit tests for the ARB key-parity helpers.
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
}
