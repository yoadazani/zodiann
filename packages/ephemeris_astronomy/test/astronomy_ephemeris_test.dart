import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:test/test.dart';

/// One degree per day as radians per day.
const double _degreePerDay = math.pi / 180;

/// A source that returns one fixed state and records every call.
final class _FakeSource implements BodyStateSource {
  _FakeSource(this.state, {this.error});

  final BodyState state;
  final Object? error;
  final List<Body> calls = [];

  @override
  BodyState bodyState(Body body, DateTime utc) {
    calls.add(body);
    if (error != null) throw error!;
    return state;
  }
}

/// Longitude 100 degrees, on the x axis, moving at one degree per day.
BodyState _state({double longitude = 100.0}) => BodyState(
  longitude: longitude,
  x: 1,
  y: 0,
  z: 0,
  vx: 0,
  vy: _degreePerDay,
  vz: 0,
);

final DateTime _start = DateTime.utc(1899, 12, 31, 12);
final DateTime _end = DateTime.utc(2100, 1, 1, 12);
final DateTime _inRange = DateTime.utc(2026, 11, 21, 6);

const _physicalBodies = [
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

EclipticPosition _success(EphemerisResult result) {
  expect(result, isA<EphemerisSuccess>());
  return (result as EphemerisSuccess).position;
}

void main() {
  group('AstronomyEphemeris', () {
    test('is an EphemerisPort', () {
      expect(
        AstronomyEphemeris(source: _FakeSource(_state())),
        isA<EphemerisPort>(),
      );
    });

    test('the covered range is 1899-12-31T12:00Z to 2100-01-01T12:00Z', () {
      expect(
        AstronomyEphemeris(source: _FakeSource(_state())).coveredRange,
        UtcRange(_start, _end),
      );
    });

    test('a physical body in range returns the source longitude and the '
        'speed derived from its vectors', () {
      final port = AstronomyEphemeris(source: _FakeSource(_state()));
      final position = _success(port.position(Body.mars, _inRange));
      expect(position.longitude, 100.0);
      expect(position.speed, closeTo(1.0, 1e-12));
    });

    test('the speed comes from the vectors, not from any other input', () {
      // x = 3, y = 4, vx = -1, vy = 2: 0.4 rad/day.
      final port = AstronomyEphemeris(
        source: _FakeSource(
          BodyState(
            longitude: 53.13010235415598,
            x: 3,
            y: 4,
            z: 0,
            vx: -1,
            vy: 2,
            vz: 0,
          ),
        ),
      );
      expect(
        _success(port.position(Body.venus, _inRange)).speed,
        closeTo(0.4 * 180 / math.pi, 1e-12),
      );
    });

    test('exactly one source call per position (no differencing)', () {
      final source = _FakeSource(_state());
      AstronomyEphemeris(source: source).position(Body.jupiter, _inRange);
      expect(source.calls, [Body.jupiter]);
    });

    test('each of the ten physical bodies is passed to the source', () {
      final source = _FakeSource(_state());
      final port = AstronomyEphemeris(source: source);
      for (final body in _physicalBodies) {
        _success(port.position(body, _inRange));
      }
      expect(source.calls, _physicalBodies);
    });

    test('Body.node comes from the mean node formula, never the source', () {
      final source = _FakeSource(_state());
      final port = AstronomyEphemeris(source: source);
      final result = port.position(Body.node, _inRange);
      expect(result, EphemerisSuccess(port.meanAscendingNode(_inRange)));
      expect(source.calls, isEmpty);
    });

    test('Body.node succeeds outside the covered range, in 1500 and 2500', () {
      final source = _FakeSource(_state());
      final port = AstronomyEphemeris(source: source);
      for (final utc in [DateTime.utc(1500), DateTime.utc(2500)]) {
        expect(
          port.position(Body.node, utc),
          EphemerisSuccess(port.meanAscendingNode(utc)),
          reason: '$utc',
        );
      }
      expect(source.calls, isEmpty);
    });

    test('the first and last instants of the covered range succeed', () {
      final port = AstronomyEphemeris(source: _FakeSource(_state()));
      _success(port.position(Body.sun, _start));
      _success(port.position(Body.sun, _end));
    });

    test('one microsecond outside the range returns OutOfCoveredRange', () {
      final source = _FakeSource(_state());
      final port = AstronomyEphemeris(source: source);
      final before = _start.subtract(const Duration(microseconds: 1));
      final after = _end.add(const Duration(microseconds: 1));
      expect(
        port.position(Body.sun, before),
        OutOfCoveredRange(requested: before, covered: port.coveredRange),
      );
      expect(
        port.position(Body.sun, after),
        OutOfCoveredRange(requested: after, covered: port.coveredRange),
      );
      expect(source.calls, isEmpty, reason: 'no position is computed');
    });

    test('a non-UTC DateTime throws ArgumentError for every body', () {
      final source = _FakeSource(_state());
      final port = AstronomyEphemeris(source: source);
      final local = DateTime(2026, 11, 21, 6);
      for (final body in Body.values) {
        expect(
          () => port.position(body, local),
          throwsArgumentError,
          reason: '$body',
        );
      }
      expect(source.calls, isEmpty);
    });

    test('a tiny negative longitude never becomes 360.0', () {
      final port = AstronomyEphemeris(
        source: _FakeSource(_state(longitude: -1e-15)),
      );
      final longitude = _success(port.position(Body.sun, _inRange)).longitude;
      expect(longitude, greaterThanOrEqualTo(0));
      expect(longitude, lessThan(360));
    });

    test('a longitude of exactly 360.0 becomes 0.0', () {
      final port = AstronomyEphemeris(
        source: _FakeSource(_state(longitude: 360.0)),
      );
      expect(_success(port.position(Body.sun, _inRange)).longitude, 0.0);
    });

    test('a longitude of 725.5 is reduced to 5.5', () {
      final port = AstronomyEphemeris(
        source: _FakeSource(_state(longitude: 725.5)),
      );
      expect(_success(port.position(Body.sun, _inRange)).longitude, 5.5);
    });

    test('a source error propagates; no position is invented', () {
      final port = AstronomyEphemeris(
        source: _FakeSource(_state(), error: StateError('status 8')),
      );
      expect(() => port.position(Body.pluto, _inRange), throwsStateError);
    });
  });
}
