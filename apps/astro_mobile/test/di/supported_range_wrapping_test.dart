// ZOD-FND-011 Task 7.4: the supported date range in front of the real
// astronomy-engine adapter (host test: a fixed `BodyStateSource`, no native
// library). It shows why the decorator is needed (the bare adapter answers the
// mean node for any instant and the Sun inside its own, wider range), that the
// decorator limits every body, that the backup's narrower end stays visible as
// unavailable data, and that a consumer reading the bound port gets the limit.
import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/port_consumer.dart';

/// A native-source stand-in: the Sun on the x axis at 123.456 degrees.
final class _FixedSource implements BodyStateSource {
  @override
  BodyState bodyState(Body body, DateTime utc) => const BodyState(
    longitude: 123.456,
    x: 1,
    y: 0,
    z: 0,
    vx: 0,
    vy: 0.01,
    vz: 0,
  );
}

void main() {
  AstronomyEphemeris bare() => AstronomyEphemeris(source: _FixedSource());
  SupportedRangeEphemeris wrapped() => SupportedRangeEphemeris(bare());

  final lastBefore = DateTime.utc(1899, 12, 31, 23, 59, 59, 999, 999);
  final firstAfter = DateTime.utc(2101);

  group('the mean node', () {
    test('inside the range it is the shared formula', () {
      final t = DateTime.utc(2000, 1, 1, 12);

      expect(
        wrapped().position(Body.node, t),
        EphemerisSuccess(meanAscendingNodeAt(t)),
      );
    });

    test('outside the range it is OutsideSupportedRange', () {
      for (final t in [lastBefore, firstAfter]) {
        expect(
          wrapped().position(Body.node, t),
          OutsideSupportedRange(
            requested: t,
            supported: SupportedDateRange.range,
          ),
        );
      }
    });

    test('the bare adapter answers the same instants with a success, which '
        'is why the decorator is needed', () {
      for (final t in [lastBefore, firstAfter]) {
        expect(bare().position(Body.node, t), isA<EphemerisSuccess>());
      }
    });
  });

  group('a physical body', () {
    test('before 1900 it is OutsideSupportedRange, not OutOfCoveredRange, '
        'even where the backup itself would answer', () {
      // The backup's range starts at 1899-12-31T12:00Z, so the bare adapter
      // answers this instant; the product range starts at 1900-01-01.
      expect(bare().position(Body.sun, lastBefore), isA<EphemerisSuccess>());
      expect(
        wrapped().position(Body.sun, lastBefore),
        OutsideSupportedRange(
          requested: lastBefore,
          supported: SupportedDateRange.range,
        ),
      );
    });

    test(
      'inside the product range but after the backup range it is '
      'OutOfCoveredRange (unavailable data), never OutsideSupportedRange',
      () {
        final t = DateTime.utc(2100, 6, 1);
        final result = wrapped().position(Body.sun, t);

        expect(result, isA<OutOfCoveredRange>());
        expect(result, isNot(isA<OutsideSupportedRange>()));
      },
    );

    test('inside both ranges it is the adapter result', () {
      final t = DateTime.utc(2026, 11, 22, 6);

      expect(wrapped().position(Body.sun, t), bare().position(Body.sun, t));
    });
  });

  group('a consumer of the bound port', () {
    ProviderContainer container() => ProviderContainer.test(
      overrides: [ephemerisPortProvider.overrideWithValue(wrapped())],
    );

    test('gets the position inside the range', () {
      final sun = sunFrom(container(), DateTime.utc(2026, 11, 22, 6));

      expect(sun.longitude, 123.456);
    });

    test('gets the limit outside it', () {
      expect(
        () => sunFrom(container(), DateTime.utc(1850)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OutsideSupportedRange('),
          ),
        ),
      );
    });
  });
}
