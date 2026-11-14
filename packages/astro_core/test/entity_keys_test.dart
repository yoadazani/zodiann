// ZOD-L10-007 (L-9): every entity has a stable, language-independent key.
// The key lists are pinned literally: changing one changes persisted JSON
// and needs an explicit decision.
import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  test('Body JSON keys are pinned', () {
    // body_test.dart pins the value names; this pins the JSON form.
    expect(Body.values.map((b) => b.toJson()), [
      'sun',
      'moon',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
      'pluto',
      'node',
    ]);
  });

  group('ZodiacSign', () {
    test('keys are pinned, in zodiacal order', () {
      expect(ZodiacSign.values.map((s) => s.toJson()), [
        'aries',
        'taurus',
        'gemini',
        'cancer',
        'leo',
        'virgo',
        'libra',
        'scorpio',
        'sagittarius',
        'capricorn',
        'aquarius',
        'pisces',
      ]);
    });

    test('fromJson round-trips every key', () {
      for (final sign in ZodiacSign.values) {
        expect(ZodiacSign.fromJson(sign.toJson()), sign);
      }
    });

    test('fromJson rejects unknown, wrong-case and non-string input', () {
      for (final bad in <Object?>['Aries', 'conj', '', 3, null]) {
        expect(
          () => ZodiacSign.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('AspectKind', () {
    test('keys are pinned, in table order', () {
      expect(AspectKind.values.map((a) => a.toJson()), [
        'conjunction',
        'sextile',
        'square',
        'trine',
        'opposition',
      ]);
    });

    test('fromJson round-trips every key', () {
      for (final aspect in AspectKind.values) {
        expect(AspectKind.fromJson(aspect.toJson()), aspect);
      }
    });

    test('fromJson rejects unknown, wrong-case and non-string input', () {
      for (final bad in <Object?>['Aries', 'conj', '', 3, null]) {
        expect(
          () => AspectKind.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });
}
