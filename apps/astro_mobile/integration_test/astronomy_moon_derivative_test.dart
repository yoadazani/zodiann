// ZOD-EPH-004 Task 3 Step 1b: the project-authored analytic derivative of the
// Moon series, proved against upstream astronomy-engine on a device, with no
// finite differences anywhere. Run on an Android device or emulator:
//   flutter test integration_test/astronomy_moon_derivative_test.dart -d <device>
//
// What each test protects (see docs/spikes/ZOD-EPH-004-moon-derivative.md):
//  * value regression: our hand-copied constants reproduce upstream's CalcMoon;
//  * integral identity: a quadrature of our analytic rate over an interval
//    equals the change in upstream's position over that interval (it
//    integrates the rate, differentiates nothing, and is never used to produce
//    a speed; owner decision D11, Option A). It runs in TT: the rate is per
//    TT century, and integrating over UT would add about 1e-7 degrees;
//  * ECT consistency and rotation invariants: the velocity is rotated by the
//    same fixed chain as the position.
import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The value every double of a hook's buffer holds before the shim runs.
const double _sentinel = 1234.5;

const _source = NativeBodyStateSource();

/// Layout of `moonSeriesForTesting`.
const _lon = 0, _lat = 1, _dist = 2;
const _dLon = 3, _dLat = 4, _dDist = 5;
const _upLon = 6, _upLat = 7, _upDist = 8;

/// Layout of `moonStateForTesting`.
const _ecmR = 0, _ecmV = 3, _ectR = 6, _ectV = 9;

/// 8-point Gauss-Legendre nodes on [-1, 1] and their weights.
const _glNodes = [
  -0.9602898564975363,
  -0.7966664774136267,
  -0.5255324099163290,
  -0.1834346424956498,
  0.1834346424956498,
  0.5255324099163290,
  0.7966664774136267,
  0.9602898564975363,
];
const _glWeights = [
  0.1012285362903763,
  0.2223810344533745,
  0.3137066458778873,
  0.3626837833783620,
  0.3626837833783620,
  0.3137066458778873,
  0.2223810344533745,
  0.1012285362903763,
];

const _degrees = 180 / math.pi;

/// A difference of two angles in radians, reduced to (-pi, pi].
double _wrap(double d) {
  while (d > math.pi) {
    d -= 2 * math.pi;
  }
  while (d <= -math.pi) {
    d += 2 * math.pi;
  }
  return d;
}

List<double> _series(double centuriesTt) =>
    _source.moonSeriesForTesting(centuriesTt);

/// The instant [utDays] days after J2000.
DateTime _utc(double utDays) => DateTime.utc(
  2000,
  1,
  1,
  12,
).add(Duration(microseconds: (utDays * 86400000000).round()));

double _norm(List<double> v, int at) =>
    math.sqrt(v[at] * v[at] + v[at + 1] * v[at + 1] + v[at + 2] * v[at + 2]);

double _dot(List<double> a, int ai, List<double> b, int bi) =>
    a[ai] * b[bi] + a[ai + 1] * b[bi + 1] + a[ai + 2] * b[bi + 2];

double _crossNorm(List<double> a, int ai, List<double> b, int bi) {
  final x = a[ai + 1] * b[bi + 2] - a[ai + 2] * b[bi + 1];
  final y = a[ai + 2] * b[bi] - a[ai] * b[bi + 2];
  final z = a[ai] * b[bi + 1] - a[ai + 1] * b[bi];
  return math.sqrt(x * x + y * y + z * z);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('the test hooks: lengths and layout', () {
    test('moonSeriesForTesting writes exactly moonSeriesLength doubles', () {
      final plain = _source.moonSeriesForTesting(0.1);
      expect(plain, hasLength(moonSeriesLength));
      final guarded = _source.moonSeriesForTesting(0.1, guardDoubles: 4);
      expect(guarded, hasLength(moonSeriesLength + 4));
      for (var i = 0; i < moonSeriesLength; i++) {
        expect(guarded[i], isNot(_sentinel), reason: 'element $i not written');
        expect(guarded[i].isFinite, isTrue, reason: 'element $i');
      }
      for (var i = moonSeriesLength; i < guarded.length; i++) {
        expect(guarded[i], _sentinel, reason: 'guard element $i overwritten');
      }
      expect(guarded.sublist(0, moonSeriesLength), plain);
    });

    test('moonStateForTesting writes exactly moonStateLength doubles', () {
      final plain = _source.moonStateForTesting(1000.25);
      expect(plain, hasLength(moonStateLength));
      final guarded = _source.moonStateForTesting(1000.25, guardDoubles: 4);
      expect(guarded, hasLength(moonStateLength + 4));
      for (var i = 0; i < moonStateLength; i++) {
        expect(guarded[i], isNot(_sentinel), reason: 'element $i not written');
        expect(guarded[i].isFinite, isTrue, reason: 'element $i');
      }
      for (var i = moonStateLength; i < guarded.length; i++) {
        expect(guarded[i], _sentinel, reason: 'guard element $i overwritten');
      }
      expect(guarded.sublist(0, moonStateLength), plain);
    });

    test('timeForTesting writes exactly timeStateLength doubles: the UT '
        'days of the production path, then a plausible TT (D12)', () {
      final utc = DateTime.utc(2000, 1, 1, 12);
      final plain = _source.timeForTesting(utc);
      expect(plain, hasLength(timeStateLength));
      final guarded = _source.timeForTesting(utc, guardDoubles: 4);
      expect(guarded, hasLength(timeStateLength + 4));
      for (var i = 0; i < timeStateLength; i++) {
        expect(guarded[i], isNot(_sentinel), reason: 'element $i not written');
        expect(guarded[i].isFinite, isTrue, reason: 'element $i');
      }
      for (var i = timeStateLength; i < guarded.length; i++) {
        expect(guarded[i], _sentinel, reason: 'guard element $i overwritten');
      }
      expect(guarded.sublist(0, timeStateLength), plain);
      // out[0] is the UT days the production path sends; out[1] is the TT.
      expect(plain[0], daysSinceJ2000(utc));
      // The library's delta T at J2000 is about 64 seconds.
      expect((plain[1] - plain[0]) * 86400, closeTo(63.8, 1.0));
    });

    test('the series layout is lon, lat, dist, rates, upstream values', () {
      final s = _series(0.1);
      expect(s[_lon], inInclusiveRange(0, 2 * math.pi));
      expect(s[_lat].abs(), lessThan(0.1)); // the Moon stays within 5.3 deg
      expect(s[_dist], inInclusiveRange(0.0023, 0.0028)); // AU, 356k to 407k km
      // Rates per TT century: about 13.2 deg/day = 4.8e5 deg/century.
      expect(s[_dLon] * _degrees / 36525, inInclusiveRange(11.5, 15.6));
      expect(s[_upLon], inInclusiveRange(0, 2 * math.pi));
    });
  });

  group('the value path against upstream CalcMoon', () {
    test('10,000 instants across 1900 to 2100 agree to 1e-11', () {
      const count = 10000;
      var worstLon = 0.0, worstLat = 0.0, worstDist = 0.0;
      for (var i = 0; i < count; i++) {
        final t = -1 + 2 * i / (count - 1);
        final s = _series(t);
        worstLon = math.max(worstLon, _wrap(s[_lon] - s[_upLon]).abs());
        worstLat = math.max(worstLat, (s[_lat] - s[_upLat]).abs());
        worstDist = math.max(
          worstDist,
          (s[_dist] - s[_upDist]).abs() / s[_upDist],
        );
      }
      // ignore: avoid_print
      print(
        'value regression worst: lon $worstLon rad, lat $worstLat rad, '
        'dist $worstDist relative',
      );
      expect(worstLon, lessThanOrEqualTo(1e-11));
      expect(worstLat, lessThanOrEqualTo(1e-11));
      expect(worstDist, lessThanOrEqualTo(1e-11));
    });
  });

  group('the analytic rates: the integral identity, in TT', () {
    const intervalDays = 7.0;
    const panelDays = 0.25;
    const panels = 28;
    const dayInCenturies = 1 / 36525;

    /// The quadrature of our three rates over [t0, t0 + 7 days] (centuries
    /// TT) and the changes of upstream's lon, lat and dist over the same
    /// interval, as (quadrature, change) pairs.
    ({(double, double) lon, (double, double) lat, (double, double) dist})
    identity(double t0) {
      final hPanel = panelDays * dayInCenturies;
      final half = hPanel / 2;
      var qLon = 0.0, qLat = 0.0, qDist = 0.0;
      for (var p = 0; p < panels; p++) {
        final centre = t0 + (p + 0.5) * hPanel;
        for (var k = 0; k < _glNodes.length; k++) {
          final s = _series(centre + _glNodes[k] * half);
          final w = _glWeights[k] * half;
          qLon += w * s[_dLon];
          qLat += w * s[_dLat];
          qDist += w * s[_dDist];
        }
      }
      final a = _series(t0);
      final b = _series(t0 + intervalDays * dayInCenturies);
      return (
        lon: (qLon, _wrap(b[_upLon] - a[_upLon])),
        lat: (qLat, b[_upLat] - a[_upLat]),
        dist: (qDist, b[_upDist] - a[_upDist]),
      );
    }

    /// Instants (centuries TT) where our own series' distance is smallest or
    /// largest, found as sign changes of our analytic distance rate on a
    /// 0.25-day scan, refined by bisection, then thinned to [want] of them.
    List<double> extrema(int want) {
      final step = 0.25 * dayInCenturies;
      final found = <double>[];
      var previous = _series(-1.0)[_dDist];
      for (var t = -1.0 + step; t < 1.0 - 8 * dayInCenturies; t += step) {
        final current = _series(t)[_dDist];
        if ((previous < 0) != (current < 0)) {
          var lo = t - step, hi = t;
          for (var i = 0; i < 40; i++) {
            final mid = (lo + hi) / 2;
            if ((_series(mid)[_dDist] < 0) == (previous < 0)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          found.add((lo + hi) / 2);
        }
        previous = current;
      }
      final picked = <double>[];
      for (var i = 0; i < want; i++) {
        picked.add(found[(i * (found.length - 1) / (want - 1)).round()]);
      }
      return picked;
    }

    test(
      '400 composite 7-day intervals agree to 1e-9 degrees and 1e-12 AU',
      () {
        final starts = <double>[
          // 360 evenly spaced start times across the span.
          for (var k = 0; k < 360; k++)
            -1.0 + k * (2.0 - (intervalDays + 1) * dayInCenturies) / 359,
          // 40 intervals centred on perigees and apogees of our own series.
          for (final e in extrema(40)) e - 3.5 * dayInCenturies,
        ];
        expect(starts, hasLength(400));
        var worstLon = 0.0, worstLat = 0.0, worstDist = 0.0;
        for (final t0 in starts) {
          final r = identity(t0);
          worstLon = math.max(worstLon, (r.lon.$1 - r.lon.$2).abs() * _degrees);
          worstLat = math.max(worstLat, (r.lat.$1 - r.lat.$2).abs() * _degrees);
          worstDist = math.max(worstDist, (r.dist.$1 - r.dist.$2).abs());
        }
        // ignore: avoid_print
        print(
          'integral identity worst: lon $worstLon deg, lat $worstLat deg, '
          'dist $worstDist AU',
        );
        expect(worstLon, lessThanOrEqualTo(1e-9));
        expect(worstLat, lessThanOrEqualTo(1e-9));
        expect(worstDist, lessThanOrEqualTo(1e-12));
      },
    );
  });

  group('the Moon state in ECM and ECT', () {
    /// 10,000 instants, as days since J2000 UT, across 1900 to 2100.
    Iterable<double> instants() sync* {
      const count = 10000;
      for (var i = 0; i < count; i++) {
        yield -36524 + i * 73049 / (count - 1);
      }
    }

    test(
      'the ECT longitude equals Astronomy_EclipticGeoMoon within 1e-9 deg',
      () {
        var worst = 0.0;
        for (final days in instants()) {
          final utc = _utc(days);
          final state = _source.moonStateForTesting(daysSinceJ2000(utc));
          final ours = math.atan2(state[_ectR + 1], state[_ectR]) * _degrees;
          final upstream = _source.bodyState(Body.moon, utc).longitude;
          var d = (ours - upstream) % 360;
          if (d > 180) d -= 360;
          worst = math.max(worst, d.abs());
        }
        // ignore: avoid_print
        print('ECT consistency worst: $worst deg');
        expect(worst, lessThanOrEqualTo(1e-9));
      },
    );

    test('rotation invariants: |v|, r.v and |r x v| equal in ECM and ECT', () {
      var worstSpeed = 0.0, worstDot = 0.0, worstCross = 0.0;
      for (final days in instants()) {
        final s = _source.moonStateForTesting(daysSinceJ2000(_utc(days)));
        final speedEcm = _norm(s, _ecmV), speedEct = _norm(s, _ectV);
        worstSpeed = math.max(
          worstSpeed,
          (speedEcm - speedEct).abs() / speedEcm,
        );
        final scale = _norm(s, _ecmR) * speedEcm;
        worstDot = math.max(
          worstDot,
          (_dot(s, _ecmR, s, _ecmV) - _dot(s, _ectR, s, _ectV)).abs() / scale,
        );
        final crossEcm = _crossNorm(s, _ecmR, s, _ecmV);
        final crossEct = _crossNorm(s, _ectR, s, _ectV);
        worstCross = math.max(
          worstCross,
          (crossEcm - crossEct).abs() / crossEcm,
        );
      }
      // ignore: avoid_print
      print(
        'rotation invariants worst (relative): |v| $worstSpeed, '
        'r.v $worstDot, |r x v| $worstCross',
      );
      expect(worstSpeed, lessThanOrEqualTo(1e-12));
      expect(worstDot, lessThanOrEqualTo(1e-12));
      expect(worstCross, lessThanOrEqualTo(1e-12));
    });

    test('the longitude speed stays between 11.5 and 15.6 degrees per day', () {
      var slowest = double.infinity, fastest = 0.0;
      for (final days in instants()) {
        final state = _source.bodyState(Body.moon, _utc(days));
        final speed = eclipticLongitudeRateDegreesPerDay(
          x: state.x,
          y: state.y,
          vx: state.vx,
          vy: state.vy,
        );
        slowest = math.min(slowest, speed);
        fastest = math.max(fastest, speed);
      }
      // ignore: avoid_print
      print('Moon longitude speed range: $slowest to $fastest deg/day');
      expect(slowest, greaterThan(11.5));
      expect(fastest, lessThan(15.6));
    });

    test('bodyState(Body.moon) has no independent longitude', () {
      expect(
        _source
            .bodyState(Body.moon, DateTime.utc(2026, 11, 21))
            .independentLongitude,
        isNull,
      );
    });
  });
}
