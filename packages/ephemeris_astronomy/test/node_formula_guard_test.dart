// ZOD-EPH-004 acceptance: the node from this adapter still uses the ZOD-EPH-001
// formula (`MeanAscendingNodeFormula` in astro_core), never a value derived
// from astronomy-engine and never a second copy of the coefficients.
import 'dart:io';

import 'package:test/test.dart';

/// The coefficients of the mean ascending node formula, which live only in
/// `packages/astro_core/lib/src/ephemeris/mean_node.dart`.
const _coefficients = ['125.04452', '1934.136261'];

void main() {
  test('no source file of this package carries the node coefficients', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(dartFiles, isNotEmpty);
    for (final file in dartFiles) {
      final text = file.readAsStringSync();
      for (final coefficient in _coefficients) {
        expect(
          text.contains(coefficient),
          isFalse,
          reason: '${file.path} contains $coefficient',
        );
      }
    }
  });

  test('the adapter mixes in MeanAscendingNodeFormula', () {
    final text = File('lib/src/astronomy_ephemeris.dart').readAsStringSync();
    expect(text, contains('with MeanAscendingNodeFormula'));
    expect(text, contains('meanAscendingNode(utc)'));
  });
}
