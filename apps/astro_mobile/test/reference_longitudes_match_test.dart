// ZOD-FND-003: the on-device Swiss Ephemeris check
// (integration_test/swiss_ephemeris_spike_test.dart) uses a Dart const copy
// of the Horizons reference fixture, because the fixture is not an app asset.
// This host test keeps the copy equal to the fixture, entry for entry.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/reference_longitudes.dart';

void main() {
  final fixture = jsonDecode(
    File(
      '../../packages/ephemeris_swiss/test/fixtures/reference_longitudes.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  final entries = (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('the const copy has the fixture tolerance', () {
    expect(toleranceArcseconds, (fixture['toleranceArcseconds']! as num));
  });

  test('the const copy has the same number of entries', () {
    expect(referenceLongitudes.length, entries.length);
  });

  test('every const entry equals the fixture entry (body, utc, longitude)', () {
    for (var i = 0; i < entries.length; i++) {
      expect(
        referenceLongitudes[i].body,
        entries[i]['body'],
        reason: 'entry $i',
      );
      expect(referenceLongitudes[i].utc, entries[i]['utc'], reason: 'entry $i');
      expect(
        referenceLongitudes[i].longitudeDegrees,
        (entries[i]['longitudeDegrees']! as num).toDouble(),
        reason: 'entry $i',
      );
    }
  });
}
