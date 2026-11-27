// ZOD-TST-001: shape, coverage and provenance of the shared JPL Horizons
// reference dataset (T-EPH-1 / ACC-1), and the checks it must pass on its own
// values: the time-scale control, and a retrograde instant for each body from
// Mercury to Pluto (owner decision: the Sun and the Moon are excluded). The
// accuracy comparison itself runs on a device
// (apps/astro_mobile/integration_test/swiss_ephemeris_accuracy_test.dart).
//
// Run from `packages/astro_core` (as `melos exec` / `melos run test` do): the
// fixture paths are relative to the package.
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart' show SupportedDateRange;
import 'package:test/test.dart';

const _bodies = [
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
];

/// The declared retrograde instants, confirmed from Horizons (design
/// section 5.2).
const _retrograde = {
  ('mercury', '1953-11-18T00:00:00Z'),
  ('mercury', '2049-05-11T00:00:00Z'),
  ('venus', '2012-06-12T00:00:00Z'),
  ('mars', '1956-09-10T00:00:00Z'),
  ('jupiter', '2023-10-15T00:00:00Z'),
  ('saturn', '2023-08-01T00:00:00Z'),
  ('uranus', '2023-10-15T00:00:00Z'),
  ('neptune', '2023-08-01T00:00:00Z'),
  ('pluto', '2023-08-01T00:00:00Z'),
};

final _leapSecondsStart = DateTime.utc(1972);

Map<String, Object?> _read(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

double _number(Map<String, Object?> row, String field) =>
    (row[field]! as num).toDouble();

/// The shortest signed angle from [from] to [to], in degrees.
double _step(double from, double to) => (to - from + 180) % 360 - 180;

bool _isBefore1972(String utc) =>
    DateTime.parse(utc).isBefore(_leapSecondsStart);

void main() {
  late Map<String, Object?> dataset;
  late Map<String, Object?> dateFile;
  late List<String> dates;

  setUpAll(() {
    dataset = _read('horizons_reference.json');
    dateFile = _read('reference_dates.json');
    dates = (dateFile['dates']! as List<Object?>).cast<String>();
  });

  List<Map<String, Object?>> rows(String key) =>
      (dataset[key]! as List<Object?>).cast<Map<String, Object?>>();

  Map<(String, String), Map<String, Object?>> keyed(String key) => {
    for (final row in rows(key))
      (row['body']! as String, row['utc']! as String): row,
  };

  test('provenance', () {
    expect(dataset['version'], 1);
    expect(dataset['referenceDatesVersion'], dateFile['version']);
    expect(dataset['source'], contains('Horizons'));
    expect(dataset['retrievedOn'], isNotEmpty);
    expect(dataset['apiVersion'], isNotEmpty);
    expect(
      (dataset['targetSources']! as Map<String, Object?>).keys.toSet(),
      _bodies.toSet(),
    );
    final query = dataset['queryParameters']! as Map<String, Object?>;
    expect(query['CENTER'], '500@399');
    expect(query['EPHEM_TYPE'], 'OBSERVER');
    expect(query['QUANTITIES'], '31');
    expect(query['TIME_TYPE'], 'TT');
    expect(query['TLIST_TYPE'], 'JD');
    expect(query['APPARENT'], 'AIRLESS');
    expect(dataset['toleranceArcseconds'], 1);
  });

  test('every body at every shared instant, once', () {
    final entries = rows('entries');
    expect(entries, hasLength(640));
    expect(keyed('entries').keys.toSet(), {
      for (final body in _bodies)
        for (final utc in dates) (body, utc),
    });
    for (final entry in entries) {
      expect(_number(entry, 'longitudeDegrees'), greaterThanOrEqualTo(0));
      expect(_number(entry, 'longitudeDegrees'), lessThan(360));
      expect(entry['jdTt'], matches(RegExp(r'^\d+\.\d{9}$')));
    }
  });

  test('at least 50 instants from 1900 to 2100', () {
    final inRange = dates.where(
      (utc) => SupportedDateRange.range.contains(DateTime.parse(utc)),
    );
    expect(inRange.length, greaterThanOrEqualTo(50));
    expect(inRange, hasLength(63));
  });

  test('includes instants at year boundaries and the end of the range', () {
    final covered = {for (final entry in rows('entries')) entry['utc']};
    expect(
      covered,
      containsAll(['1999-12-31T23:59:59Z', '2100-12-31T23:59:59Z']),
    );
  });

  test('a retrograde instant for each body from mercury to pluto, none for '
      'sun or moon', () {
    final evidence = keyed('retrogradeEvidence');
    final entries = keyed('entries');

    expect(rows('retrogradeEvidence'), hasLength(_retrograde.length));
    expect(evidence.keys.toSet(), _retrograde);
    expect({for (final (body, _) in _retrograde) body}, {..._bodies.skip(2)});
    for (final key in _retrograde) {
      final (body, utc) = key;
      expect(dates, contains(utc));
      final at = _number(entries[key]!, 'longitudeDegrees');
      final row = evidence[key]!;
      expect(
        _step(_number(row, 'longitudeBefore'), at),
        lessThan(0),
        reason: '$body $utc',
      );
      expect(
        _step(at, _number(row, 'longitudeAfter')),
        lessThan(0),
        reason: '$body $utc',
      );
    }
  });

  test('retrograde evidence is asked 3 days either side', () {
    final entries = keyed('entries');
    for (final row in rows('retrogradeEvidence')) {
      final entry = entries[(row['body']! as String, row['utc']! as String)]!;
      final at = double.parse(entry['jdTt']! as String);
      expect(double.parse(row['jdTtBefore']! as String), closeTo(at - 3, 2e-9));
      expect(double.parse(row['jdTtAfter']! as String), closeTo(at + 3, 2e-9));
    }
  });

  test(
    'the UT cross-check holds every body from 1972, and nothing earlier',
    () {
      expect(rows('utcCrossCheck'), hasLength(420));
      expect(keyed('utcCrossCheck').keys.toSet(), {
        for (final body in _bodies)
          for (final utc in dates)
            if (!_isBefore1972(utc)) (body, utc),
      });
      final query =
          dataset['utcCrossCheckQueryParameters']! as Map<String, Object?>;
      expect(query['TIME_TYPE'], 'UT');
      expect(query['TLIST_TYPE'], 'JD');
    },
  );

  // Design section 6, link 4: entirely inside Horizons. Its own TDB - UT turns
  // a UT instant into the TT asked, and both answers must agree.
  test('Horizons TIME_TYPE=TT is the same scale as its UT', () {
    final control = rows('timeScaleControl');
    expect(control, hasLength(22));
    expect(
      {for (final row in control) row['utc']},
      {...dates.where(_isBefore1972)},
    );
    for (final row in control) {
      final utc = row['utc']! as String;
      expect(
        _step(
              _number(row, 'longitudeAtUt'),
              _number(row, 'longitudeAtTt'),
            ).abs() *
            3600,
        lessThanOrEqualTo(0.002),
        reason: utc,
      );
      expect(
        double.parse(row['jdTtDerived']! as String),
        closeTo(
          double.parse(row['jdUt']! as String) +
              _number(row, 'tdbMinusUtSeconds') / 86400,
          2e-9,
        ),
        reason: utc,
      );
    }
    // Where the two scales barely differ the control would prove nothing.
    expect(
      control.any((row) => _number(row, 'tdbMinusUtSeconds').abs() > 10),
      isTrue,
    );
  });
}
