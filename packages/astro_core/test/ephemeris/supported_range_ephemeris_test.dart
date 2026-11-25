// ZOD-FND-011 Task 7.1: the product-range guard in front of every source.
// `SupportedRangeEphemeris` limits every body, the mean node included,
// through `position()`; `meanAscendingNode()` stays the unlimited formula
// primitive (no failure channel, no exception).
import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// A recording source: counts calls and returns a fixed answer.
final class _RecordingSource implements EphemerisPort {
  _RecordingSource({this.answer});

  /// What `position` returns; a fixed success when null.
  final EphemerisResult? answer;

  int positionCalls = 0;
  int nodeCalls = 0;

  static final physical = UtcRange(DateTime.utc(1800), DateTime.utc(2400));

  @override
  UtcRange get coveredRange => physical;

  @override
  EphemerisResult position(Body body, DateTime utc) {
    positionCalls++;
    return answer ??
        EphemerisSuccess(EclipticPosition(longitude: 12.5, speed: 0.25));
  }

  @override
  EclipticPosition meanAscendingNode(DateTime utc) {
    nodeCalls++;
    return EclipticPosition(longitude: 77.0, speed: -0.05);
  }
}

/// A const source, to prove the decorator can be built in a const context.
final class _ConstSource implements EphemerisPort {
  const _ConstSource();

  static final physical = UtcRange(DateTime.utc(1800), DateTime.utc(2400));

  @override
  UtcRange get coveredRange => physical;

  @override
  EphemerisResult position(Body body, DateTime utc) =>
      EphemerisSuccess(EclipticPosition(longitude: 1, speed: 1));

  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      EclipticPosition(longitude: 1, speed: 1);
}

void main() {
  const tick = Duration(microseconds: 1);
  final start = SupportedDateRange.start;
  final end = SupportedDateRange.end;

  OutsideSupportedRange outside(DateTime t) =>
      OutsideSupportedRange(requested: t, supported: SupportedDateRange.range);

  group('every body is limited through position()', () {
    for (final body in [Body.sun, Body.moon, Body.node]) {
      group(body.name, () {
        test('one microsecond before the range is OutsideSupportedRange and '
            'the source is not called', () {
          final source = _RecordingSource();
          final port = SupportedRangeEphemeris(source);
          final t = start.subtract(tick);

          expect(port.position(body, t), outside(t));
          expect(source.positionCalls, 0);
        });

        test('one microsecond after the range is OutsideSupportedRange and '
            'the source is not called', () {
          final source = _RecordingSource();
          final port = SupportedRangeEphemeris(source);
          final t = end.add(tick);

          expect(port.position(body, t), outside(t));
          expect(source.positionCalls, 0);
        });

        test('the first and the last instant delegate to the source', () {
          final source = _RecordingSource();
          final port = SupportedRangeEphemeris(source);

          expect(port.position(body, start), isA<EphemerisSuccess>());
          expect(port.position(body, end), isA<EphemerisSuccess>());
          expect(source.positionCalls, 2);
        });

        test('a local DateTime throws ArgumentError before anything else', () {
          final source = _RecordingSource();
          final port = SupportedRangeEphemeris(source);

          expect(
            () => port.position(body, DateTime(2000)),
            throwsArgumentError,
          );
          expect(source.positionCalls, 0);
        });
      });
    }

    test('the converted time-zone instants are outside', () {
      final port = SupportedRangeEphemeris(_RecordingSource());
      // 1900-01-01T00:00+14:00 and 2100-12-31T23:00-10:00 in UTC.
      final early = DateTime.utc(1899, 12, 31, 10);
      final late = DateTime.utc(2101, 1, 1, 9);

      expect(port.position(Body.sun, early), outside(early));
      expect(port.position(Body.node, late), outside(late));
    });

    test('a result inside the range is the source result, unchanged', () {
      final answer = EphemerisSuccess(
        EclipticPosition(longitude: 200, speed: -0.4),
      );
      final port = SupportedRangeEphemeris(_RecordingSource(answer: answer));

      expect(port.position(Body.mars, DateTime.utc(2026, 11, 25)), answer);
    });

    test('an OutOfCoveredRange inside the range passes through and is not '
        'an OutsideSupportedRange', () {
      final t = DateTime.utc(2050);
      final inner = OutOfCoveredRange(
        requested: t,
        covered: _RecordingSource.physical,
      );
      final port = SupportedRangeEphemeris(_RecordingSource(answer: inner));

      final result = port.position(Body.sun, t);

      expect(result, inner);
      expect(result, isNot(isA<OutsideSupportedRange>()));
    });
  });

  group('the rest of the port', () {
    test('coveredRange is the source range (physical coverage)', () {
      final source = _RecordingSource();

      expect(
        SupportedRangeEphemeris(source).coveredRange,
        _RecordingSource.physical,
      );
    });

    test('meanAscendingNode is the raw formula primitive: delegated, never '
        'limited, never throwing outside the range', () {
      final source = _RecordingSource();
      final port = SupportedRangeEphemeris(source);
      final far = DateTime.utc(1850);

      expect(port.meanAscendingNode(far), source.meanAscendingNode(far));
      expect(source.nodeCalls, 2);
    });

    test('it can be used as an EphemerisPort', () {
      final EphemerisPort port = SupportedRangeEphemeris(_RecordingSource());

      expect(port.coveredRange, isA<UtcRange>());
    });

    test('it is const-constructible', () {
      const port = SupportedRangeEphemeris(_ConstSource());

      expect(port.coveredRange, _ConstSource.physical);
    });
  });

  group('OutsideSupportedRange', () {
    final t = DateTime.utc(1850);

    test('has value equality and hashCode', () {
      final a = OutsideSupportedRange(
        requested: t,
        supported: SupportedDateRange.range,
      );
      final b = OutsideSupportedRange(
        requested: t,
        supported: SupportedDateRange.range,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the requested instant or the range differs', () {
      final a = OutsideSupportedRange(
        requested: t,
        supported: SupportedDateRange.range,
      );

      expect(
        a,
        isNot(
          OutsideSupportedRange(
            requested: t.add(tick),
            supported: SupportedDateRange.range,
          ),
        ),
      );
      expect(
        a,
        isNot(
          OutsideSupportedRange(
            requested: t,
            supported: UtcRange(DateTime.utc(1900), DateTime.utc(2100)),
          ),
        ),
      );
    });

    test(
      'is an EphemerisFailure and its toString starts with the class name',
      () {
        final r = OutsideSupportedRange(
          requested: t,
          supported: SupportedDateRange.range,
        );

        expect(r, isA<EphemerisFailure>());
        expect(r.toString(), startsWith('OutsideSupportedRange('));
      },
    );

    test(
      'a switch over EphemerisResult with the three cases is exhaustive',
      () {
        String name(EphemerisResult r) => switch (r) {
          EphemerisSuccess() => 'ok',
          OutOfCoveredRange() => 'covered',
          OutsideSupportedRange() => 'supported',
        };

        expect(
          name(
            OutsideSupportedRange(
              requested: t,
              supported: SupportedDateRange.range,
            ),
          ),
          'supported',
        );
      },
    );
  });
}
