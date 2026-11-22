import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:test/test.dart';

void main() {
  group('bodyStateLength', () {
    test('is 8: the shim writes out[0] through out[7]', () {
      expect(bodyStateLength, 8);
    });
  });

  group('the Moon test-hook lengths', () {
    test('moonSeriesLength is 9: lon, lat, dist, three rates, upstream x3', () {
      expect(moonSeriesLength, 9);
    });

    test('moonStateLength is 12: ECM r, ECM v, ECT r, ECT v', () {
      expect(moonStateLength, 12);
    });
  });

  group('the time test-hook length (ZOD-EPH-004 D12)', () {
    test('timeStateLength is 2: the UT days, then the TT days', () {
      expect(timeStateLength, 2);
    });
  });

  group('BodyState.fromBuffer', () {
    // out[0] longitude, out[1..3] r, out[4..6] v, out[7] independent longitude.
    test('maps an eight-element buffer in the shim layout', () {
      final state = BodyState.fromBuffer([10.5, 1, 2, 3, 4, 5, 6, 10.25]);
      expect(state.longitude, 10.5);
      expect((state.x, state.y, state.z), (1.0, 2.0, 3.0));
      expect((state.vx, state.vy, state.vz), (4.0, 5.0, 6.0));
      expect(state.independentLongitude, 10.25);
    });

    test('maps a NaN out[7] to a null independentLongitude', () {
      final state = BodyState.fromBuffer([10.5, 1, 2, 3, 4, 5, 6, double.nan]);
      expect(state.independentLongitude, isNull);
    });

    test('rejects a 7-element list (the original seven-double allocation)', () {
      expect(
        () => BodyState.fromBuffer(List.filled(7, 0.0)),
        throwsArgumentError,
      );
    });

    test('rejects a 9-element list', () {
      expect(
        () => BodyState.fromBuffer(List.filled(9, 0.0)),
        throwsArgumentError,
      );
    });
  });

  group('daysSinceJ2000', () {
    test('is 0 at the J2000 epoch, 2000-01-01T12:00Z', () {
      expect(daysSinceJ2000(DateTime.utc(2000, 1, 1, 12)), 0.0);
    });

    test('is 1 one day later', () {
      expect(daysSinceJ2000(DateTime.utc(2000, 1, 2, 12)), 1.0);
    });

    test('is negative before the epoch and keeps the fraction of a day', () {
      expect(daysSinceJ2000(DateTime.utc(2000, 1, 1)), -0.5);
    });

    test('throws ArgumentError for a non-UTC DateTime', () {
      expect(
        () => daysSinceJ2000(DateTime(2000, 1, 1, 12)),
        throwsArgumentError,
      );
    });
  });

  group('shimBodyIds', () {
    test('holds exactly sun 0 ... pluto 9, in the shim order', () {
      expect(shimBodyIds, {
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
      });
    });

    test('has no entry for Body.node (the node is not a native body)', () {
      expect(shimBodyIds.containsKey(Body.node), isFalse);
    });
  });
}
