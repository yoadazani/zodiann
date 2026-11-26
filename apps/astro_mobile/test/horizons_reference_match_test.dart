// ZOD-TST-001: the on-device T-EPH-1 / ACC-1 gate
// (integration_test/swiss_ephemeris_accuracy_test.dart) uses a Dart const copy
// of the shared Horizons reference dataset, because a fixture is not an app
// asset. This host test keeps the copy equal to the dataset, row for row.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/horizons_reference.dart';

void main() {
  final dataset = jsonDecode(
    File('../../packages/astro_core/test/fixtures/horizons_reference.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  List<Map<String, Object?>> rows(String key) =>
      (dataset[key]! as List<Object?>).cast<Map<String, Object?>>();

  test('the const copy has the dataset version and tolerance', () {
    expect(horizonsDatasetVersion, dataset['version']);
    expect(horizonsToleranceArcseconds, dataset['toleranceArcseconds']! as num);
  });

  test('every const entry equals the dataset entry (body, utc, jdTt, '
      'ttMinusUtSeconds, longitude)', () {
    final entries = rows('entries');
    expect(horizonsReference.length, entries.length);
    for (var i = 0; i < entries.length; i++) {
      final c = horizonsReference[i];
      final e = entries[i];
      expect(c.body, e['body'], reason: 'entry $i');
      expect(c.utc, e['utc'], reason: 'entry $i');
      expect(c.jdTt, e['jdTt'], reason: 'entry $i');
      expect(
        c.ttMinusUtSeconds,
        (e['ttMinusUtSeconds']! as num).toDouble(),
        reason: 'entry $i',
      );
      expect(
        c.longitudeDegrees,
        (e['longitudeDegrees']! as num).toDouble(),
        reason: 'entry $i',
      );
    }
  });

  test('every const cross-check row equals the dataset row', () {
    final crossCheck = rows('utcCrossCheck');
    expect(horizonsUtCrossCheck.length, crossCheck.length);
    for (var i = 0; i < crossCheck.length; i++) {
      final c = horizonsUtCrossCheck[i];
      final e = crossCheck[i];
      expect(c.body, e['body'], reason: 'row $i');
      expect(c.utc, e['utc'], reason: 'row $i');
      expect(
        c.longitudeDegrees,
        (e['longitudeDegrees']! as num).toDouble(),
        reason: 'row $i',
      );
    }
  });
}
