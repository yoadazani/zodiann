// ZOD-EPH-004 Task 6: the longitude speed of the astronomy-engine adapter
// (analytic, from the library's own state vectors; the Moon's from our own
// analytic derivative of the lunar series) against Swiss Ephemeris, for the ten
// bodies, with the stations of the eight planets. Run on an Android device or
// emulator:
//   flutter test integration_test/astronomy_speed_vs_swiss_test.dart -d <device>
//
// Time scale (owner decision D12-O1, 2026-11-22): every comparison is at the
// exact same TT. The adapter is called with the UTC instant, as in production;
// the TT it uses is read through `NativeBodyStateSource.timeForTesting` (the
// shim's single conversion helper) and Swiss Ephemeris is asked at that TT
// through `swe_calc`, so neither engine's delta T enters the speed difference.
// Swiss is evaluated without gravitational deflection (see _swissSpeedFlags).
// Each engine keeps its own, independent speed calculation. Nothing here
// differences positions: the stations are found by looking for a sign change
// of a speed, which is a search, not a derivative.
//
// Thresholds are the owner-approved values of decision D7; the Moon's 0.0007
// was confirmed by the owner on 2026-11-22 (see its constant).
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy_native.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'astronomy_reference_longitudes_tt.dart';

/// D7 (a): the largest allowed `|astronomy speed - Swiss speed|`, degrees per
/// day, owner-approved 2026-11-21.
const Map<Body, double> speedBoundDegPerDay = {
  Body.sun: 0.0003,
  Body.mercury: 0.0012,
  Body.venus: 0.00045,
  Body.mars: 0.0003,
  Body.jupiter: 0.0003,
  Body.saturn: 0.0003,
  Body.uranus: 0.0003,
  Body.neptune: 0.0003,
  Body.pluto: 0.0003,
};

/// The Moon's bound, degrees per day. FROZEN on 2026-11-22 on the owner's
/// confirmation of the proposal "0.0007" ("Moon bound 0.0007 confirmed"). It is
/// the diagnostic maximum 0.000573 (2025-04-24T00:00Z, dense six-hourly set
/// 2025-01-01 to 2027-01-01 plus the 53 reference instants; the maximum over
/// the 53 alone is 0.000251) plus 0.000127, about 22%, roughly one residual rms
/// of the signed difference, as headroom for epochs outside the sampled years.
/// Epochs beyond those two years and the 53 reference dates are not claimed.
/// Do not change it without the owner.
const double moonSpeedBoundDegPerDay = 0.0007;

/// D7 (c): the largest allowed offset of a station, in days.
const double stationOffsetBoundDays = 1.0;

/// The Swiss flags of every speed sample (owner approval 2026-11-22): the
/// Swiss Ephemeris data files, with speed, and **without gravitational
/// deflection**. Swiss's deflection speed correction glitches near solar
/// conjunction (Uranus at 2075-01-01 and 1946-06-09, 82 Uranus days over the
/// bound in a daily scan), the dip being in code the data-file and Moshier
/// modes share; Astronomy Engine applies no deflection, so this is the
/// like-for-like reference. See docs/spikes/ZOD-EPH-004-swiss-speed-reference.md.
/// Replaces the `SEFLG_SWIEPH | SEFLG_SPEED` that decision D7 named; no
/// threshold, formula or sample changes with it.
const int _swissSpeedFlags = seflgSwieph | seflgSpeed | seflgNogdefl;

/// The Swiss body ids (swephexp.h, decision D9).
const Map<Body, int> _swissIds = {
  Body.sun: 0,
  Body.moon: 1,
  Body.mercury: 2,
  Body.venus: 3,
  Body.mars: 4,
  Body.jupiter: 5,
  Body.saturn: 6,
  Body.uranus: 7,
  Body.neptune: 8,
  Body.pluto: 9,
};

const _planets = [
  Body.mercury,
  Body.venus,
  Body.mars,
  Body.jupiter,
  Body.saturn,
  Body.uranus,
  Body.neptune,
  Body.pluto,
];

const _assetDirectory = 'packages/ephemeris_swiss/assets/ephe';
const _dataFiles = ['sepl_18.se1', 'semo_18.se1'];

const _native = NativeBodyStateSource();

/// Smallest angle between two longitudes, in arcseconds.
double arcsecondsBetween(double a, double b) {
  var difference = (a - b).abs() % 360;
  if (difference > 180) difference = 360 - difference;
  return difference * 3600;
}

/// Everything measured for one body.
final class _Stat {
  _Stat(this.body);

  final Body body;
  int samples = 0;
  int outOfRange = 0;
  double maxAbs = 0;
  DateTime? maxAt;
  double sumAbs = 0;
  int signChecked = 0;
  int signExempt = 0;
  final List<String> signMismatches = [];
  int stations = 0;
  int stationsSkipped = 0;
  int stationsNoCrossing = 0;
  double maxOffsetMinutes = 0;
  double sumOffsetMinutes = 0;
  DateTime? maxOffsetAt;
  // The Moon's dense set and the 53 reference dates are reported separately.
  double maxAbsReference = 0;
  double maxAbsDense = 0;
  DateTime? maxDenseAt;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dataDirectory;
  final swiss = SwissEphemerisBinding();
  final port = AstronomyEphemeris(source: _native);

  setUpAll(() async {
    final support = await getApplicationSupportDirectory();
    dataDirectory = Directory('${support.path}/ephe')
      ..createSync(recursive: true);
    for (final name in _dataFiles) {
      final bundled = await rootBundle.load('$_assetDirectory/$name');
      final bytes = bundled.buffer.asUint8List(
        bundled.offsetInBytes,
        bundled.lengthInBytes,
      );
      final target = File('${dataDirectory.path}/$name');
      await target.writeAsBytes(bytes, flush: true);
      expect(target.lengthSync(), bytes.length, reason: '$name copied whole');
    }
  });

  /// TT days since J2000 that the adapter's production path assigns to [utc].
  double ttDaysOf(DateTime utc) => _native.timeForTesting(utc)[1];

  /// Swiss speed of [body] at the TT the adapter assigns to [utc]. Every
  /// sample must come from the data files, otherwise the reference would be
  /// the Moshier ephemeris.
  double swissSpeed(Body body, DateTime utc) {
    final result = swiss.calcTt(
      julianDayTt(ttDaysOf(utc)),
      _swissIds[body]!,
      flags: _swissSpeedFlags,
    );
    if (!result.usedSwissEphemerisFiles) {
      throw StateError(
        'Swiss Ephemeris did not use its data files for $body at $utc: '
        'flags ${result.returnFlags}, error "${result.error}"',
      );
    }
    return result.speed;
  }

  /// The adapter's speed, or null outside the covered range.
  double? astronomySpeed(Body body, DateTime utc) {
    final result = port.position(body, utc);
    return result is EphemerisSuccess ? result.position.speed : null;
  }

  group('the Swiss TT entry point (D12-O1)', () {
    test('calcTt is TT: it agrees with calcUt given Swiss ΔT and differs '
        'from it by the ΔT when handed the UT', () {
      swiss.setEphePath(dataDirectory.path);
      final utc = DateTime.utc(2000);
      final viaUt = swiss.calcUt(utc, seMoon);
      final jdUt = julianDayUt(utc);
      expect(viaUt.usedSwissEphemerisFiles, isTrue);
      // Swiss's own ΔT at 2000-01-01 is 63.83 s (docs/spikes/
      // ZOD-EPH-004-delta-t.md): 1 s is 0.55 arcsecond for the Moon.
      final viaTt = swiss.calcTt(jdUt + 63.83 / 86400, seMoon);
      expect(viaTt.usedSwissEphemerisFiles, isTrue);
      expect(
        arcsecondsBetween(viaTt.longitude, viaUt.longitude),
        lessThan(0.5),
      );
      // Handed the UT instead of the TT, the Moon would be 35 arcseconds off.
      final wrong = swiss.calcTt(jdUt, seMoon);
      expect(
        arcsecondsBetween(wrong.longitude, viaUt.longitude),
        greaterThan(25),
      );
    });

    test('the hook TT and the Swiss TT call are the same instant for the '
        'adapter\'s own conversion', () {
      swiss.setEphePath(dataDirectory.path);
      final utc = DateTime.utc(2026, 11, 22, 6);
      final time = _native.timeForTesting(utc);
      expect(time[0], daysSinceJ2000(utc));
      expect(julianDayTt(time[1]), time[1] + 2451545.0);
      final a = swiss.calcTt(julianDayTt(time[1]), seSun);
      final b = swiss.calcTt(time[1] + 2451545.0, seSun);
      expect(a.longitude, b.longitude);
    });
  });

  test('speed against Swiss Ephemeris at the same TT: ten bodies, stations '
      'included', () {
    final watch = Stopwatch()..start();
    swiss.setEphePath(dataDirectory.path);
    final stats = {for (final b in _swissIds.keys) b: _Stat(b)};

    /// One sample: the adapter's speed against Swiss's at the same TT.
    void sample(
      Body body,
      DateTime utc, {
      bool reference = false,
      bool dense = false,
    }) {
      final stat = stats[body]!;
      final astro = astronomySpeed(body, utc);
      if (astro == null) {
        stat.outOfRange++;
        return;
      }
      final swissValue = swissSpeed(body, utc);
      final difference = (astro - swissValue).abs();
      stat.samples++;
      stat.sumAbs += difference;
      if (difference > stat.maxAbs) {
        stat.maxAbs = difference;
        stat.maxAt = utc;
      }
      if (reference && difference > stat.maxAbsReference) {
        stat.maxAbsReference = difference;
      }
      if (dense && difference > stat.maxAbsDense) {
        stat.maxAbsDense = difference;
        stat.maxDenseAt = utc;
      }
      final bound = body == Body.moon
          ? moonSpeedBoundDegPerDay
          : speedBoundDegPerDay[body];
      if (bound == null) return; // diagnostic mode: the Moon's (a) and (b)
      if (swissValue.abs() > bound) {
        stat.signChecked++;
        if (astro.isNegative != swissValue.isNegative) {
          stat.signMismatches.add(
            '${utc.toIso8601String()} astronomy $astro Swiss $swissValue',
          );
        }
      } else {
        stat.signExempt++;
      }
    }

    // The 53 reference instants, every body.
    final referenceInstants = {
      for (final r in astronomyTtReferenceLongitudes) DateTime.parse(r.utc),
    }.toList()..sort();
    for (final body in _swissIds.keys) {
      for (final utc in referenceInstants) {
        sample(body, utc, reference: true);
      }
    }

    // The Sun: 20 more instants spread over 2026.
    for (var k = 0; k < 20; k++) {
      sample(Body.sun, DateTime.utc(2026).add(Duration(hours: k * 438)));
    }

    // The Moon: every 6 hours from 2025-01-01 to 2027-01-01 (2,921 instants).
    final moonStart = DateTime.utc(2025);
    final moonEnd = DateTime.utc(2027);
    var moonInstants = 0;
    for (
      var t = moonStart;
      !t.isAfter(moonEnd);
      t = t.add(const Duration(hours: 6))
    ) {
      sample(Body.moon, t, dense: true);
      moonInstants++;
    }
    expect(moonInstants, 2921);

    // Stations: scan Swiss's speed daily over 1900-01-01 to 2099-12-31 (UTC
    // days; Swiss is asked at the adapter's TT for each), keep every sign
    // change, bisect it to a minute.
    final scanStart = DateTime.utc(1900);
    final scanEnd = DateTime.utc(2099, 12, 31);
    final brackets = <Body, List<(DateTime, DateTime)>>{
      for (final p in _planets) p: [],
    };
    final previousNegative = <Body, bool>{};
    DateTime? previousDay;
    for (
      var day = scanStart;
      !day.isAfter(scanEnd);
      day = day.add(const Duration(days: 1))
    ) {
      final jd = julianDayTt(ttDaysOf(day));
      for (final p in _planets) {
        final result = swiss.calcTt(jd, _swissIds[p]!, flags: _swissSpeedFlags);
        if (!result.usedSwissEphemerisFiles) {
          throw StateError('Swiss files not used for $p at $day');
        }
        final negative = result.speed.isNegative;
        final before = previousNegative[p];
        if (before != null && before != negative) {
          brackets[p]!.add((previousDay!, day));
        }
        previousNegative[p] = negative;
      }
      previousDay = day;
    }
    // ignore: avoid_print
    print(
      'stations found by the daily Swiss scan: '
      '${{for (final p in _planets) p.name: brackets[p]!.length}} '
      '(${watch.elapsed.inSeconds} s so far)',
    );

    /// The instant in [lo, hi] where [speed] changes sign, to about a minute
    /// (12 halvings of at most four days). A search for a sign change, not a
    /// derivative.
    DateTime bisect(DateTime lo, DateTime hi, double Function(DateTime) f) {
      var a = lo.microsecondsSinceEpoch;
      var b = hi.microsecondsSinceEpoch;
      final negativeAtLo = f(lo).isNegative;
      for (var i = 0; i < 12; i++) {
        final mid = (a + b) ~/ 2;
        final negativeAtMid = f(
          DateTime.fromMicrosecondsSinceEpoch(mid, isUtc: true),
        ).isNegative;
        if (negativeAtMid == negativeAtLo) {
          a = mid;
        } else {
          b = mid;
        }
      }
      return DateTime.fromMicrosecondsSinceEpoch((a + b) ~/ 2, isUtc: true);
    }

    const offsets = [0, 1, -1, 5, -5, 20, -20];
    for (final planet in _planets) {
      final stat = stats[planet]!;
      for (final (lo, hi) in brackets[planet]!) {
        final swissStation = bisect(lo, hi, (t) => swissSpeed(planet, t));
        // The adapter's own crossing, searched within two days of Swiss's.
        final searchLo = swissStation.subtract(const Duration(days: 2));
        final searchHi = swissStation.add(const Duration(days: 2));
        final loSpeed = astronomySpeed(planet, searchLo);
        final hiSpeed = astronomySpeed(planet, searchHi);
        if (loSpeed == null || hiSpeed == null) {
          stat.stationsSkipped++;
        } else if (loSpeed.isNegative == hiSpeed.isNegative) {
          stat.stations++;
          stat.stationsNoCrossing++;
          stat.maxOffsetMinutes = double.infinity;
          stat.maxOffsetAt = swissStation;
        } else {
          final astroStation = bisect(
            searchLo,
            searchHi,
            (t) => astronomySpeed(planet, t)!,
          );
          final minutes =
              astroStation.difference(swissStation).inSeconds.abs() / 60;
          stat.stations++;
          stat.sumOffsetMinutes += minutes;
          if (minutes > stat.maxOffsetMinutes) {
            stat.maxOffsetMinutes = minutes;
            stat.maxOffsetAt = swissStation;
          }
        }
        for (final days in offsets) {
          sample(planet, swissStation.add(Duration(days: days)));
        }
      }
    }

    // The report.
    final lines = <String>[
      'SPEED vs SWISS (same TT, D12-O1): ${watch.elapsed.inSeconds} s, '
          'Moon bound $moonSpeedBoundDegPerDay',
      '| Body | Samples | Out of range | Bound (deg/day) | Max abs diff '
          '(deg/day) | At | Mean abs diff | Sign checked | Sign exempt | '
          'Sign mismatches | Stations | No crossing | Max station offset '
          '(min) | Mean offset (min) |',
      '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|',
    ];
    for (final body in _swissIds.keys) {
      final s = stats[body]!;
      final bound = body == Body.moon
          ? moonSpeedBoundDegPerDay
          : speedBoundDegPerDay[body];
      lines.add(
        '| ${body.name} | ${s.samples} | ${s.outOfRange} | '
        '${bound ?? "n/a"} | ${s.maxAbs.toStringAsFixed(6)} | '
        '${s.maxAt?.toIso8601String()} | '
        '${(s.samples == 0 ? 0 : s.sumAbs / s.samples).toStringAsFixed(6)} | '
        '${s.signChecked} | ${s.signExempt} | ${s.signMismatches.length} | '
        '${s.stations} | ${s.stationsNoCrossing} | '
        '${body == Body.moon || s.stations == 0 ? "n/a" : s.maxOffsetMinutes.toStringAsFixed(1)} | '
        '${body == Body.moon || s.stations == 0 ? "n/a" : (s.sumOffsetMinutes / s.stations).toStringAsFixed(1)} |',
      );
    }
    final moon = stats[Body.moon]!;
    lines
      ..add(
        'Moon: max over the 53 reference instants '
        '${moon.maxAbsReference.toStringAsFixed(6)} deg/day; max over the '
        '2,921 dense instants ${moon.maxAbsDense.toStringAsFixed(6)} '
        'deg/day at ${moon.maxDenseAt?.toIso8601String()}',
      )
      ..add(
        'Stations skipped (search window outside the covered range): '
        '${{for (final p in _planets) p.name: stats[p]!.stationsSkipped}}',
      );
    for (final body in _swissIds.keys) {
      for (final m in stats[body]!.signMismatches.take(10)) {
        lines.add('SIGN MISMATCH ${body.name} $m');
      }
    }
    for (final line in lines) {
      // ignore: avoid_print
      print(line);
    }

    // Assertions: D7 (a), (b), (c). The Moon's (a) and (b) only when its
    // bound is set; the Moon has no stations.
    final failures = <String>[];
    for (final body in _swissIds.keys) {
      final s = stats[body]!;
      final bound = body == Body.moon
          ? moonSpeedBoundDegPerDay
          : speedBoundDegPerDay[body];
      if (bound != null && s.maxAbs > bound) {
        failures.add(
          '(a) ${body.name}: max |Δ speed| ${s.maxAbs} > $bound at ${s.maxAt}',
        );
      }
      if (s.signMismatches.isNotEmpty) {
        failures.add(
          '(b) ${body.name}: ${s.signMismatches.length} sign mismatches, '
          'first ${s.signMismatches.first}',
        );
      }
      if (body != Body.moon &&
          s.maxOffsetMinutes > stationOffsetBoundDays * 1440) {
        failures.add(
          '(c) ${body.name}: station offset ${s.maxOffsetMinutes} min > '
          '${stationOffsetBoundDays * 1440} at ${s.maxOffsetAt}',
        );
      }
      if (body != Body.moon && body != Body.sun && s.stations == 0) {
        failures.add('${body.name}: no station found');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 40)));
}
