// ZOD-EPH-004 D12: the on-device ACC-2 gate (integration_test/
// astronomy_accuracy_test.dart) uses a Dart const copy of the TT reference
// fixture, because the fixture is not an app asset. This host test keeps the
// copy equal to the fixture, entry for entry, including the time conversion
// the fixture assumed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/astronomy_reference_longitudes_tt.dart';

void main() {
  final fixture = jsonDecode(
    File(
      '../../packages/ephemeris_astronomy/test/fixtures/'
      'reference_longitudes_tt.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  final entries = (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('the const copy has the fixture tolerance', () {
    expect(
      astronomyTtToleranceArcseconds,
      fixture['toleranceArcseconds']! as num,
    );
  });

  test('the const copy has the same number of entries', () {
    expect(astronomyTtReferenceLongitudes.length, entries.length);
  });

  test('every const entry equals the fixture entry (body, utc, utDays, '
      'ttDays, deltaTSeconds, longitude)', () {
    for (var i = 0; i < entries.length; i++) {
      final c = astronomyTtReferenceLongitudes[i];
      final e = entries[i];
      expect(c.body, e['body'], reason: 'entry $i');
      expect(c.utc, e['utc'], reason: 'entry $i');
      expect(c.utDays, (e['utDays']! as num).toDouble(), reason: 'entry $i');
      expect(c.ttDays, (e['ttDays']! as num).toDouble(), reason: 'entry $i');
      expect(
        c.deltaTSeconds,
        (e['deltaTSeconds']! as num).toDouble(),
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
