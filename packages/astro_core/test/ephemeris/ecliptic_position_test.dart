import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('EclipticPosition', () {
    test('accepts the range boundaries 0 and just below 360', () {
      final zero = EclipticPosition(longitude: 0.0, speed: 1.0);
      final top = EclipticPosition(longitude: 359.99999999, speed: 0.98);

      expect(zero.longitude, 0.0);
      expect(zero.speed, 1.0);
      expect(top.longitude, 359.99999999);
      expect(top.speed, 0.98);
    });

    test('rejects 360 and above', () {
      expect(
        () => EclipticPosition(longitude: 360.0, speed: 1),
        throwsArgumentError,
      );
      expect(
        () => EclipticPosition(longitude: 360.5, speed: 1),
        throwsArgumentError,
      );
    });

    test('rejects negative longitudes', () {
      expect(
        () => EclipticPosition(longitude: -0.0001, speed: 1),
        throwsArgumentError,
      );
    });

    test('stores -0.0 as 0.0', () {
      expect(
        EclipticPosition(longitude: -0.0, speed: 1).longitude.isNegative,
        isFalse,
      );
    });

    test('rejects non-finite longitude', () {
      expect(
        () => EclipticPosition(longitude: double.nan, speed: 1),
        throwsArgumentError,
      );
      expect(
        () => EclipticPosition(longitude: double.infinity, speed: 1),
        throwsArgumentError,
      );
    });

    test(
      'accepts negative speed (retrograde) and rejects non-finite speed',
      () {
        expect(EclipticPosition(longitude: 10, speed: -0.5).speed, -0.5);
        expect(
          () => EclipticPosition(longitude: 10, speed: double.nan),
          throwsArgumentError,
        );
        expect(
          () => EclipticPosition(longitude: 10, speed: double.negativeInfinity),
          throwsArgumentError,
        );
      },
    );

    test('has value equality', () {
      final a = EclipticPosition(longitude: 12.5, speed: -0.25);
      final b = EclipticPosition(longitude: 12.5, speed: -0.25);
      final c = EclipticPosition(longitude: 12.5, speed: 0.25);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
