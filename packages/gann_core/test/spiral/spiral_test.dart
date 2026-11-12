import 'dart:math' as math;

import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

/// Reference values from the spec formula, cross-checked against the design
/// reference (02-square-of-nine_numbers_desktop_en_dark.png).
/// Columns: n, k, j, i, θ, x, y.
const _reference = <List<num>>[
  [2, 1, 0, 0, 0.0, -1, 0],
  [3, 1, 1, 1, 45.0, -1, -1],
  [4, 1, 2, 2, 90.0, 0, -1],
  [5, 1, 3, 3, 135.0, 1, -1],
  [6, 1, 4, 4, 180.0, 1, 0],
  [7, 1, 5, 5, 225.0, 1, 1],
  [8, 1, 6, 6, 270.0, 0, 1],
  [9, 1, 7, 7, 315.0, -1, 1],
  [10, 2, 0, 15, 337.5, -2, 1],
  [13, 2, 3, 2, 45.0, -2, -2],
  [25, 2, 15, 14, 315.0, -2, 2],
  [26, 3, 0, 22, 330.0, -3, 2],
  [49, 3, 23, 21, 315.0, -3, 3],
  [81, 4, 31, 28, 315.0, -4, 4],
  [82, 5, 0, 36, 324.0, -5, 4],
  [3721, 30, 239, 210, 315.0, -30, 30],
];

/// Geometric screen angle, independent of the formula's i: west = 0°,
/// north = 90°, east = 180°, south = 270° (x right, y down).
double _screenAngle(int x, int y) {
  final phi = math.atan2(-y, x) * 180 / math.pi;
  return (180 - phi) % 360;
}

/// Smallest k with (2k+1)² ≥ n — the ring by definition, in integers.
int _ringByDefinition(int n) {
  var k = 0;
  while ((2 * k + 1) * (2 * k + 1) < n) {
    k++;
  }
  return k;
}

void main() {
  group('spiralCell', () {
    test('center: n = 1 is ring 0 at (0, 0) with no index, steps or angle', () {
      final c = spiralCell(1);

      expect(c.n, 1);
      expect(c.ring, 0);
      expect(c.indexInRing, isNull);
      expect(c.stepsFromAxis, isNull);
      expect(c.angle, isNull);
      expect((c.x, c.y), (0, 0));
    });

    test('rejects n < 1 and n > maxSpiralNumber', () {
      for (final bad in [0, -5, 9007199136250226]) {
        expect(() => spiralCell(bad), throwsArgumentError, reason: '$bad');
      }
    });

    test('accepts maxSpiralNumber, the last cell of ring maxSpiralRing', () {
      expect(maxSpiralRing, 47453132);
      expect(maxSpiralNumber, 9007199136250225);
      final c = spiralCell(9007199136250225);

      expect(c.ring, 47453132);
      expect((c.x, c.y), (-47453132, 47453132));
    });

    test('matches the reference table', () {
      for (final row in _reference) {
        final c = spiralCell(row[0] as int);
        final label = 'n=${row[0]}';
        expect(c.ring, row[1], reason: label);
        expect(c.indexInRing, row[2], reason: label);
        expect(c.stepsFromAxis, row[3], reason: label);
        expect(c.angle, row[4], reason: label);
        expect((c.x, c.y), (row[5], row[6]), reason: label);
      }
    });

    test('cell 2 is left of cell 1 and the first ring runs clockwise: left, up, right, down', () {
      final positions = [for (var n = 2; n <= 9; n++) spiralCell(n)]
          .map((c) => (c.x, c.y))
          .toList();

      expect(positions, [
        (-1, 0), // 2: left of 1
        (-1, -1),
        (0, -1), // 4: up
        (1, -1),
        (1, 0), // 6: right
        (1, 1),
        (0, 1), // 8: down
        (-1, 1),
      ]);
    });

    test('every ring 1–6 runs clockwise on screen', () {
      for (var k = 1; k <= 6; k++) {
        final first = (2 * k - 1) * (2 * k - 1) + 1;
        final last = (2 * k + 1) * (2 * k + 1);
        final psi = [
          for (var n = first; n <= last; n++)
            _screenAngle(spiralCell(n).x, spiralCell(n).y),
        ];
        final wraps = [
          for (var m = 0; m + 1 < psi.length; m++)
            if (psi[m + 1] <= psi[m]) m,
        ];

        if (k == 1) {
          // Ring 1 starts on the west axis (cell 2, ψ = 0): no wrap.
          expect(wraps, isEmpty, reason: 'ring 1');
        } else {
          // Ring k starts k−1 cells below the west axis, so ψ wraps through
          // 360 exactly once: on the step onto the west-axis cell (i = 0).
          expect(wraps, [k - 2], reason: 'ring $k: one wrap onto the axis');
          expect(spiralCell(first + k - 1).stepsFromAxis, 0, reason: 'ring $k');
        }
      }
    });

    test('θ equals the geometric angle on axes and diagonals', () {
      for (var n = 2; n <= 169; n++) {
        final c = spiralCell(n);
        if (c.stepsFromAxis! % c.ring != 0) continue;
        final psi = _screenAngle(c.x, c.y);
        final theta = c.angle! % 360;
        expect(theta, closeTo(psi == 360 ? 0 : psi, 1e-9), reason: 'n=$n');
      }
    });

    test('consecutive cells are grid neighbours', () {
      var previous = spiralCell(1);
      for (var n = 2; n <= 3721; n++) {
        final c = spiralCell(n);
        expect(
          (c.x - previous.x).abs() + (c.y - previous.y).abs(),
          1,
          reason: '${n - 1} → $n',
        );
        previous = c;
      }
    });

    test('ring boundaries', () {
      const expected = {
        9: 1,
        10: 2,
        25: 2,
        26: 3,
        81: 4,
        82: 5,
        3721: 30,
        3722: 31,
      };
      expected.forEach((n, ring) {
        expect(spiralCell(n).ring, ring, reason: 'n=$n');
      });
    });

    test('ring agrees with the integer definition', () {
      for (var n = 2; n <= 200000; n++) {
        expect(spiralCell(n).ring, _ringByDefinition(n), reason: 'n=$n');
      }
      // 94906263² = 9007198756625169. At +1 the plain sqrt formula returns
      // 47453131; only the integer correction gives the right ring.
      expect(spiralCell(9007198756625168).ring, 47453131);
      expect(spiralCell(9007198756625169).ring, 47453131);
      expect(spiralCell(9007198756625170).ring, 47453132);
    });

    test('has value equality', () {
      expect(spiralCell(49), spiralCell(49));
      expect(spiralCell(49).hashCode, spiralCell(49).hashCode);
      expect(spiralCell(49), isNot(spiralCell(48)));
    });
  });

  group('ring helpers', () {
    test('match Appendix B for rings 1–6', () {
      expect(
        [for (var k = 1; k <= 6; k++) cellsInRing(k)],
        [8, 16, 24, 32, 40, 48],
      );
      expect(
        [for (var k = 1; k <= 6; k++) squareSideForRing(k)],
        [3, 5, 7, 9, 11, 13],
      );
      expect(
        [for (var k = 1; k <= 6; k++) lastNumberInRing(k)],
        [9, 25, 49, 81, 121, 169],
      );
    });

    test('ring 1 ends at 9 and ring 4 ends at 81', () {
      expect(lastNumberInRing(1), 9);
      expect(lastNumberInRing(4), 81);
    });

    test('the center is ring 0', () {
      expect(cellsInRing(0), 1);
      expect(squareSideForRing(0), 1);
      expect(lastNumberInRing(0), 1);
    });

    test('reject rings outside 0…maxSpiralRing', () {
      for (final k in [-1, maxSpiralRing + 1]) {
        expect(() => cellsInRing(k), throwsArgumentError, reason: '$k');
        expect(() => squareSideForRing(k), throwsArgumentError, reason: '$k');
        expect(() => lastNumberInRing(k), throwsArgumentError, reason: '$k');
      }
      expect(lastNumberInRing(maxSpiralRing), maxSpiralNumber);
    });
  });
}
