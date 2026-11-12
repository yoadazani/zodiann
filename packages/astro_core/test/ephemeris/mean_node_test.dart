import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

const tolerance = 1e-9;
final epoch = DateTime.utc(2000, 1, 1, 12);

/// An adapter that reuses the shared formula via the mixin, ordering its
/// `position` branches as the contract requires: node first (formula-based,
/// not bounded by coveredRange), then the covered-range check.
final class _Adapter with MeanAscendingNodeFormula implements EphemerisPort {
  @override
  final UtcRange coveredRange = UtcRange(
    DateTime.utc(2000),
    DateTime.utc(2100),
  );

  @override
  EphemerisResult position(Body body, DateTime utc) {
    if (body == Body.node) return EphemerisSuccess(meanAscendingNode(utc));
    if (!coveredRange.contains(utc)) {
      return OutOfCoveredRange(requested: utc, covered: coveredRange);
    }
    return EphemerisSuccess(EclipticPosition(longitude: 10, speed: 1));
  }
}

void main() {
  group('meanAscendingNodeAt', () {
    test('is exactly 125.04452 at the reference epoch', () {
      expect(meanAscendingNodeAt(epoch).longitude, 125.04452);
    });

    test('matches hand-computed values before and after the epoch', () {
      expect(
        meanAscendingNodeAt(DateTime.utc(1900)).longitude,
        closeTo(259.15430411757734, tolerance),
      );
      expect(
        meanAscendingNodeAt(DateTime.utc(2100)).longitude,
        closeTo(350.93473588242273, tolerance),
      );
      expect(
        meanAscendingNodeAt(DateTime.utc(2026, 11, 12)).longitude,
        closeTo(325.48865621351126, tolerance),
      );
    });

    test('normalizes negative raw values into [0, 360)', () {
      // Raw Ω is −394.51 (2026-11-12) and −1809.07 (2100-01-01).
      for (final t in [DateTime.utc(2026, 11, 12), DateTime.utc(2100)]) {
        final longitude = meanAscendingNodeAt(t).longitude;
        expect(longitude, greaterThanOrEqualTo(0));
        expect(longitude, lessThan(360));
      }
    });

    test('has the constant negative speed −1934.136261 / 36525 °/day on every date', () {
      for (final t in [DateTime.utc(1800), epoch, DateTime.utc(2400)]) {
        expect(meanAscendingNodeAt(t).speed, -1934.136261 / 36525);
      }
    });

    test('uses the spec coefficients', () {
      expect(meanNodeEpochLongitude, 125.04452);
      expect(meanNodeDegreesPerCentury, 1934.136261);
      expect(meanNodeSpeedDegreesPerDay, -1934.136261 / 36525);
      expect(
        meanAscendingNodeAt(epoch.add(const Duration(days: 1))).longitude,
        closeTo(normalizeDegrees(125.04452 - 1934.136261 / 36525), tolerance),
      );
    });

    test('is never reported as direct', () {
      expect(Body.node.hasConstantMeanRetrograde, isTrue);
      for (var year = 1800; year <= 2400; year++) {
        expect(
          meanAscendingNodeAt(DateTime.utc(year)).speed,
          lessThan(0),
          reason: '$year',
        );
      }
    });

    test('rejects non-UTC input', () {
      expect(
        () => meanAscendingNodeAt(DateTime(2026, 11, 12)),
        throwsArgumentError,
      );
    });
  });

  group('MeanAscendingNodeFormula', () {
    test('an adapter mixing it in returns the shared formula', () {
      final adapter = _Adapter();
      final t = DateTime.utc(2026, 11, 12, 6);

      expect(adapter.meanAscendingNode(t), meanAscendingNodeAt(t));
    });

    test(
      'node bypasses coveredRange because the formula is source-independent',
      () {
        final EphemerisPort adapter = _Adapter();
        final outside = DateTime.utc(1900);

        final node = adapter.position(Body.node, outside);
        expect(node, isA<EphemerisSuccess>());
        expect(
          (node as EphemerisSuccess).position,
          meanAscendingNodeAt(outside),
        );
        expect(adapter.position(Body.moon, outside), isA<OutOfCoveredRange>());
      },
    );
  });
}
