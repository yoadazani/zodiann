// ZOD-EPH-002: the bundled leap-second table is the published one
// (docs/decisions/ZOD-EPH-002-time-scale.md).
import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Transcribed from IERS `Leap_Second.dat`, retrieved 2026-11-25, "Updated
/// through IERS Bulletin 72 issued in July 2026", "File expires on
/// 28 June 2027". Each row is (year, month, TAI − UTC) from day 1 at
/// 00:00:00 UTC. The file itself is not committed: its redistribution terms
/// are unverified. A second, independent guard reads the vendored Swiss
/// Ephemeris list (packages/ephemeris_swiss/test/vendored_time_data_test.dart).
const _published = [
  (1972, 1, 10),
  (1972, 7, 11),
  (1973, 1, 12),
  (1974, 1, 13),
  (1975, 1, 14),
  (1976, 1, 15),
  (1977, 1, 16),
  (1978, 1, 17),
  (1979, 1, 18),
  (1980, 1, 19),
  (1981, 7, 20),
  (1982, 7, 21),
  (1983, 7, 22),
  (1985, 7, 23),
  (1988, 1, 24),
  (1990, 1, 25),
  (1991, 1, 26),
  (1992, 7, 27),
  (1993, 7, 28),
  (1994, 7, 29),
  (1996, 1, 30),
  (1997, 7, 31),
  (1999, 1, 32),
  (2006, 1, 33),
  (2009, 1, 34),
  (2012, 7, 35),
  (2015, 7, 36),
  (2017, 1, 37),
];

LeapSecondTable _table(List<LeapSecondStep> steps, {DateTime? validUntil}) =>
    LeapSecondTable(
      steps: steps,
      validUntil: validUntil ?? DateTime.utc(2031),
      source: 's',
      bulletin: 'b',
    );

LeapSecondStep _step(DateTime from, [int seconds = 10]) =>
    LeapSecondStep(from: from, taiMinusUtcSeconds: seconds);

void main() {
  final bundled = LeapSecondTable.bundled;

  test('the bundled steps are the published list', () {
    expect(
      [for (final s in bundled.steps) (s.from, s.taiMinusUtcSeconds)],
      [
        for (final (year, month, seconds) in _published)
          (DateTime.utc(year, month), seconds),
      ],
    );
  });

  test('the bundled table records its validity end and provenance', () {
    expect(bundled.validUntil, DateTime.utc(2027, 6, 28));
    expect(bundled.source, 'IERS Leap_Second.dat');
    expect(bundled.bulletin, 'Bulletin C 72 (July 2026)');
  });

  test('the steps cannot be changed', () {
    expect(
      () => bundled.steps.add(_step(DateTime.utc(2030), 38)),
      throwsUnsupportedError,
    );
  });

  test('TAI − UTC is the last step at or before the instant', () {
    const tick = Duration(microseconds: 1);
    expect(
      bundled.taiMinusUtcSecondsAt(DateTime.utc(1972).subtract(tick)),
      isNull,
    );
    expect(bundled.taiMinusUtcSecondsAt(DateTime.utc(1972)), 10);
    expect(bundled.taiMinusUtcSecondsAt(DateTime.utc(2017).subtract(tick)), 36);
    expect(bundled.taiMinusUtcSecondsAt(DateTime.utc(2100)), 37);
  });

  test('a non-UTC instant is rejected', () {
    expect(
      () => bundled.taiMinusUtcSecondsAt(DateTime(2000)),
      throwsArgumentError,
    );
  });

  group('construction rejects', () {
    final a = DateTime.utc(2000);
    final b = DateTime.utc(2001);

    test('no steps', () {
      expect(() => _table([]), throwsArgumentError);
    });

    test('a non-UTC step', () {
      expect(() => _table([_step(DateTime(2000))]), throwsArgumentError);
    });

    test('a non-UTC validity end', () {
      expect(
        () => _table([_step(a)], validUntil: DateTime(2031)),
        throwsArgumentError,
      );
    });

    test('steps that are not strictly ascending', () {
      expect(() => _table([_step(b), _step(a)]), throwsArgumentError);
      expect(() => _table([_step(a), _step(a, 11)]), throwsArgumentError);
    });

    test('a validity end that is not after the last step', () {
      expect(() => _table([_step(a)], validUntil: a), throwsArgumentError);
    });
  });
}
