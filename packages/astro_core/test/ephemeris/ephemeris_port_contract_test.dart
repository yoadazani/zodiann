import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// A minimal source that follows the documented `EphemerisPort` contract.
/// It proves the interface can be implemented, injected and consumed as
/// designed. Behavioural conformance of real adapters is ZOD-EPH-002/004.
final class _FakePort implements EphemerisPort {
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
    return EphemerisSuccess(
      EclipticPosition(
        longitude: 30.0 * body.index,
        speed: body == Body.mars ? -0.3 : 0.5,
      ),
    );
  }

  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      EclipticPosition(longitude: 125.0, speed: -0.0529539);
}

/// Exhaustive over [EphemerisResult] with no default branch: adding a result
/// kind without handling it here stops this file from compiling.
String describe(EphemerisResult result) => switch (result) {
  EphemerisSuccess(:final position) => 'ok ${position.longitude}',
  OutOfCoveredRange(:final requested) => 'out $requested',
};

void main() {
  group('EphemerisPort contract', () {
    final EphemerisPort port = _FakePort();
    final inRange = DateTime.utc(2026, 11, 12);
    final outOfRange = DateTime.utc(1900);

    test('can be implemented and injected as the interface type', () {
      expect(port.position(Body.sun, inRange), isA<EphemerisSuccess>());
    });

    test('exposes speed so retrograde is derivable', () {
      final mars = port.position(Body.mars, inRange) as EphemerisSuccess;

      expect(mars.position.speed < 0, isTrue);
    });

    test('reports out-of-range as a typed failure carrying the request and covered range', () {
      final result = port.position(Body.moon, outOfRange);

      expect(result, isA<OutOfCoveredRange>());
      final failure = result as OutOfCoveredRange;
      expect(failure.requested, outOfRange);
      expect(failure.covered, port.coveredRange);
    });

    test('results are consumable by an exhaustive switch', () {
      expect(describe(port.position(Body.sun, inRange)), startsWith('ok '));
      expect(describe(port.position(Body.sun, outOfRange)), startsWith('out '));
    });

    test('node goes through the declared mean-node method', () {
      final node = port.position(Body.node, outOfRange);

      expect(node, isA<EphemerisSuccess>());
      expect(
        (node as EphemerisSuccess).position,
        port.meanAscendingNode(outOfRange),
      );
    });
  });
}
