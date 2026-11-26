// ZOD-TST-001 (from ZOD-EPH-002): the time basis of the shared Horizons
// reference dataset. The device test (apps/astro_mobile/integration_test/
// swiss_ephemeris_accuracy_test.dart) gates on the dataset; these host checks
// show that its TT is the app's conversion, and that Horizons asked at the UTC
// instant agrees.
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> dataset;

  setUpAll(() {
    dataset = jsonDecode(
      File('../astro_core/test/fixtures/horizons_reference.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
  });

  List<Map<String, Object?>> rows(String key) =>
      (dataset[key]! as List<Object?>).cast<Map<String, Object?>>();

  double seconds(Map<String, Object?> e) =>
      (e['ttMinusUtSeconds']! as num).toDouble();

  test('from 1972 the TT is the one the app conversion gives', () {
    var checked = 0;
    for (final e in rows('entries')) {
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
    expect(checked, 420);
    // The canonical string (design section 8.3), not an exact-decimal rounding.
    expect(
      {
        for (final e in rows('entries'))
          if (e['utc'] == '2012-06-12T00:00:00Z') e['jdTt'],
      },
      {'2456090.500766018'},
    );
  });

  test('before 1972 the TT is UT plus the recorded delta T', () {
    var checked = 0;
    for (final e in rows('entries')) {
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
    expect(checked, 220);
  });

  // The only check of the conversion that does not use it (ZOD-EPH-002 branch
  // review, finding I1). The entries are asked at the TT the app computes, so
  // the matched-TT gate and the TT pin agree with the app whatever it computes,
  // and a UTC-input gate (1 arcsecond) resolves only about a second. The
  // cross-check was asked at the UTC instant (Horizons' UT), where Horizons
  // applies its own leap seconds from 1972. Both must give the same longitude.
  // The Moon moves about 0.55 arcseconds per second, so this tolerance catches
  // an error of a few milliseconds; the rounding of the answers accounts for
  // less than half of it.
  test('from 1972 Horizons asked at the app TT agrees with Horizons asked at '
      'UTC, within 0.002 arcseconds', () {
    final query =
        dataset['utcCrossCheckQueryParameters']! as Map<String, Object?>;
    expect(query['TIME_TYPE'], 'UT');
    final atUtc = <String, double>{};
    for (final e in rows('utcCrossCheck')) {
      // A cross-check asked in TT by mistake would pass every numeric gate.
      expect(
        e['jdUt'],
        julianDayUt(DateTime.parse(e['utc']! as String)).toStringAsFixed(9),
      );
      atUtc['${e['body']}|${e['utc']}'] = (e['longitudeDegrees']! as num)
          .toDouble();
    }
    // A literal, so the app's conversion plays no part in this comparison.
    final leapSecondsStart = DateTime.utc(1972);

    var checked = 0;
    final disagreements = <String>[];
    for (final e in rows('entries')) {
      final utc = DateTime.parse(e['utc']! as String);
      if (utc.isBefore(leapSecondsStart)) continue;
      final key = '${e['body']}|${e['utc']}';
      expect(atUtc, contains(key));
      checked++;
      var degrees =
          ((e['longitudeDegrees']! as num).toDouble() - atUtc[key]!).abs() %
          360;
      if (degrees > 180) degrees = 360 - degrees;
      if (degrees * 3600 > 0.002) {
        disagreements.add('$key: ${degrees * 3600} arcsec');
      }
    }

    expect(checked, 420);
    expect(disagreements, isEmpty);
  });
}
