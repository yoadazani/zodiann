import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeDegrees', () {
    test('maps -1e-15 to 0.0 (the x % 360 == 360.0 edge)', () {
      expect((-1e-15) % 360, 360.0, reason: 'precondition: the Dart edge');
      final result = normalizeDegrees(-1e-15);

      expect(result, 0.0);
      expect(result.isNegative, isFalse);
    });

    test('normalizes negatives', () {
      expect(normalizeDegrees(-10), 350.0);
      expect(normalizeDegrees(-370), 350.0);
      expect(
        normalizeDegrees(-394.51134378648874),
        closeTo(325.48865621351126, 1e-9),
      );
    });

    test('normalizes values at or above 360', () {
      expect(normalizeDegrees(360), 0.0);
      expect(normalizeDegrees(725), 5.0);
      expect(
        normalizeDegrees(2059.1543041175773),
        closeTo(259.15430411757734, 1e-9),
      );
    });

    test('keeps values already in range', () {
      expect(normalizeDegrees(0), 0.0);
      expect(normalizeDegrees(359.5), 359.5);
      expect(normalizeDegrees(-0.0).isNegative, isFalse);
    });

    test('rejects non-finite input', () {
      expect(() => normalizeDegrees(double.nan), throwsArgumentError);
      expect(() => normalizeDegrees(double.infinity), throwsArgumentError);
      expect(
        () => normalizeDegrees(double.negativeInfinity),
        throwsArgumentError,
      );
    });
  });
}
