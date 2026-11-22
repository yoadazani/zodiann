// ZOD-EPH-004 D12 (Task 5 Step 7): shape of the JPL Horizons reference
// fixture taken at the TT instants the adapter's own UTC-to-TT conversion
// assigns to the reference UTC instants. The device test (apps/astro_mobile/
// integration_test/astronomy_accuracy_test.dart) gates on it; a host test in
// astro_mobile keeps the const copy equal to this file.
import 'dart:convert';
import 'dart:io';

import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:test/test.dart';

const _physicalBodies = {
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
};

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/reference_longitudes_tt.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final entries = (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final referenceDates =
      (jsonDecode(
            File('../astro_core/test/fixtures/reference_dates.json')
                .readAsStringSync(),
          ) as Map<String, Object?>)['dates']!
          as List<Object?>;

  final rangeStart = DateTime.utc(1899, 12, 31, 12);
  final rangeEnd = DateTime.utc(2100, 1, 1, 12);

  test('records where the numbers came from, how, and what TT means here', () {
    expect(fixture['source'], contains('Horizons'));
    expect(fixture['retrievedOn'], isNotEmpty);
    final query = fixture['queryParameters']! as Map<String, Object?>;
    expect(query['QUANTITIES'], '31');
    expect(query['CENTER'], '500@399');
    expect(query['TIME_TYPE'], 'TT');
    expect(query['TLIST_TYPE'], 'JD');
    expect(fixture['timeScale'], contains('Astronomy_TimeFromDays'));
  });

  test('the tolerance is 60 arcseconds, one arcminute (ACC-2)', () {
    expect(fixture['toleranceArcseconds'], 60);
  });

  test('every instant of reference_dates.json has all ten bodies', () {
    final present = {for (final e in entries) '${e['body']}|${e['utc']}'};
    for (final date in referenceDates) {
      for (final body in _physicalBodies) {
        expect(present, contains('$body|$date'), reason: '$body at $date');
      }
    }
  });

  test('there is no entry for the node and none outside the ten bodies', () {
    expect({for (final e in entries) e['body']}, _physicalBodies);
  });

  test('there is one entry per body and instant, no duplicates', () {
    final keys = [for (final e in entries) '${e['body']}|${e['utc']}'];
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('every entry is a UTC instant in the covered range with a longitude '
      'in [0, 360)', () {
    for (final e in entries) {
      final utc = DateTime.parse(e['utc']! as String);
      expect(utc.isUtc, isTrue, reason: '${e['utc']} must end in Z');
      expect(utc.isBefore(rangeStart), isFalse, reason: '${e['utc']}');
      expect(utc.isAfter(rangeEnd), isFalse, reason: '${e['utc']}');
      final longitude = (e['longitudeDegrees']! as num).toDouble();
      expect(longitude, greaterThanOrEqualTo(0));
      expect(longitude, lessThan(360));
    }
  });

  test(
    'utDays is exactly the adapter\'s own daysSinceJ2000 of the instant',
    () {
      for (final e in entries) {
        final utc = DateTime.parse(e['utc']! as String);
        expect(
          (e['utDays']! as num).toDouble(),
          daysSinceJ2000(utc),
          reason: '${e['utc']}',
        );
      }
    },
  );

  test('jdTt is ttDays plus 2451545.0 to nine decimals', () {
    for (final e in entries) {
      final tt = (e['ttDays']! as num).toDouble();
      final jd = e['jdTt']! as String;
      expect(jd, matches(RegExp(r'^\d+\.\d{9}$')), reason: '${e['utc']}');
      expect(double.parse(jd), closeTo(tt + 2451545.0, 1e-9));
    }
  });

  test('deltaTSeconds is (ttDays - utDays) x 86400 and plausible '
      '(-10 to 210 s)', () {
    for (final e in entries) {
      final ut = (e['utDays']! as num).toDouble();
      final tt = (e['ttDays']! as num).toDouble();
      final deltaT = (e['deltaTSeconds']! as num).toDouble();
      expect((tt - ut) * 86400, closeTo(deltaT, 1e-6), reason: '${e['utc']}');
      expect(deltaT, inInclusiveRange(-10, 210), reason: '${e['utc']}');
    }
  });

  test('every body at one instant carries the same time conversion', () {
    final byInstant = <String, (double, double, double)>{};
    for (final e in entries) {
      final value = (
        (e['utDays']! as num).toDouble(),
        (e['ttDays']! as num).toDouble(),
        (e['deltaTSeconds']! as num).toDouble(),
      );
      final previous = byInstant.putIfAbsent(e['utc']! as String, () => value);
      expect(value, previous, reason: '${e['utc']}');
    }
  });
}
