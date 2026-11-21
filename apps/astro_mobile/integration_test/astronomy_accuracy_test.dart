// ZOD-EPH-004 Task 5: ACC-2 on a device. The astronomy-engine adapter, running
// the real C library through FFI, against JPL Horizons for all ten physical
// bodies at every instant of packages/astro_core/test/fixtures/
// reference_dates.json, within one arcminute. Run on an Android device or
// emulator:
//   flutter test integration_test/astronomy_accuracy_test.dart -d <device>
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
        greaterThan(astronomyToleranceArcseconds),
      );
    });

    test('accepts an error just below it, and wraps around 360', () {
      expect(
        arcsecondsBetween(10.0, 10.0 + 59 / 3600),
        lessThan(astronomyToleranceArcseconds),
      );
      expect(arcsecondsBetween(359.99, 0.01), closeTo(72, 1e-6));
    });
  });

  test('ACC-2: all ten bodies, 53 instants, within 60 arcseconds of Horizons', () {
    final worst = <String, ({double arcseconds, String utc})>{};
    for (final reference in astronomyReferenceLongitudes) {
      final utc = DateTime.parse(reference.utc);
      final result = port.position(Body.fromJson(reference.body), utc);
      expect(result, isA<EphemerisSuccess>(), reason: reference.body);
      final position = (result as EphemerisSuccess).position;
      final difference = arcsecondsBetween(
        position.longitude,
        reference.longitudeDegrees,
      );
      final previous = worst[reference.body];
      if (previous == null || difference > previous.arcseconds) {
        worst[reference.body] = (arcseconds: difference, utc: reference.utc);
      }
    }
    for (final entry in worst.entries) {
      // ignore: avoid_print
      print(
        'ACC-2 ${entry.key.padRight(8)} max ${entry.value.arcseconds.toStringAsFixed(3)}'
        ' arcsec at ${entry.value.utc}',
      );
    }
    expect(worst.keys.toSet(), hasLength(10));
    for (final entry in worst.entries) {
      expect(
        entry.value.arcseconds,
        lessThanOrEqualTo(astronomyToleranceArcseconds),
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
