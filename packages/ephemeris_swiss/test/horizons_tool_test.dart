// ZOD-TST-001: the pure query, check and parse functions of the Horizons
// reference tool (tool/horizons/horizons.dart). Offline: nothing here sends a
// request; the parser is tested on two answers of the pilot of 2026-11-26.
import 'dart:io';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:test/test.dart';

import '../tool/horizons/horizons.dart';

/// The two requests that produced test/fixtures/horizons_sample_{tt,ut}.txt,
/// exactly as sent on 2026-11-26 (design section 8.5).
const _pilotTtUrl =
    'https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%27301%27'
    '&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27OBSERVER%27'
    '&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27'
    '&TLIST=%272415020.000000000+2441317.500488241+2451545.000000000'
    '+2488434.500789167%27'
    '&TIME_TYPE=%27TT%27&TIME_DIGITS=%27FRACSEC%27&CAL_FORMAT=%27BOTH%27'
    '&QUANTITIES=%2731%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27'
    '&CSV_FORMAT=%27YES%27&APPARENT=%27AIRLESS%27';

const _pilotUtUrl =
    'https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%27301%27'
    '&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27OBSERVER%27'
    '&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27'
    '&TLIST=%272415020.000000000+2441317.500000000+2451545.000000000'
    '+2488434.500789167%27'
    '&TIME_TYPE=%27UT%27&TIME_DIGITS=%27FRACSEC%27&CAL_FORMAT=%27BOTH%27'
    '&QUANTITIES=%2730%2C31%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27'
    '&CSV_FORMAT=%27YES%27&APPARENT=%27AIRLESS%27';

const _utc = '2000-01-01T00:00:00Z';

LongitudeRow _row(
  double longitude, {
  String body = 'moon',
  String utc = _utc,
}) => (body: body, utc: utc, longitudeDegrees: longitude);

String _url(Map<String, String> query) =>
    Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', query).toString();

void main() {
  group('horizonsQuery', () {
    Map<String, String> query({
      HorizonsTimeType timeType = HorizonsTimeType.tt,
      String? quantities,
    }) {
      const days = ['2451545.000000000', '2451546.000000000'];
      return quantities == null
          ? horizonsQuery(command: '301', julianDays: days, timeType: timeType)
          : horizonsQuery(
              command: '301',
              julianDays: days,
              timeType: timeType,
              quantities: quantities,
            );
    }

    test('the query is exactly the approved parameters', () {
      expect(query(), {
        'format': 'text',
        'COMMAND': "'301'",
        'OBJ_DATA': "'NO'",
        'MAKE_EPHEM': "'YES'",
        'EPHEM_TYPE': "'OBSERVER'",
        'CENTER': "'500@399'",
        'TLIST_TYPE': "'JD'",
        'TLIST': "'2451545.000000000 2451546.000000000'",
        'TIME_TYPE': "'TT'",
        'TIME_DIGITS': "'FRACSEC'",
        'CAL_FORMAT': "'BOTH'",
        'QUANTITIES': "'31'",
        'ANG_FORMAT': "'DEG'",
        'EXTRA_PREC': "'YES'",
        'CSV_FORMAT': "'YES'",
        'APPARENT': "'AIRLESS'",
      });
      expect(query(timeType: HorizonsTimeType.ut)['TIME_TYPE'], "'UT'");
      expect(query(quantities: '30,31')['QUANTITIES'], "'30,31'");
    });

    test('the query reproduces the two pilot requests', () {
      expect(
        _url(
          horizonsQuery(
            command: '301',
            julianDays: [
              '2415020.000000000',
              '2441317.500488241',
              '2451545.000000000',
              '2488434.500789167',
            ],
            timeType: HorizonsTimeType.tt,
          ),
        ),
        _pilotTtUrl,
      );
      expect(
        _url(
          horizonsQuery(
            command: '301',
            julianDays: [
              '2415020.000000000',
              '2441317.500000000',
              '2451545.000000000',
              '2488434.500789167',
            ],
            timeType: HorizonsTimeType.ut,
            quantities: '30,31',
          ),
        ),
        _pilotUtUrl,
      );
    });

    test('julian days must be ascending with nine decimals', () {
      for (final days in [
        ['2.000000000', '1.000000000'],
        ['2.000000000', '2.000000000'],
        ['2451545.0'],
        <String>[],
      ]) {
        expect(
          () => horizonsQuery(
            command: '301',
            julianDays: days,
            timeType: HorizonsTimeType.tt,
          ),
          throwsArgumentError,
          reason: '$days',
        );
      }
    });

    test('the commands are the ten approved body numbers', () {
      expect(horizonsCommands, {
        'sun': '10',
        'moon': '301',
        'mercury': '199',
        'venus': '299',
        'mars': '499',
        'jupiter': '599',
        'saturn': '699',
        'uranus': '799',
        'neptune': '899',
        'pluto': '999',
      });
    });
  });

  test('signedDegrees wraps', () {
    expect(signedDegrees(359.9, 0.1), closeTo(0.2, 1e-9));
    expect(signedDegrees(0.1, 359.9), closeTo(-0.2, 1e-9));
    expect(signedDegrees(10, 190), -180);
  });

  test('isRetrograde needs both steps backward, across 0 degrees too', () {
    expect(isRetrograde(before: 0.2, at: 0.0, after: 359.8), isTrue);
    expect(isRetrograde(before: 359.8, at: 0.0, after: 0.2), isFalse);
    expect(isRetrograde(before: 10, at: 9, after: 9.5), isFalse);
    expect(isRetrograde(before: 10, at: 10, after: 9), isFalse);
  });

  group('changedRows', () {
    test('equal rows are unchanged', () {
      expect(changedRows([_row(10)], [_row(10)]), isEmpty);
    });

    test('the tolerance is 0.001 arcseconds', () {
      expect(changedRows([_row(10)], [_row(10 + 0.0009 / 3600)]), isEmpty);
      final changed = changedRows([_row(10)], [_row(10 + 0.0011 / 3600)]);
      expect(changed, hasLength(1));
      expect(changed.single, contains('moon'));
      expect(changed.single, contains(_utc));
    });

    test('a baseline row missing from the next rows is reported', () {
      final changed = changedRows(
        [_row(10), _row(20, body: 'sun')],
        [_row(10)],
      );
      expect(changed, hasLength(1));
      expect(changed.single, contains('missing'));
      expect(changed.single, contains('sun'));
    });

    test('an extra row is not a change', () {
      expect(
        changedRows([_row(10)], [_row(10), _row(20, body: 'sun')]),
        isEmpty,
      );
    });

    test('the difference is the shortest angle across 0 degrees', () {
      final baseline = [_row(359.9999999)];
      final next = [_row(0.0000001)];
      expect(changedRows(baseline, next), isEmpty);
      expect(
        changedRows(baseline, next, toleranceArcseconds: 0.0001),
        hasLength(1),
      );
    });
  });

  parserTests();
  retrogradeTests();
}

/// The delta T the vendored library gives the two candidate instants before
/// 1972, in seconds.
const _deltaT = {
  '1953-11-18T00:00:00Z': 30.572200534016,
  '1956-09-10T00:00:00Z': 31.563208632313,
};

/// Design section 5.1, written out.
const _primaries = <Declaration>[
  (body: 'mercury', utc: '1953-11-18T00:00:00Z'),
  (body: 'mercury', utc: '2049-05-11T00:00:00Z'),
  (body: 'venus', utc: '2012-06-12T00:00:00Z'),
  (body: 'mars', utc: '1956-09-10T00:00:00Z'),
  (body: 'jupiter', utc: '2023-10-15T00:00:00Z'),
  (body: 'saturn', utc: '2023-08-01T00:00:00Z'),
  (body: 'uranus', utc: '2023-10-15T00:00:00Z'),
  (body: 'neptune', utc: '2023-08-01T00:00:00Z'),
  (body: 'pluto', utc: '2023-08-01T00:00:00Z'),
];

const _backups = {
  'mercury': '2016-05-13T00:00:00Z',
  'venus': '2004-06-14T00:00:00Z',
  'mars': '2003-08-28T00:00:00Z',
  'jupiter': '2024-10-20T00:00:00Z',
  'saturn': '2024-08-01T00:00:00Z',
  'uranus': '2024-10-20T00:00:00Z',
  'neptune': '2024-08-01T00:00:00Z',
  'pluto': '2024-08-01T00:00:00Z',
};

const _retrogradeBodies = [
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
];

/// A result for [body] that is retrograde exactly when [passes].
RetrogradeResult _result(
  String body, {
  required bool isBackup,
  required bool passes,
  String utc = _utc,
}) => (
  body: body,
  utc: utc,
  isBackup: isBackup,
  before: passes ? 11 : 9,
  at: 10,
  after: passes ? 9 : 11,
);

void retrogradeTests() {
  group('ttJulianDay', () {
    DateTime at(String utc) => DateTime.parse(utc);
    String plusSeconds(String utc, double seconds) =>
        (julianDayUt(at(utc)) + seconds / 86400).toStringAsFixed(9);

    test('from 1972 uses leap seconds', () {
      // TAI - UTC was 34 s until 2012-07-01, and 37 s in 2023.
      expect(
        ttJulianDay(at('2012-06-12T00:00:00Z')),
        plusSeconds('2012-06-12T00:00:00Z', 66.184),
      );
      expect(
        ttJulianDay(at('2023-08-01T00:00:00Z')),
        plusSeconds('2023-08-01T00:00:00Z', 69.184),
      );
    });

    test('before 1972 it adds the given delta T', () {
      expect(
        ttJulianDay(at('1953-11-18T00:00:00Z'), historicalDeltaTSeconds: 30),
        plusSeconds('1953-11-18T00:00:00Z', 30),
      );
    });

    test('before 1972 without a finite delta T throws ArgumentError', () {
      for (final deltaT in [null, double.nan, double.infinity]) {
        expect(
          () => ttJulianDay(
            at('1953-11-18T00:00:00Z'),
            historicalDeltaTSeconds: deltaT,
          ),
          throwsArgumentError,
          reason: '$deltaT',
        );
      }
    });

    test('1971-12-31T23:59:59Z uses the given delta T', () {
      expect(
        ttJulianDay(at('1971-12-31T23:59:59Z'), historicalDeltaTSeconds: 30),
        plusSeconds('1971-12-31T23:59:59Z', 30),
      );
    });

    test('1972-01-01T00:00:00Z is +42.184 s even when a delta T is given', () {
      // The string the pilot sent for this instant.
      expect(
        ttJulianDay(DateTime.utc(1972), historicalDeltaTSeconds: 30),
        '2441317.500488241',
      );
    });

    test("2100-12-31T23:59:59Z is the pilot's last instant", () {
      expect(ttJulianDay(at('2100-12-31T23:59:59Z')), '2488434.500789167');
    });
  });

  test('shiftJulianDay moves whole days and keeps the fraction', () {
    expect(shiftJulianDay('2441317.500488241', -3), '2441314.500488241');
    expect(shiftJulianDay('2441317.500488241', 3), '2441320.500488241');
  });

  group('retrograde candidates', () {
    test('the primaries cover mercury to pluto and never sun or moon', () {
      expect(retrogradePrimaries, _primaries);
      expect({
        for (final p in retrogradePrimaries) p.body,
      }, _retrogradeBodies.toSet());
    });

    test('every primary body has a backup', () {
      expect(retrogradeBackups, _backups);
      expect(retrogradeBackups.keys.toSet(), {
        for (final p in retrogradePrimaries) p.body,
      });
    });

    test('the declarations are the primaries', () {
      expect(retrogradeDeclarations, _primaries);
    });

    test('the historical instants are 1953-11-18 and 1956-09-10', () {
      expect(retrogradeHistoricalInstants(), [
        '1953-11-18T00:00:00Z',
        '1956-09-10T00:00:00Z',
      ]);
    });

    test('eight requests, mercury to pluto, 51 times', () {
      // The TT Julian day sent for each instant.
      const julianDays = {
        '1953-11-18T00:00:00Z': '2434699.500353845',
        '1956-09-10T00:00:00Z': '2435726.500365315',
        '2003-08-28T00:00:00Z': '2452879.500742870',
        '2004-06-14T00:00:00Z': '2453170.500742870',
        '2012-06-12T00:00:00Z': '2456090.500766018',
        '2016-05-13T00:00:00Z': '2457521.500789167',
        '2023-08-01T00:00:00Z': '2460157.500800741',
        '2023-10-15T00:00:00Z': '2460232.500800741',
        '2024-08-01T00:00:00Z': '2460523.500800741',
        '2024-10-20T00:00:00Z': '2460603.500800741',
        '2049-05-11T00:00:00Z': '2469572.500800741',
      };
      final requests = retrogradeRequests(_deltaT);
      expect([for (final r in requests) r.first.body], _retrogradeBodies);
      expect(
        [for (final r in requests) r.length * 3],
        [9, 6, 6, 6, 6, 6, 6, 6],
      );
      for (final request in requests) {
        final body = request.first.body;
        expect({for (final c in request) c.body}, {body});
        // The primaries and the backup of this body, ascending by instant.
        final expected = [
          for (final p in _primaries)
            if (p.body == body) (p.utc, false),
          (_backups[body]!, true),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        expect(
          [for (final c in request) (c.utc, c.isBackup)],
          expected,
          reason: body,
        );
        final sent = [for (final c in request) ...c.julianDays];
        for (var i = 1; i < sent.length; i++) {
          expect(double.parse(sent[i]), greaterThan(double.parse(sent[i - 1])));
        }
        for (final candidate in request) {
          final at = julianDays[candidate.utc]!;
          final [whole, fraction] = at.split('.');
          expect(candidate.julianDays, [
            '${int.parse(whole) - 3}.$fraction',
            at,
            '${int.parse(whole) + 3}.$fraction',
          ], reason: '$body ${candidate.utc}');
        }
      }
    });

    test('a missing delta T throws', () {
      expect(
        () => retrogradeRequests({'1953-11-18T00:00:00Z': 30}),
        throwsArgumentError,
      );
    });
  });

  group('retrograde results', () {
    List<HorizonsRow> rowsFor(
      List<RetrogradeCandidate> candidates,
      List<double> longitudes,
    ) {
      final days = [for (final c in candidates) ...c.julianDays];
      return [
        for (var i = 0; i < days.length; i++)
          (
            julianDay: days[i],
            longitudeDegrees: longitudes[i],
            tdbMinusUtSeconds: null,
          ),
      ];
    }

    test('results pair three rows with each candidate', () {
      final venus = retrogradeRequests(_deltaT)[1];
      final results = retrogradeResults(
        venus,
        rowsFor(venus, [10, 9, 8, 20, 21, 22]),
      );
      expect(results, [
        (
          body: 'venus',
          utc: '2004-06-14T00:00:00Z',
          isBackup: true,
          before: 10.0,
          at: 9.0,
          after: 8.0,
        ),
        (
          body: 'venus',
          utc: '2012-06-12T00:00:00Z',
          isBackup: false,
          before: 20.0,
          at: 21.0,
          after: 22.0,
        ),
      ]);
    });

    test('a row count that differs throws', () {
      final venus = retrogradeRequests(_deltaT)[1];
      final rows = rowsFor(venus, [10, 9, 8, 20, 21, 22]);
      expect(
        () => retrogradeResults(venus, rows.sublist(1)),
        throwsArgumentError,
      );
      expect(
        () => retrogradeResults(venus, [...rows, rows.last]),
        throwsArgumentError,
      );
    });

    test('the line shows both steps and the verdict', () {
      expect(
        retrogradeResultLine((
          body: 'venus',
          utc: '2004-06-14T00:00:00Z',
          isBackup: true,
          before: 0.5,
          at: 359.5,
          after: 358.5,
        )),
        'venus 2004-06-14T00:00:00Z backup: '
        '0.5000000 359.5000000 358.5000000, '
        'steps -1.0000000 -1.0000000, PASS',
      );
      expect(
        retrogradeResultLine((
          body: 'mars',
          utc: '1956-09-10T00:00:00Z',
          isBackup: false,
          before: 10,
          at: 9,
          after: 10,
        )),
        'mars 1956-09-10T00:00:00Z primary: '
        '10.0000000 9.0000000 10.0000000, '
        'steps -1.0000000 +1.0000000, FAIL',
      );
    });
  });

  group('retrogradeUnresolved', () {
    test('all pass: none', () {
      expect(
        retrogradeUnresolved([
          _result('venus', isBackup: false, passes: true),
          _result('venus', isBackup: true, passes: true),
        ]),
        isEmpty,
      );
    });

    test('a primary failing with its backup passing: none', () {
      expect(
        retrogradeUnresolved([
          _result('venus', isBackup: false, passes: false),
          _result('venus', isBackup: true, passes: true),
        ]),
        isEmpty,
      );
    });

    test('primary and backup failing: that body', () {
      expect(
        retrogradeUnresolved([
          _result('mars', isBackup: false, passes: true),
          _result('mars', isBackup: true, passes: true),
          _result('venus', isBackup: false, passes: false),
          _result('venus', isBackup: true, passes: false),
        ]),
        ['venus'],
      );
    });

    test('both Mercury primaries failing with the backup passing: mercury', () {
      expect(
        retrogradeUnresolved([
          _result('mercury', isBackup: false, passes: false),
          _result('mercury', isBackup: true, passes: true),
          _result('mercury', isBackup: false, passes: false),
        ]),
        ['mercury'],
      );
    });

    test('only a backup failing: none', () {
      expect(
        retrogradeUnresolved([
          _result('venus', isBackup: false, passes: true),
          _result('venus', isBackup: true, passes: false),
        ]),
        isEmpty,
      );
    });
  });
}

const _ttDays = [
  '2415020.000000000',
  '2441317.500488241',
  '2451545.000000000',
  '2488434.500789167',
];

const _utDays = [
  '2415020.000000000',
  '2441317.500000000',
  '2451545.000000000',
  '2488434.500789167',
];

const _firstRowTime = '1899-Dec-31 12:00:00.000,';

String _sample(String scale) =>
    File('test/fixtures/horizons_sample_$scale.txt').readAsStringSync();

/// [text] with the first [from] replaced; fails if there is nothing to replace.
String _edit(String text, String from, String to) {
  expect(text, contains(from));
  final edited = text.replaceFirst(from, to);
  expect(edited, isNot(text));
  return edited;
}

/// The row line of [text] that starts with the calendar time [time].
String _line(String text, String time) =>
    text.split('\n').singleWhere((line) => line.startsWith(' $time'));

HorizonsAnswer _parseTt(
  String text, {
  String command = '301',
  HorizonsTimeType timeType = HorizonsTimeType.tt,
  List<String> julianDays = _ttDays,
  bool expectTdbMinusUt = false,
}) => parseHorizonsAnswer(
  text,
  command: command,
  timeType: timeType,
  julianDays: julianDays,
  expectTdbMinusUt: expectTdbMinusUt,
);

HorizonsAnswer _parseUt(
  String text, {
  HorizonsTimeType timeType = HorizonsTimeType.ut,
  bool expectTdbMinusUt = true,
}) => parseHorizonsAnswer(
  text,
  command: '301',
  timeType: timeType,
  julianDays: _utDays,
  expectTdbMinusUt: expectTdbMinusUt,
);

/// A refusal by the check named [check].
Matcher _refusedBy(String check) => throwsA(
  isA<FormatException>().having(
    (e) => e.message,
    'message',
    startsWith('$check:'),
  ),
);

void parserTests() {
  group('parseHorizonsAnswer', () {
    late String tt;
    late String ut;
    setUpAll(() {
      tt = _sample('tt');
      ut = _sample('ut');
    });

    test('parses the TT sample', () {
      final answer = _parseTt(tt);
      expect([for (final r in answer.rows) r.julianDay], _ttDays);
      expect(
        [for (final r in answer.rows) r.longitudeDegrees],
        [265.2972999, 101.6302965, 223.3148557, 293.9451964],
      );
      expect([
        for (final r in answer.rows) r.tdbMinusUtSeconds,
      ], everyElement(isNull));
      expect(answer.apiVersion, '1.2');
      expect(answer.targetLine, contains('Moon (301)'));
      expect(answer.targetLine, contains('DE441'));
    });

    test('parses the UT sample with TDB-UT', () {
      final answer = _parseUt(ut);
      expect([for (final r in answer.rows) r.julianDay], _utDays);
      expect(
        [for (final r in answer.rows) r.longitudeDegrees],
        [265.2969812, 101.6302965, 223.3237860, 293.9567420],
      );
      expect(
        [for (final r in answer.rows) r.tdbMinusUtSeconds],
        [-1.946024, 42.183919, 64.183903, 69.183904],
      );
    });

    test('a CRLF variant parses to the same rows', () {
      expect(tt, isNot(contains('\r')));
      final lf = _parseTt(tt);
      final crlf = _parseTt(tt.replaceAll('\n', '\r\n'));
      expect(crlf.rows, lf.rows);
      expect(crlf.apiVersion, lf.apiVersion);
      expect(crlf.targetLine, lf.targetLine);
    });

    test('the UT sample read without TDB-UT gives the same longitudes', () {
      final answer = _parseUt(ut, expectTdbMinusUt: false);
      expect(
        [for (final r in answer.rows) r.longitudeDegrees],
        [265.2969812, 101.6302965, 223.3237860, 293.9567420],
      );
      expect([
        for (final r in answer.rows) r.tdbMinusUtSeconds,
      ], everyElement(isNull));
    });

    test('a requested time about 0.5 ms (0.518 ms) from the echo passes and '
        'the row carries the requested string', () {
      final answer = _parseTt(
        tt,
        julianDays: ['2415020.000000006', ..._ttDays.skip(1)],
      );
      expect(answer.rows.first.julianDay, '2415020.000000006');
    });

    group('refuses', () {
      test('a TT answer for a UT request', () {
        expect(
          () => _parseTt(tt, timeType: HorizonsTimeType.ut),
          _refusedBy('time scale'),
        );
      });

      test('a UT answer for a TT request', () {
        expect(
          () => _parseUt(
            ut,
            timeType: HorizonsTimeType.tt,
            expectTdbMinusUt: false,
          ),
          _refusedBy('time scale'),
        );
      });

      test('a stop time naming another scale', () {
        final text = _edit(tt, '00:01:08.1840 TT', '00:01:08.1840 UT');
        expect(() => _parseTt(text), _refusedBy('time scale'));
      });

      test('a start time naming another scale', () {
        final text = _edit(tt, '12:00:00.0000 TT', '12:00:00.0000 UT');
        expect(() => _parseTt(text), _refusedBy('time scale'));
      });

      test('a column header naming another scale', () {
        for (final (from, to) in [
          ('Date__(TT)__HR:MN:SC.fff', 'Date__(UT)__HR:MN:SC.fff'),
          ('Date_________JDTT', 'Date_________JDUT'),
        ]) {
          final text = _edit(tt, from, to);
          expect(() => _parseTt(text), _refusedBy('column'), reason: from);
        }
      });

      test('no ObsEcLon column', () {
        final text = _edit(tt, 'ObsEcLon,', 'ObsEcLng,');
        expect(() => _parseTt(text), _refusedBy('column'));
      });

      test('quantity 30 expected but absent', () {
        expect(
          () => _parseTt(tt, expectTdbMinusUt: true),
          _refusedBy('column'),
        );
      });

      test('a missing row', () {
        final row = _line(tt, '2000-Jan-01');
        final text = _edit(tt, '$row\n', '');
        expect(() => _parseTt(text), _refusedBy('rows'));
      });

      test('an extra row', () {
        final row = _line(tt, '2101-Jan-01');
        final text = _edit(tt, '$row\n', '$row\n$row\n');
        expect(() => _parseTt(text), _refusedBy('rows'));
      });

      test('a row missing a field', () {
        final text = _edit(
          tt,
          '2415020.000000000, , ,',
          '2415020.000000000, ,',
        );
        expect(() => _parseTt(text), _refusedBy('fields'));
      });

      test('two rows swapped', () {
        final first = _line(tt, '1972-Jan-01');
        final second = _line(tt, '2000-Jan-01');
        final text = _edit(tt, '$first\n$second\n', '$second\n$first\n');
        expect(() => _parseTt(text), _refusedBy('time'));
      });

      test('an echoed Julian day 2 ms off', () {
        final text = _edit(tt, '2415020.000000000,', '2415020.000000023,');
        expect(() => _parseTt(text), _refusedBy('time'));
      });

      test('an echoed calendar time 2 ms off', () {
        final text = _edit(tt, _firstRowTime, '1899-Dec-31 12:00:00.002,');
        expect(() => _parseTt(text), _refusedBy('time'));
      });

      test('a value that is not a number', () {
        for (final value in ['n.a.', 'NaN', 'Infinity']) {
          final text = _edit(tt, '265.2972999', value);
          expect(() => _parseTt(text), _refusedBy('number'), reason: value);
        }
      });

      test('a calendar time in another form', () {
        final text = _edit(tt, _firstRowTime, '1899-Xyz-31 12:00:00.000,');
        expect(() => _parseTt(text), _refusedBy('number'));
      });

      test('longitude printed to six decimals', () {
        final text = _edit(tt, '265.2972999', '265.297300');
        expect(() => _parseTt(text), _refusedBy('precision'));
      });

      test('quantity 30 printed to two decimals', () {
        final text = _edit(ut, '-1.946024', '-1.95');
        expect(() => _parseUt(text), _refusedBy('precision'));
      });

      test('longitude 360', () {
        final text = _edit(tt, '265.2972999', '360.0000000');
        expect(() => _parseTt(text), _refusedBy('longitude'));
      });

      test('a negative longitude', () {
        final text = _edit(tt, '265.2972999', '-0.0000001');
        expect(() => _parseTt(text), _refusedBy('longitude'));
      });

      test(r'no $$SOE', () {
        final text = _edit(tt, r'$$SOE', 'SOE');
        expect(() => _parseTt(text), _refusedBy('markers'));
      });

      test(r'no $$EOE', () {
        final text = _edit(tt, r'$$EOE', 'EOE');
        expect(() => _parseTt(text), _refusedBy('markers'));
      });

      test('no API version line', () {
        final text = _edit(tt, 'API VERSION: 1.2', 'API: 1.2');
        expect(() => _parseTt(text), _refusedBy('API version'));
      });

      test('another target', () {
        expect(() => _parseTt(tt, command: '10'), _refusedBy('target'));
      });

      test('a non-geocentric centre body', () {
        final text = _edit(
          tt,
          'Center body name: Earth (399)',
          'Center body name: Mars (499)',
        );
        expect(() => _parseTt(text), _refusedBy('centre'));
      });

      test('a non-geocentric site', () {
        final text = _edit(
          tt,
          'Center-site name: GEOCENTRIC',
          'Center-site name: NOT GEOCENTRIC',
        );
        expect(() => _parseTt(text), _refusedBy('centre'));
      });
    });
  });
}
