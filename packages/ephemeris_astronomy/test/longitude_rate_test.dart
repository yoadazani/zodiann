import 'dart:math' as math;

import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:test/test.dart';

/// One degree per day expressed as radians per day.
const double _degreePerDay = math.pi / 180;

void main() {
  group('eclipticLongitudeRateDegreesPerDay', () {
    test('a unit circle at one degree per day gives exactly 1', () {
      expect(
        eclipticLongitudeRateDegreesPerDay(
          x: 1,
          y: 0,
          vx: 0,
          vy: _degreePerDay,
        ),
        closeTo(1.0, 1e-12),
      );
    });

    test('rotation about the origin from the y axis gives 1', () {
      // At (0, 2) the tangent speed for one degree per day is 2 * pi/180,
      // pointing towards negative x.
      expect(
        eclipticLongitudeRateDegreesPerDay(
          x: 0,
          y: 2,
          vx: -2 * _degreePerDay,
          vy: 0,
        ),
        closeTo(1.0, 1e-12),
      );
    });

    test('a negative tangential velocity gives a negative rate', () {
      expect(
        eclipticLongitudeRateDegreesPerDay(
          x: 1,
          y: 0,
          vx: 0,
          vy: -_degreePerDay,
        ),
        closeTo(-1.0, 1e-12),
      );
    });

    test('scaling position and velocity together keeps the rate', () {
      expect(
        eclipticLongitudeRateDegreesPerDay(
          x: 7,
          y: 0,
          vx: 0,
          vy: 7 * _degreePerDay,
        ),
        closeTo(1.0, 1e-12),
      );
    });

    test('purely radial motion gives zero', () {
      expect(eclipticLongitudeRateDegreesPerDay(x: 2, y: 1, vx: 4, vy: 2), 0.0);
    });

    test('a general case equals the rate of atan2(y, x)', () {
      // (x*vy - y*vx) / (x^2 + y^2) = (3*2 - 4*(-1)) / 25 = 0.4 rad/day.
      expect(
        eclipticLongitudeRateDegreesPerDay(x: 3, y: 4, vx: -1, vy: 2),
        closeTo(0.4 * 180 / math.pi, 1e-12),
      );
    });

    test('x = y = 0 throws ArgumentError', () {
      expect(
        () => eclipticLongitudeRateDegreesPerDay(x: 0, y: 0, vx: 1, vy: 1),
        throwsArgumentError,
      );
    });

    test('a non-finite input throws ArgumentError', () {
      for (final bad in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => eclipticLongitudeRateDegreesPerDay(x: bad, y: 1, vx: 0, vy: 1),
          throwsArgumentError,
          reason: 'x = $bad',
        );
        expect(
          () => eclipticLongitudeRateDegreesPerDay(x: 1, y: bad, vx: 0, vy: 1),
          throwsArgumentError,
          reason: 'y = $bad',
        );
        expect(
          () => eclipticLongitudeRateDegreesPerDay(x: 1, y: 1, vx: bad, vy: 1),
          throwsArgumentError,
          reason: 'vx = $bad',
        );
        expect(
          () => eclipticLongitudeRateDegreesPerDay(x: 1, y: 1, vx: 0, vy: bad),
          throwsArgumentError,
          reason: 'vy = $bad',
        );
      }
    });
  });
}
