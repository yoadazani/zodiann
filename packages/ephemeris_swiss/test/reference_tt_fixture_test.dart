// ZOD-EPH-002: shape of the JPL Horizons reference asked at Terrestrial Time,
// for the matched-TT accuracy gate. The device test (apps/astro_mobile/
// integration_test/swiss_ephemeris_accuracy_test.dart) gates on it; a host test
// in astro_mobile keeps the const copy equal to this file.
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
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
  late Map<String, Object?> fixture;
  late List<Map<String, Object?>> entries;
  late List<String> referenceDates;

  setUpAll(() {
    fixture = jsonDecode(
      File('test/fixtures/reference_longitudes_tt.json').readAsStringSync(),
    ) as Map<String, Object?>;
    entries = (fixture['entries']! as List<Object?>)
        .cast<Map<String, Object?>>();
    referenceDates =
        ((jsonDecode(
                  File('../astro_core/test/fixtures/reference_dates.json')
                      .readAsStringSync(),
                ) as Map<String, Object?>)['dates']!
                as List<Object?>)
            .cast<String>();
  });

  double seconds(Map<String, Object?> e) =>
      (e['ttMinusUtSeconds']! as num).toDouble();

  test('records where the numbers came from and how', () {
    expect(fixture['source'], contains('Horizons'));
    expect(fixture['retrievedOn'], isNotEmpty);
    final query = fixture['queryParameters']! as Map<String, Object?>;
    expect(query['CENTER'], '500@399');
    expect(query['QUANTITIES'], '31');
    expect(query['TIME_TYPE'], 'TT');
    expect(query['TLIST_TYPE'], 'JD');
  });

  test('the tolerance is one arcsecond', () {
    expect(fixture['toleranceArcseconds'], 1);
  });

  test('every body at every reference instant, once', () {
    final keys = [for (final e in entries) '${e['body']}|${e['utc']}'];
    expect(keys.toSet(), hasLength(keys.length));
    expect(keys.toSet(), {
      for (final date in referenceDates)
        for (final body in _physicalBodies) '$body|$date',
    });
    expect(referenceDates, hasLength(53));
  });

  test('every longitude is in [0, 360) and jdTt has nine decimals', () {
    for (final e in entries) {
      final longitude = (e['longitudeDegrees']! as num).toDouble();
      expect(longitude, greaterThanOrEqualTo(0));
      expect(longitude, lessThan(360));
      expect(e['jdTt'], matches(RegExp(r'^\d+\.\d{9}$')));
    }
  });

  test('from 1972 the TT is the one the app conversion gives', () {
    var checked = 0;
    for (final e in entries) {
      final utc = DateTime.parse(e['utc']! as String);
      final time = ephemerisTimeFor(utc);
      if (time is! TerrestrialTime) continue;
      checked++;
      expect(
        e['jdTt'],
        julianDayUt(utc.add(time.ttMinusUtc)).toStringAsFixed(9),
        reason: '${e['utc']}',
      );
      expect(
        seconds(e),
        time.ttMinusUtc.inMicroseconds / 1000000,
        reason: '${e['utc']}',
      );
    }
    expect(checked, greaterThan(300));
  });

  test('before 1972 the TT is UT plus the recorded delta T', () {
    var checked = 0;
    for (final e in entries) {
      final utc = DateTime.parse(e['utc']! as String);
      if (ephemerisTimeFor(utc) is! UniversalTime) continue;
      checked++;
      expect(
        double.parse(e['jdTt']! as String),
        closeTo(julianDayUt(utc) + seconds(e) / 86400, 2e-9),
        reason: '${e['utc']}',
      );
      // Delta T from 1899 to 1971 lies well inside these bounds.
      expect(seconds(e), inInclusiveRange(-10, 50), reason: '${e['utc']}');
    }
    expect(checked, greaterThan(100));
  });
}
