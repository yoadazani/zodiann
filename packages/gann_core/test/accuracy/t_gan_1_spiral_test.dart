// T-GAN-1 (ZOD-TST-010): cell 2 is to the left of cell 1, and the spiral
// moves clockwise across the first dozens of cells (spec T-GAN-1, SQ-8,
// SQ-9).
//
// Independence rules (product-owner decision, see the TST-010 task file):
// * Only the code under test is imported (`show` list).
// * Expected positions are literals: the full 13×13 square transcribed from
//   the design reference
//   design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png
//   (rows top to bottom, columns left to right).
// * Beyond the grid, properties are geometric, computed from (x, y) alone —
//   never from production's ring, index or angle.
//
// Coordinates: relative to cell 1, x to the right and y downward (screen).
import 'package:gann_core/gann_core.dart' show spiralCell, spiralNumberAt;
import 'package:test/test.dart';

/// The design reference's 13×13 square; the center (1) is at [6][6].
const _designGrid = [
  [133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145],
  [132, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 146],
  [131, 90, 57, 58, 59, 60, 61, 62, 63, 64, 65, 102, 147],
  [130, 89, 56, 31, 32, 33, 34, 35, 36, 37, 66, 103, 148],
  [129, 88, 55, 30, 13, 14, 15, 16, 17, 38, 67, 104, 149],
  [128, 87, 54, 29, 12, 3, 4, 5, 18, 39, 68, 105, 150],
  [127, 86, 53, 28, 11, 2, 1, 6, 19, 40, 69, 106, 151],
  [126, 85, 52, 27, 10, 9, 8, 7, 20, 41, 70, 107, 152],
  [125, 84, 51, 26, 25, 24, 23, 22, 21, 42, 71, 108, 153],
  [124, 83, 50, 49, 48, 47, 46, 45, 44, 43, 72, 109, 154],
  [123, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 110, 155],
  [122, 121, 120, 119, 118, 117, 116, 115, 114, 113, 112, 111, 156],
  [169, 168, 167, 166, 165, 164, 163, 162, 161, 160, 159, 158, 157],
];

const _lastCell = 61 * 61; // 3,721, the largest square

(int, int) _pos(int n) {
  final c = spiralCell(n);
  return (c.x, c.y);
}

/// Chebyshev distance from the center: the ring, decided geometrically.
int _geometricRing(int x, int y) => x.abs() > y.abs() ? x.abs() : y.abs();

void main() {
  test('cell 1 is the center and cell 2 is directly left of it', () {
    expect(_pos(1), (0, 0));
    expect(_pos(2), (-1, 0));
  });

  test('all 169 cells of the 13×13 design reference', () {
    final seen = <int>{for (final row in _designGrid) ...row};
    expect(seen, {for (var n = 1; n <= 169; n++) n}, reason: 'transcription');

    final bad = <String>[];
    for (var row = 0; row < 13; row++) {
      for (var col = 0; col < 13; col++) {
        final n = _designGrid[row][col];
        final expected = (col - 6, row - 6);
        if (_pos(n) != expected) {
          bad.add('$n at ${_pos(n)}, expected $expected');
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('the inverse agrees on the design grid', () {
    for (var row = 0; row < 13; row++) {
      for (var col = 0; col < 13; col++) {
        expect(spiralNumberAt(col - 6, row - 6), _designGrid[row][col]);
      }
    }
  });

  test('the inverse round-trips every cell of 61×61', () {
    final bad = <int>[];
    for (var n = 1; n <= _lastCell; n++) {
      final (x, y) = _pos(n);
      if (spiralNumberAt(x, y) != n) bad.add(n);
    }
    expect(bad, isEmpty);
  });

  test('moves clockwise, one step at a time, through 61×61', () {
    final bad = <String>[];
    var sameRingPairs = 0;
    for (var n = 1; n < _lastCell; n++) {
      final (x1, y1) = _pos(n);
      final (x2, y2) = _pos(n + 1);
      if ((x2 - x1).abs() + (y2 - y1).abs() != 1) {
        bad.add('$n → ${n + 1}: not a unit step');
        continue;
      }
      if (n == 1 || _geometricRing(x1, y1) != _geometricRing(x2, y2)) continue;
      sameRingPairs++;
      // Screen coordinates (y down): clockwise means a positive cross product.
      if (x1 * y2 - y1 * x2 <= 0) bad.add('$n → ${n + 1}: not clockwise');
    }
    expect(bad, isEmpty);
    // 3,719 pairs from 2…3720, minus 29 ring changes.
    expect(sameRingPairs, 3690);
  });

  test('ring k is entered at (−k, k−1) and left at (−k, k), for k = 1…30', () {
    for (var k = 1; k <= 30; k++) {
      final first = (2 * k - 1) * (2 * k - 1) + 1;
      final last = (2 * k + 1) * (2 * k + 1);
      expect(_pos(first), (-k, k - 1), reason: 'ring $k entry, cell $first');
      expect(_pos(last), (-k, k), reason: 'ring $k exit, cell $last');
    }
  });
}
