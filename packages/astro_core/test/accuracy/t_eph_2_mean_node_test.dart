// T-EPH-2 (ZOD-TST-002): the mean ascending node equals the spec formula.
//
// Independence rules (product-owner decision, see the TST-002 task file):
// * Only `meanAscendingNodeAt` — the code under test — is imported from
//   production. Expected values are computed here with a separately
//   implemented reference: a Meeus Julian-Day algorithm from the calendar
//   fields (production uses microseconds since J2000), literal coefficients
//   and a local normalizer. Production constants and `normalizeDegrees` are
//   deliberately not imported, so a transcription bug cannot hide.
// * Both the production formula and the reference compute T from the UTC
//   instant, as the EphemerisPort contract requires.
//
// Run from `packages/astro_core` (as `melos exec` / `melos run test` do): the
// fixture path is relative to the package.
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart' show meanAscendingNodeAt;
import 'package:test/test.dart';

const _tolerance = 1e-9; // degrees

/// Julian Day of a UTC instant from its calendar fields (Meeus, Astronomical
/// Algorithms, ch. 7; Gregorian calendar).
double _julianDay(DateTime utc) {
  var year = utc.year;
  var month = utc.month;
  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  final a = (year / 100).floor();
  final b = 2 - a + (a / 4).floor();
  final dayFraction =
      (utc.hour +
          utc.minute / 60 +
          utc.second / 3600 +
          utc.millisecond / 3.6e6 +
          utc.microsecond / 3.6e9) /
      24;
  return (365.25 * (year + 4716)).floor() +
      (30.6001 * (month + 1)).floor() +
      utc.day +
      dayFraction +
      b -
      1524.5;
}

double _centuriesSinceJ2000(DateTime utc) =>
    (_julianDay(utc) - 2451545.0) / 36525;

/// Spec formula, written independently: Ω = 125.04452 − 1934.136261·T.
double _referenceOmega(DateTime utc) =>
    125.04452 - 1934.136261 * _centuriesSinceJ2000(utc);

double _norm360(double degrees) {
  final r = degrees % 360;
  return (r == 360 || r == 0) ? 0.0 : r;
}

/// Signed smallest difference in degrees, in [−180, 180). (Dart's `%` with a
/// positive divisor is already non-negative.) Callers compare `.abs()`.
double _wrap180(double degrees) => (degrees + 180) % 360 - 180;

/// The full Meeus mean-node formula (Astronomical Algorithms, eq. 47.7) — the
/// "full formula" the spec's < 0.01° claim refers to.
///
/// Compared at the same T as production (Julian centuries from the UTC
/// instant). Meeus defines T in terrestrial time; ΔT (≈ 64 s around 2000)
/// shifts Ω by ≈ 4e-5°, far below the 0.01° bound, so the formula
/// comparison is unaffected.
double _meeusOmega(double t) =>
    125.0445479 -
    1934.1362891 * t +
    0.0020754 * t * t +
    t * t * t / 467441 -
    t * t * t * t / 60616000;

List<DateTime> _referenceDates() {
  final json = jsonDecode(
    File('test/fixtures/reference_dates.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return [
    for (final s in (json['dates'] as List<dynamic>).cast<String>())
      DateTime.parse(s),
  ];
}

void main() {
  final dates = _referenceDates();

  group('T-EPH-2: mean node equals the spec formula', () {
    test('reference JD helper is correct at known epochs', () {
      expect(_julianDay(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
      expect(_julianDay(DateTime.utc(1899, 12, 31, 12)), 2415020.0);
      expect(_julianDay(DateTime.utc(2100, 1, 1, 12)), 2488070.0);
    });

    test('matches the independent reference on every reference date', () {
      expect(dates.length, greaterThanOrEqualTo(50));
      for (final t in dates) {
        final production = meanAscendingNodeAt(t).longitude;
        final reference = _norm360(_referenceOmega(t));
        expect(
          _wrap180(production - reference).abs(),
          lessThanOrEqualTo(_tolerance),
          reason: '$t: production $production, reference $reference',
        );
      }
    });

    test('speed is the constant -1934.136261 / 36525 °/day on every reference date', () {
      for (final t in dates) {
        expect(
          meanAscendingNodeAt(t).speed,
          -1934.136261 / 36525,
          reason: '$t',
        );
      }
    });
  });

  group('T-EPH-2: accuracy bound vs full Meeus formula', () {
    final epoch = DateTime.utc(2000, 1, 1, 12);
    const daysPerCentury = 36525;

    double deviation(DateTime utc) => _wrap180(
      meanAscendingNodeAt(utc).longitude -
          _norm360(_meeusOmega(_centuriesSinceJ2000(utc))),
    ).abs();

    test('the sweep reaches exactly T = −1 and T = +1', () {
      final first = epoch.add(const Duration(days: -daysPerCentury));
      final last = epoch.add(const Duration(days: daysPerCentury));

      expect(first, DateTime.utc(1899, 12, 31, 12));
      expect(last, DateTime.utc(2100, 1, 1, 12));
      expect(_centuriesSinceJ2000(first), -1.0);
      expect(_centuriesSinceJ2000(last), 1.0);
    });

    test('deviates from the full formula by less than 0.01° over ±100 years (daily)', () {
      var max = 0.0;
      var atDay = 0;
      for (var i = -daysPerCentury; i <= daysPerCentury; i++) {
        final d = deviation(epoch.add(Duration(days: i)));
        if (d > max) {
          max = d;
          atDay = i;
        }
      }

      expect(max, lessThan(0.01), reason: 'max $max° at day $atDay');
      // Pins the figure stated in the production docs (0.0021°) and proves
      // this is a real comparison, not production against itself.
      expect(max, closeTo(0.00213, 1e-5), reason: 'max $max° at day $atDay');
    });

    test('is within the bound on every reference date', () {
      for (final t in dates) {
        expect(deviation(t), lessThan(0.01), reason: '$t');
      }
    });
  });
}
