// ZOD-EPH-004 Task 5: shape of the JPL Horizons reference fixture that the
// on-device ACC-2 check uses (apps/astro_mobile/integration_test). The fixture
// is not an app asset: the integration test uses a Dart const copy, which a
// host test in astro_mobile keeps equal to this file.
import 'dart:convert';
import 'dart:io';

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
    File('test/fixtures/reference_longitudes.json').readAsStringSync(),
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

  test('records where the numbers came from and how', () {
    expect(fixture['source'], contains('Horizons'));
    expect(fixture['retrievedOn'], isNotEmpty);
    final query = fixture['queryParameters']! as Map<String, Object?>;
    expect(query['QUANTITIES'], '31');
    expect(query['CENTER'], '500@399');
    expect(query['TIME_TYPE'], 'UT');
  });

  test('the tolerance is 60 arcseconds, one arcminute (ACC-2)', () {
    expect(fixture['toleranceArcseconds'], 60);
  });

  bool covered(Object? date) {
    final utc = DateTime.parse(date! as String);
    return !utc.isBefore(rangeStart) && !utc.isAfter(rangeEnd);
  }

  // The shared date set reaches 2100-12-31 (ZOD-TST-001); the backup's covered
  // range ends at 2100-01-01T12:00Z, so its reference stops there.
  test('every instant of reference_dates.json in the covered range has all ten '
      'bodies', () {
    final present = {for (final e in entries) '${e['body']}|${e['utc']}'};
    for (final date in referenceDates.where(covered)) {
      for (final body in _physicalBodies) {
        expect(present, contains('$body|$date'), reason: '$body at $date');
      }
    }
  });

  test('only instants after the covered range are left out', () {
    expect(referenceDates.where((date) => !covered(date)).toSet(), {
      '2100-07-01T00:00:00Z',
      '2100-12-31T00:00:00Z',
      '2100-12-31T23:59:59Z',
    });
    // Both boundary instants stay in.
    expect(
      referenceDates.where(covered),
      containsAll(['1899-12-31T12:00:00Z', '2100-01-01T12:00:00Z']),
    );
  });

  test(
    'there is no entry for the node and no entry outside the ten bodies',
    () {
      expect({for (final e in entries) e['body']}, _physicalBodies);
    },
  );

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

  test('there is one entry per body and instant, no duplicates', () {
    final keys = [for (final e in entries) '${e['body']}|${e['utc']}'];
    expect(keys.toSet(), hasLength(keys.length));
  });
}
