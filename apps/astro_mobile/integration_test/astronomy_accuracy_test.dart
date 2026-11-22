// ZOD-EPH-004 Task 5 (D12): ACC-2 on a device. The astronomy-engine adapter,
// running the real C library through FFI, against JPL Horizons for all ten
// physical bodies at every instant of packages/astro_core/test/fixtures/
// reference_dates.json, within one arcminute, **at equivalent TT instants**.
// Run on an Android device or emulator:
//   flutter test integration_test/astronomy_accuracy_test.dart -d <device>
//
// The adapter is always called with the reference UTC instant, through the
// production path. Horizons was asked at the TT that the adapter's own
// UTC-to-TT conversion assigns to that instant; a pin test checks that the
// device's own hook (zodiann_test_time_for_ut, the same single conversion
// helper) reports exactly those values, within 1 millisecond, so a change of
// the conversion fails the pin instead of silently re-aligning the reference.
//
// HONEST LIMIT: because the TT comes from the library's own delta T, the gate
// has that delta T on both sides. It validates the position model given TT; it
// cannot see an error in the library's delta T, and says nothing about which
// delta T is closer to the truth. The UTC-input difference against Horizons
// (asked at the same UTC instants as UT) is printed beside every body's TT
// result as information, with no threshold. See
// docs/spikes/ZOD-EPH-004-delta-t.md.
//
// The maximum error of every body is printed on its own line, so Moon and
// Pluto are never folded into one figure.
import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'astronomy_reference_longitudes.dart';
import 'astronomy_reference_longitudes_tt.dart';

/// The value every double of a hook's buffer holds before the shim runs.
const double _sentinel = 1234.5;

const _native = NativeBodyStateSource();

/// Smallest angle between two longitudes, in arcseconds.
double arcsecondsBetween(double a, double b) {
  var difference = (a - b).abs() % 360;
  if (difference > 180) difference = 360 - difference;
  return difference * 3600;
}

/// A source that counts the calls it forwards to the native source.
final class _CountingSource implements BodyStateSource {
  int calls = 0;

  @override
  BodyState bodyState(Body body, DateTime utc) {
    calls++;
    return _native.bodyState(body, utc);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final port = AstronomyEphemeris(source: _native);

  group('the comparison itself', () {
    test('rejects an error just above the tolerance', () {
      expect(
        arcsecondsBetween(10.0, 10.0 + 61 / 3600),
        greaterThan(astronomyTtToleranceArcseconds),
      );
    });

    test('accepts an error just below it, and wraps around 360', () {
      expect(
        arcsecondsBetween(10.0, 10.0 + 59 / 3600),
        lessThan(astronomyTtToleranceArcseconds),
      );
      expect(arcsecondsBetween(359.99, 0.01), closeTo(72, 1e-6));
    });
  });

  group('the UTC-to-TT conversion the fixture assumed (D12)', () {
    test(
      'the hook reports the fixture\'s UT, TT and delta T for every instant, '
      'each within 1 millisecond',
      () {
        // 1 millisecond in days.
        const millisecond = 1 / 86400000;
        final seen = <String>{};
        for (final reference in astronomyTtReferenceLongitudes) {
          if (!seen.add(reference.utc)) continue;
          // The hook is called with the instant, never with the fixture's days,
          // so it goes through the same conversion the adapter uses.
          final time = _native.timeForTesting(DateTime.parse(reference.utc));
          expect(
            time[0],
            closeTo(reference.utDays, 1e-9),
            reason: 'UT days at ${reference.utc}',
          );
          expect(
            time[1],
            closeTo(reference.ttDays, millisecond),
            reason: 'TT days at ${reference.utc}',
          );
          expect(
            (time[1] - time[0]) * 86400,
            closeTo(reference.deltaTSeconds, 0.001),
            reason: 'delta T at ${reference.utc}',
          );
        }
        expect(seen, hasLength(53));
      },
    );
  });

  test('ACC-2 gate: all ten bodies, 53 instants, within 60 arcseconds of '
      'Horizons at the equivalent TT instants', () {
    // What this comparison is: the adapter is called with each reference UTC
    // instant through the production path; Horizons was asked at the TT the
    // adapter's own conversion assigns to it (pinned above). It validates the
    // position model given TT. It cannot see an error in the library's delta T:
    // that is on both sides. The UTC-input difference is printed beside it.
    final worstTt = <String, ({double arcseconds, String utc})>{};
    for (final reference in astronomyTtReferenceLongitudes) {
      final utc = DateTime.parse(reference.utc);
      final result = port.position(Body.fromJson(reference.body), utc);
      expect(result, isA<EphemerisSuccess>(), reason: reference.body);
      final difference = arcsecondsBetween(
        (result as EphemerisSuccess).position.longitude,
        reference.longitudeDegrees,
      );
      final previous = worstTt[reference.body];
      if (previous == null || difference > previous.arcseconds) {
        worstTt[reference.body] = (arcseconds: difference, utc: reference.utc);
      }
    }
    // Informational, not asserted, no threshold: the same adapter calls against
    // Horizons asked at the same UTC instants as UT (its own delta T).
    final worstUt = <String, ({double arcseconds, String utc})>{};
    for (final reference in astronomyReferenceLongitudes) {
      final utc = DateTime.parse(reference.utc);
      final result = port.position(Body.fromJson(reference.body), utc);
      expect(result, isA<EphemerisSuccess>(), reason: reference.body);
      final difference = arcsecondsBetween(
        (result as EphemerisSuccess).position.longitude,
        reference.longitudeDegrees,
      );
      final previous = worstUt[reference.body];
      if (previous == null || difference > previous.arcseconds) {
        worstUt[reference.body] = (arcseconds: difference, utc: reference.utc);
      }
    }
    for (final entry in worstTt.entries) {
      final ut = worstUt[entry.key]!;
      // ignore: avoid_print
      print(
        'ACC-2 ${entry.key.padRight(8)} TT max '
        '${entry.value.arcseconds.toStringAsFixed(3)} arcsec at '
        '${entry.value.utc}; UTC-input (informational) max '
        '${ut.arcseconds.toStringAsFixed(3)} arcsec at ${ut.utc}',
      );
    }
    expect(worstTt.keys.toSet(), hasLength(10));
    for (final entry in worstTt.entries) {
      expect(
        entry.value.arcseconds,
        lessThanOrEqualTo(astronomyTtToleranceArcseconds),
        reason: '${entry.key} at ${entry.value.utc}',
      );
    }
  });

  group('frame checks at the reference instants', () {
    final instants = {
      for (final r in astronomyReferenceLongitudes) DateTime.parse(r.utc),
    }.toList();

    test('Sun: the shim longitude agrees with Astronomy_SunPosition '
        'within 1 arcsecond', () {
      var worst = 0.0;
      for (final utc in instants) {
        final state = _native.bodyState(Body.sun, utc);
        expect(state.independentLongitude, isNotNull);
        worst = math.max(
          worst,
          arcsecondsBetween(state.longitude, state.independentLongitude!),
        );
      }
      // ignore: avoid_print
      print(
        'Sun frame check (SunPosition vs rotated GeoVector) worst: $worst arcsec',
      );
      expect(worst, lessThanOrEqualTo(1.0));
    });

    test(
      'Moon: the longitude and atan2 of the Moon position agree within '
      '1e-9 degrees (a regression check, not an independent frame check)',
      () {
        var worst = 0.0;
        for (final utc in instants) {
          final state = _native.bodyState(Body.moon, utc);
          final fromVector = math.atan2(state.y, state.x) * 180 / math.pi;
          worst = math.max(
            worst,
            arcsecondsBetween(state.longitude, fromVector) / 3600,
          );
        }
        // ignore: avoid_print
        print('Moon position/longitude consistency worst: $worst deg');
        expect(worst, lessThanOrEqualTo(1e-9));
      },
    );
  });

  group('the production call path and its buffer', () {
    final utc = DateTime.utc(2026, 11, 21, 6);

    test('every body: status 0, out[0..7] written, the guard untouched', () {
      for (final body in shimBodyIds.keys) {
        final result = _native.rawBufferForTesting(body, utc, guardDoubles: 4);
        expect(result.status, 0, reason: '$body');
        expect(result.buffer, hasLength(bodyStateLength + 4), reason: '$body');
        for (var i = 0; i < bodyStateLength; i++) {
          expect(
            result.buffer[i],
            isNot(_sentinel),
            reason: '$body element $i was not written',
          );
        }
        // out[7]: finite for the Sun only, NaN for every other body.
        expect(
          result.buffer[7].isNaN,
          body != Body.sun,
          reason: '$body out[7] is ${result.buffer[7]}',
        );
        for (var i = bodyStateLength; i < result.buffer.length; i++) {
          // A guard of four doubles detects only an overrun of four or fewer.
          expect(
            result.buffer[i],
            _sentinel,
            reason: '$body guard element $i was overwritten',
          );
        }
      }
    });

    test('an invalid shim id returns non-zero and writes nothing', () {
      for (final id in [-1, 10]) {
        final result = _native.rawBufferForTesting(
          Body.sun,
          utc,
          guardDoubles: 4,
          shimIdOverride: id,
        );
        expect(result.status, isNot(0), reason: 'id $id');
        expect(
          result.buffer.every((v) => v == _sentinel),
          isTrue,
          reason: 'id $id wrote into the buffer: ${result.buffer}',
        );
      }
    });

    test('a non-UTC DateTime and Body.node throw ArgumentError', () {
      expect(
        () => _native.bodyState(Body.sun, DateTime(2000)),
        throwsArgumentError,
      );
      expect(() => _native.bodyState(Body.node, utc), throwsArgumentError);
    });
  });

  test(
    'out of range: OutOfCoveredRange and the native source is not called',
    () {
      final counting = _CountingSource();
      final guarded = AstronomyEphemeris(source: counting);
      final result = guarded.position(Body.sun, DateTime.utc(1899, 12, 30));
      expect(result, isA<OutOfCoveredRange>());
      expect(counting.calls, 0);
    },
  );
}
