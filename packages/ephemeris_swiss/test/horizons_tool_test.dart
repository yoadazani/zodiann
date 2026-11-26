// ZOD-TST-001: the pure query and check functions of the Horizons reference
// tool (tool/horizons/horizons.dart). Offline: nothing here sends a request.
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
}
