import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/repo_root.dart';

void main() {
  // Literal copy of `kit.js` SIGNS (design-reference/zodiann/_source/kit.js).
  const expected = {
    ZodiacSign.aries: ZodiacElement.fire,
    ZodiacSign.taurus: ZodiacElement.earth,
    ZodiacSign.gemini: ZodiacElement.air,
    ZodiacSign.cancer: ZodiacElement.water,
    ZodiacSign.leo: ZodiacElement.fire,
    ZodiacSign.virgo: ZodiacElement.earth,
    ZodiacSign.libra: ZodiacElement.air,
    ZodiacSign.scorpio: ZodiacElement.water,
    ZodiacSign.sagittarius: ZodiacElement.fire,
    ZodiacSign.capricorn: ZodiacElement.earth,
    ZodiacSign.aquarius: ZodiacElement.air,
    ZodiacSign.pisces: ZodiacElement.water,
  };

  test('every sign maps to its element (literal table)', () {
    expect(ZodiacSign.values, hasLength(12));
    for (final sign in ZodiacSign.values) {
      expect(elementOf(sign), expected[sign], reason: sign.name);
    }
  });

  test('each element covers exactly three signs, four apart', () {
    for (final element in ZodiacElement.values) {
      expect(
        ZodiacSign.values.where((s) => elementOf(s) == element),
        hasLength(3),
        reason: element.name,
      );
    }
    for (var i = 0; i < 8; i++) {
      expect(
        elementOf(ZodiacSign.values[i]),
        elementOf(ZodiacSign.values[i + 4]),
      );
    }
  });

  test('agrees with kit.js (second source)', () {
    final kit = File(
      '${repoRoot().path}/design-reference/zodiann/_source/kit.js',
    ).readAsStringSync();
    final pattern = RegExp(r"\{ k: '(\w+)', g: '[^']+', el: '(\w+)'");
    final rows = pattern.allMatches(kit).toList();
    expect(rows, hasLength(12));
    for (final row in rows) {
      final sign = ZodiacSign.fromJson(row.group(1));
      expect(elementOf(sign).name, row.group(2), reason: sign.name);
    }
  });
}
