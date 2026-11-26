// ZOD-EPH-002: the on-device matched-TT gate
// (integration_test/swiss_ephemeris_accuracy_test.dart) uses a Dart const copy
// of the Horizons reference fixture, because the fixture is not an app asset.
// This host test keeps the copy equal to the fixture, entry for entry.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/swiss_reference_longitudes_tt.dart';

void main() {
  final fixture = jsonDecode(
    File(
      '../../packages/ephemeris_swiss/test/fixtures/'
      'reference_longitudes_tt.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  final entries = (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('the const copy has the fixture tolerance', () {
    expect(swissTtToleranceArcseconds, fixture['toleranceArcseconds']! as num);
  });

  test('the const copy has the same number of entries', () {
    expect(swissTtReferenceLongitudes.length, entries.length);
  });

  test('every const entry equals the fixture entry (body, utc, jdTt, '
      'ttMinusUtSeconds, longitude)', () {
    for (var i = 0; i < entries.length; i++) {
      final c = swissTtReferenceLongitudes[i];
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
}
