// ZOD-EPH-002: the Swiss Ephemeris adapter over a recording fake source. The
// real library runs on a device (apps/astro_mobile/integration_test).
import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:test/test.dart';

const _tick = Duration(microseconds: 1);

const _physical = [
  Body.sun,
  Body.moon,
  Body.mercury,
  Body.venus,
  Body.mars,
  Body.jupiter,
  Body.saturn,
  Body.uranus,
  Body.neptune,
  Body.pluto,
];

SwissCalcResult _result({
  double longitude = 123.5,
  double speed = -0.25,
  int returnFlags = seflgSwieph | seflgSpeed,
  String error = '',
}) => SwissCalcResult(
  longitude: longitude,
  speed: speed,
  returnFlags: returnFlags,
  error: error,
);

final class _FakeSource implements SwissCalculationSource {
  _FakeSource([this.result]);

  /// Returned by both calls; null means the source cannot calculate.
  SwissCalcResult? result;

  final ut = <(DateTime, int, int)>[];
  final tt = <(double, int, int)>[];

  @override
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags}) {
    ut.add((utc, body, flags));
    return result;
  }

  @override
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags}) {
    tt.add((tjdTt, body, flags));
    return result;
  }

  int get calls => ut.length + tt.length;
}

double _ttDay(DateTime utc, int taiMinusUtcSeconds) => julianDayUt(
  utc.add(Duration(microseconds: 32184000 + taiMinusUtcSeconds * 1000000)),
);

void main() {
  test('the body ids are the SE_ numbers of the ten physical bodies', () {
    expect(swissBodyIds, {
      for (var i = 0; i < _physical.length; i++) _physical[i]: i,
    });
    expect(swissBodyIds.containsKey(Body.node), isFalse);
  });

  test('the flag word is exactly SWIEPH and SPEED', () {
    expect(swissAdapterFlags, 258);
  });

  group('the time conversion', () {
    test('before 1972 every body goes to calcUt with the instant', () {
      final utc = DateTime.utc(1971, 12, 31, 23, 59, 59, 999, 999);
      for (final body in _physical) {
        final source = _FakeSource(_result());

        SwissEphemeris(source: source).position(body, utc);

        expect(source.ut, [(utc, swissBodyIds[body], 258)], reason: '$body');
        expect(source.tt, isEmpty);
      }
    });

    test('from 1972 the TT of the leap-second table goes to calcTt', () {
      for (final (utc, taiMinusUtc) in [
        (DateTime.utc(1972), 10),
        (DateTime.utc(2026, 11, 26), 37),
      ]) {
        final source = _FakeSource(_result());

        SwissEphemeris(source: source).position(Body.moon, utc);

        expect(source.tt, [(_ttDay(utc, taiMinusUtc), 1, 258)]);
        expect(source.ut, isEmpty);
      }
    });

    test('a different leap table changes the TT passed', () {
      final source = _FakeSource(_result());
      final table = LeapSecondTable(
        steps: [
          LeapSecondStep(from: DateTime.utc(2000), taiMinusUtcSeconds: 50),
        ],
        validUntil: DateTime.utc(2001),
        source: 's',
        bulletin: 'b',
      );
      final utc = DateTime.utc(2026, 11, 26);

      SwissEphemeris(
        source: source,
        leapSeconds: table,
      ).position(Body.sun, utc);

      expect(source.tt, [(_ttDay(utc, 50), 0, 258)]);
    });
  });

  group('a valid result', () {
    final utc = DateTime.utc(2000, 1, 1, 12);

    test('is the library longitude and speed from one call', () {
      final source = _FakeSource(_result(longitude: 10, speed: 12.5));

      final result = SwissEphemeris(source: source).position(Body.moon, utc);

      expect(
        result,
        EphemerisSuccess(EclipticPosition(longitude: 10, speed: 12.5)),
      );
      expect(source.calls, 1);
    });

    test('has its longitude normalized', () {
      EclipticPosition at(double longitude) => (SwissEphemeris(
        source: _FakeSource(_result(longitude: longitude)),
      ).position(Body.sun, utc) as EphemerisSuccess).position;

      expect(at(-1e-15).longitude, 0.0);
      expect(at(370).longitude, 10);
    });
  });

  group('an unusable result is data unavailable, never a position', () {
    final unusable = <String, SwissCalcResult?>{
      'no result': null,
      'the Moshier flag': _result(returnFlags: seflgMoseph | seflgSpeed),
      'a warning': _result(error: 'file not found'),
      // The Swiss bit is set and the Moshier bit clear: only the sign says
      // this is an error.
      'a negative return': _result(returnFlags: -5),
      'a NaN longitude': _result(longitude: double.nan),
      'an infinite longitude': _result(longitude: double.infinity),
      'a NaN speed': _result(speed: double.nan),
    };

    unusable.forEach((name, value) {
      test(name, () {
        final port = SwissEphemeris(source: _FakeSource(value));
        final utc = DateTime.utc(2000);

        expect(
          port.position(Body.mars, utc),
          OutOfCoveredRange(requested: utc, covered: port.coveredRange),
        );
      });
    });

    test('over the unavailable source, for all ten bodies', () {
      final port = SwissEphemeris(
        source: const UnavailableSwissCalculationSource(),
      );
      for (final utc in [DateTime.utc(1900), DateTime.utc(2000)]) {
        for (final body in _physical) {
          expect(port.position(body, utc), isA<OutOfCoveredRange>());
        }
        expect(
          port.position(Body.node, utc),
          EphemerisSuccess(meanAscendingNodeAt(utc)),
        );
      }
    });
  });

  group('coverage', () {
    test('is the file coverage and encloses the supported range', () {
      final port = SwissEphemeris(source: _FakeSource());

      expect(port.coveredRange, SwissEphemeris.fileCoverage);
      expect(port.coveredRange.contains(SupportedDateRange.start), isTrue);
      expect(port.coveredRange.contains(SupportedDateRange.end), isTrue);
    });

    test('one microsecond outside it, the source is not called', () {
      final source = _FakeSource(_result());
      final port = SwissEphemeris(source: source);
      final range = port.coveredRange;

      for (final utc in [range.start.subtract(_tick), range.end.add(_tick)]) {
        expect(
          port.position(Body.sun, utc),
          OutOfCoveredRange(requested: utc, covered: range),
        );
      }
      expect(source.calls, 0);
    });

    test('both ends are covered', () {
      final source = _FakeSource(_result());
      final port = SwissEphemeris(source: source);

      for (final utc in [port.coveredRange.start, port.coveredRange.end]) {
        expect(port.position(Body.sun, utc), isA<EphemerisSuccess>());
      }
      expect(source.calls, 2);
    });
  });

  group('the node and bad input', () {
    test('the node is the formula, in and outside coverage, with no call', () {
      final source = _FakeSource(_result());
      final port = SwissEphemeris(source: source);

      for (final utc in [
        DateTime.utc(1000),
        DateTime.utc(2000),
        DateTime.utc(3000),
      ]) {
        expect(
          port.position(Body.node, utc),
          EphemerisSuccess(meanAscendingNodeAt(utc)),
        );
      }
      expect(source.calls, 0);
    });

    test('a non-UTC instant is rejected', () {
      final port = SwissEphemeris(source: _FakeSource(_result()));

      expect(
        () => port.position(Body.sun, DateTime(2000)),
        throwsArgumentError,
      );
      expect(
        () => port.position(Body.node, DateTime(2000)),
        throwsArgumentError,
      );
    });

    test('calculateSwissBody rejects the node', () {
      expect(
        () => calculateSwissBody(
          _FakeSource(_result()),
          Body.node,
          DateTime.utc(2000),
        ),
        throwsArgumentError,
      );
    });
  });
}
