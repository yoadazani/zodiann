// ZOD-L10-007 (L-9): compass directions have stable keys, and map from the
// spiral's angle convention (0° on the west axis, clockwise).
import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

CompassDirection? _dirOf(int n) =>
    CompassDirection.atAngle(spiralCell(n).angle!);

void main() {
  test('keys are pinned', () {
    expect(CompassDirection.values.map((d) => d.toJson()), [
      'west',
      'northWest',
      'north',
      'northEast',
      'east',
      'southEast',
      'south',
      'southWest',
    ]);
  });

  test('fromJson round-trips every key', () {
    for (final d in CompassDirection.values) {
      expect(CompassDirection.fromJson(d.toJson()), d);
    }
  });

  test('fromJson rejects unknown, wrong-case and non-string input', () {
    for (final bad in <Object?>['NW', 'north-west', 'West', '', 0, null]) {
      expect(
        () => CompassDirection.fromJson(bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });

  test('angleDegrees follows the spiral convention', () {
    expect(CompassDirection.values.map((d) => d.angleDegrees), [
      0,
      45,
      90,
      135,
      180,
      225,
      270,
      315,
    ]);
  });

  test('atAngle maps the eight axes and nothing else', () {
    for (final d in CompassDirection.values) {
      expect(CompassDirection.atAngle(d.angleDegrees), d);
    }
    for (final other in [22.5, 360.0, -45.0, 44.999]) {
      expect(CompassDirection.atAngle(other), isNull, reason: '$other');
    }
  });

  test('ring 1: cell 2 is west, corners are diagonals', () {
    expect([for (var n = 2; n <= 9; n++) _dirOf(n)], CompassDirection.values);
  });

  test('far rings stay exact', () {
    expect(_dirOf(spiralNumberAt(-30, 0)), CompassDirection.west);
    expect(_dirOf(spiralNumberAt(30, -30)), CompassDirection.northEast);
  });
}
