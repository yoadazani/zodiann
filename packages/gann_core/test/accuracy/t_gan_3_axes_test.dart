// T-GAN-3 (ZOD-TST-010): the axes 0°, 90°, 180°, 270° are blue and only the
// angles 45°, 135°, 225°, 315° are yellow (spec T-GAN-3, Appendix C).
//
// Product-owner decision (2026-11-12, TST-010 / GAN-002 Notes): 90° is the
// axis straight above cell 1 and 270° straight below. The spec's "270 axis
// (the row above cell 1)" is a typo.
//
// Independence rules (see the TST-010 task file):
// * Only the code under test is imported (`show` list).
// * Expectations are Appendix C's rows as literals (angle, direction, type)
//   and the design reference's blue/yellow cells as literal numbers. Cell
//   membership on a ray is decided geometrically from the forward mapping's
//   (x, y) — never from production's ring or index. Orientation is pinned
//   through angles and positions, because categories alone are invariant
//   under mirroring and rotation.
//
// Coordinates: relative to cell 1, x to the right and y downward (screen).
import 'package:gann_core/gann_core.dart'
    show spiralCell, classifyHighlight, HighlightCategory;
import 'package:test/test.dart';

const _lastCell = 61 * 61; // 3,721, rings 1–30

/// Appendix C, transcribed: angle, direction (x right, y down), type.
const _appendixC = [
  (0.0, 'west', (-1, 0), HighlightCategory.axis),
  (45.0, 'north-west', (-1, -1), HighlightCategory.diagonal),
  (90.0, 'north', (0, -1), HighlightCategory.axis),
  (135.0, 'north-east', (1, -1), HighlightCategory.diagonal),
  (180.0, 'east', (1, 0), HighlightCategory.axis),
  (225.0, 'south-east', (1, 1), HighlightCategory.diagonal),
  (270.0, 'south', (0, 1), HighlightCategory.axis),
  (315.0, 'south-west', (-1, 1), HighlightCategory.diagonal),
];

/// The design reference's highlighted cells, by direction (numbers from
/// 02-square-of-nine_numbers_desktop_en_dark.png; angles from Appendix C —
/// the image labels the axes and shows 315° SW for cell 49).
final _designHighlights = {
  0.0: [2, 11, 28, 53, 86, 127],
  45.0: [3, 13, 31, 57, 91, 133],
  90.0: [4, 15, 34, 61, 96, 139],
  135.0: [5, 17, 37, 65, 101, 145],
  180.0: [6, 19, 40, 69, 106, 151],
  225.0: [7, 21, 43, 73, 111, 157],
  270.0: [8, 23, 46, 77, 116, 163],
  315.0: [9, 25, 49, 81, 121, 169],
};

int _abs(int v) => v < 0 ? -v : v;

void main() {
  for (final (angle, name, (dx, dy), type) in _appendixC) {
    test('Appendix C: ${angle.toInt()}° $name is ${type.name}', () {
      final others = HighlightCategory.values.where((c) => c != type);
      var rayCells = 0;
      for (var n = 2; n <= _lastCell; n++) {
        final cell = spiralCell(n);
        final m = _abs(cell.x) > _abs(cell.y) ? _abs(cell.x) : _abs(cell.y);
        if (cell.x != m * dx || cell.y != m * dy) continue;
        rayCells++;
        final reason = 'cell $n at (${cell.x}, ${cell.y})';
        expect(cell.angle, angle, reason: reason);
        final category = classifyHighlight(cell);
        expect(category, type, reason: reason);
        for (final other in others) {
          expect(category, isNot(other), reason: reason);
        }
      }
      expect(rayCells, 30);
    });
  }

  test('only the diagonals are yellow and only the axes are blue (61×61)', () {
    final axisAngles = {0.0, 90.0, 180.0, 270.0};
    final diagonalAngles = {45.0, 135.0, 225.0, 315.0};
    final bad = <String>[];
    for (var n = 2; n <= _lastCell; n++) {
      final cell = spiralCell(n);
      final category = classifyHighlight(cell);
      final onDiagonal = _abs(cell.x) == _abs(cell.y);
      final onAxis = (cell.x == 0) != (cell.y == 0);
      if ((category == HighlightCategory.diagonal) != onDiagonal) {
        bad.add('$n (${cell.x}, ${cell.y}): $category, diagonal=$onDiagonal');
      }
      if ((category == HighlightCategory.axis) != onAxis) {
        bad.add('$n (${cell.x}, ${cell.y}): $category, axis=$onAxis');
      }
      if ((category == HighlightCategory.diagonal) !=
          diagonalAngles.contains(cell.angle)) {
        bad.add('$n angle ${cell.angle}: $category');
      }
      if ((category == HighlightCategory.axis) !=
          axisAngles.contains(cell.angle)) {
        bad.add('$n angle ${cell.angle}: $category');
      }
    }
    expect(bad, isEmpty);
  });

  test('the design reference highlights', () {
    _designHighlights.forEach((angle, cells) {
      final type = angle % 90 == 0
          ? HighlightCategory.axis
          : HighlightCategory.diagonal;
      for (final n in cells) {
        final cell = spiralCell(n);
        expect(classifyHighlight(cell), type, reason: 'cell $n');
        expect(cell.angle, angle, reason: 'cell $n');
      }
    });
  });

  test('every angle is in [0, 360) (Appendix C: 360 is 0)', () {
    final bad = <String>[];
    for (var n = 2; n <= _lastCell; n++) {
      final angle = spiralCell(n).angle;
      if (angle == null || angle < 0 || angle >= 360) bad.add('$n: $angle');
    }
    expect(bad, isEmpty);
  });
}
