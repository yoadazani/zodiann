import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Shape of the Horizons reference fixture used by the on-device run
/// (apps/astro_mobile/integration_test, ZOD-FND-003). The fixture is not an
/// app asset: the integration test uses a Dart const copy, which a host test
/// in astro_mobile keeps equal to this file.
void main() {
  final fixture =
      jsonDecode(File('test/fixtures/reference_longitudes.json').readAsStringSync())
          as Map<String, Object?>;
  final entries = (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('records where the numbers came from and how', () {
    expect(fixture['source'], contains('Horizons'));
    expect(fixture['retrievedOn'], isNotEmpty);
    final query = fixture['queryParameters']! as Map<String, Object?>;
    expect(query['QUANTITIES'], '31');
    expect(query['CENTER'], '500@399');
    expect(query['TIME_TYPE'], 'UT');
  });

  test('the tolerance is one arcsecond', () {
    expect(fixture['toleranceArcseconds'], 1.0);
  });

  test('has at least three entries and both bodies', () {
    expect(entries.length, greaterThanOrEqualTo(3));
    expect(entries.map((e) => e['body']).toSet(), {'sun', 'moon'});
  });

  test('every entry is a UTC instant with a longitude in [0, 360)', () {
    for (final e in entries) {
      final utc = DateTime.parse(e['utc']! as String);
      expect(utc.isUtc, isTrue, reason: '${e['utc']} must end in Z');
      final longitude = (e['longitudeDegrees']! as num).toDouble();
      expect(longitude, inInclusiveRange(0, 360));
      expect(longitude, lessThan(360));
    }
  });
}
