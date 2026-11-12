import 'dart:ui' show lerpDouble;

import 'package:astro_core/astro_core.dart' show Body;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'samples.dart';

/// Registers the four shared tests for one extension type.
///
/// [keys] is the MASTER.md §2 token list for the group, typed out here
/// (independently of the production code and of samples.dart).
void _extensionTests<T extends ThemeExtension<T>>({
  required String name,
  required String keyTestName,
  required List<String> keys,
  required T Function(int seed) sample,
  required Map<String, Color> Function(T) tokens,
  required T Function(T a, T b) copyAll,
  required T Function(T a, Color c) copyFirst,
  required T Function(T a, Color c) copyLast,
  double Function(T)? opacity,
}) {
  group(name, () {
    final a = sample(1);
    final b = sample(2);

    test(keyTestName, () {
      expect(tokens(a).keys.toList(), keys);
      expect(
        tokens(a).values.toList(),
        List.generate(keys.length, (i) => sampleColor(1, i)),
        reason: 'tokens getter must map each key to its own field',
      );
    });

    test('lerp interpolates every token at t = 0.5', () {
      final mid = a.lerp(b, 0.5) as T;
      for (final k in keys) {
        expect(
          tokens(mid)[k],
          Color.lerp(tokens(a)[k], tokens(b)[k], 0.5),
          reason: k,
        );
      }
      expect(tokens(a.lerp(b, 0) as T), tokens(a));
      expect(tokens(a.lerp(b, 1) as T), tokens(b));
      expect(a.lerp(null, 0.5), same(a));
      if (opacity != null) {
        expect(opacity(mid), lerpDouble(opacity(a), opacity(b), 0.5));
      }
    });

    test('copyWith changes exactly one token', () {
      const c = Color.fromARGB(255, 99, 99, 99);
      for (final (index, changed) in [
        (0, copyFirst(a, c)),
        (keys.length - 1, copyLast(a, c)),
      ]) {
        for (var i = 0; i < keys.length; i++) {
          expect(
            tokens(changed)[keys[i]],
            i == index ? c : tokens(a)[keys[i]],
            reason: keys[i],
          );
        }
      }
      expect(tokens(a.copyWith() as T), tokens(a));
      if (opacity != null) {
        expect(opacity(a.copyWith() as T), opacity(a));
      }
    });

    test('copyWith of every field yields the other sample', () {
      final copied = copyAll(a, b);
      expect(tokens(copied), tokens(b));
      if (opacity != null) expect(opacity(copied), opacity(b));
    });
  });
}

void main() {
  _extensionTests<ZodiannSurfaces>(
    name: 'ZodiannSurfaces',
    keyTestName: 'ZodiannSurfaces tokens are MASTER §2.1, in order',
    keys: const [
      'bg',
      'bg-raised',
      'surface',
      'surface-2',
      'surface-3',
      'line',
      'line-soft',
      'text',
      'text-2',
      'text-3',
      'accent',
      'accent-strong',
      'accent-soft',
      'accent-line',
      'on-accent',
      'focus',
      'scrim',
      'danger',
      'ok',
    ],
    sample: sampleSurfaces,
    tokens: (x) => x.tokens,
    copyAll: copyAllZodiannSurfaces,
    copyFirst: (x, c) => x.copyWith(bg: c),
    copyLast: (x, c) => x.copyWith(ok: c),
  );

  _extensionTests<SquareColors>(
    name: 'SquareColors',
    keyTestName: 'SquareColors tokens are MASTER §2.2, in order',
    keys: const [
      'axis-fill',
      'axis-ink',
      'axis',
      'diag-fill',
      'diag-ink',
      'diag',
      'eighth-fill',
      'eighth-ink',
      'cell-fill',
      'cell-ink',
      'cell-line',
      'center',
      'today',
      'sel-outer',
      'sel-inner',
    ],
    sample: sampleSquare,
    tokens: (x) => x.tokens,
    copyAll: copyAllSquareColors,
    copyFirst: (x, c) => x.copyWith(axisFill: c),
    copyLast: (x, c) => x.copyWith(selInner: c),
  );

  _extensionTests<ZodiacColors>(
    name: 'ZodiacColors',
    keyTestName: 'ZodiacColors tokens are MASTER §2.3 elements',
    keys: const ['fire', 'earth', 'air', 'water'],
    sample: sampleZodiac,
    tokens: (x) => x.tokens,
    copyAll: copyAllZodiacColors,
    copyFirst: (x, c) => x.copyWith(fire: c),
    copyLast: (x, c) => x.copyWith(water: c),
    opacity: (x) => x.signTintOpacity,
  );

  _extensionTests<AspectColors>(
    name: 'AspectColors',
    keyTestName: 'AspectColors tokens are MASTER §2.3 aspects',
    keys: const ['asp-conj', 'asp-soft', 'asp-hard'],
    sample: sampleAspects,
    tokens: (x) => x.tokens,
    copyAll: copyAllAspectColors,
    copyFirst: (x, c) => x.copyWith(conj: c),
    copyLast: (x, c) => x.copyWith(hard: c),
  );

  _extensionTests<BodyColors>(
    name: 'BodyColors',
    keyTestName: 'BodyColors covers every Body',
    keys: const [
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
    ],
    sample: sampleBodies,
    tokens: (x) => x.tokens,
    copyAll: copyAllBodyColors,
    copyFirst: (x, c) => x.copyWith(sun: c),
    copyLast: (x, c) => x.copyWith(node: c),
  );

  test('BodyColors.of agrees with tokens for every Body', () {
    final bodies = sampleBodies(3);
    expect(bodies.tokens.keys, Body.values.map((b) => b.name));
    for (final b in Body.values) {
      expect(bodies.of(b), bodies.tokens[b.name], reason: b.name);
    }
  });
}
