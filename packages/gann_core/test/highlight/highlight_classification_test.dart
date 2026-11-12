import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

HighlightCategory? classifyAt(int x, int y) =>
    classifyHighlight(spiralCell(spiralNumberAt(x, y)));

/// Geometric oracle, independent of i and k (pre-verified on 61×61):
/// axis ⇔ x = 0 or y = 0; else diagonal ⇔ |x| = |y|;
/// else eighth ⇔ |x| = 2|y| or |y| = 2|x|; else none.
HighlightCategory? geometricCategory(int x, int y) {
  if (x == 0 || y == 0) return HighlightCategory.axis;
  if (x.abs() == y.abs()) return HighlightCategory.diagonal;
  if (x.abs() == 2 * y.abs() || y.abs() == 2 * x.abs()) {
    return HighlightCategory.eighth;
  }
  return null;
}

bool _near(double a, double b) => (a - b).abs() <= 1e-9;

/// Evaluates FND-012's rules on the cell's θ in ascending priority order;
/// the first matching rule decides.
String? matchingDefaultRuleId(SpiralCell cell) {
  final rules = [...defaultHighlightRules]
    ..sort((a, b) => a.priority.compareTo(b.priority));
  final theta = cell.angle!;
  for (final rule in rules) {
    final matches = switch (rule.match) {
      AnglesMatch(:final degrees) => degrees.any((d) => _near(theta, d)),
      MultipleOfMatch(:final degrees) => _near(
        theta / degrees,
        (theta / degrees).roundToDouble(),
      ),
    };
    if (matches) return rule.id;
  }
  return null;
}

void main() {
  group('classifyHighlight', () {
    test('the center is never classified', () {
      expect(classifyHighlight(spiralCell(1)), isNull);
    });

    test('Appendix C directions on the first ring', () {
      const expected = {
        2: HighlightCategory.axis, // west, 0°
        3: HighlightCategory.diagonal, // NW, 45°
        4: HighlightCategory.axis, // north, 90°, straight above cell 1
        5: HighlightCategory.diagonal, // NE
        6: HighlightCategory.axis, // east
        7: HighlightCategory.diagonal, // SE
        8: HighlightCategory.axis, // south, 270°, straight below
        9: HighlightCategory.diagonal, // SW
      };
      expected.forEach((n, category) {
        expect(classifyHighlight(spiralCell(n)), category, reason: 'n=$n');
      });
    });

    test(
      'the 90° axis is the column straight above cell 1, not the row y = −1',
      () {
        for (final (x, y, n) in [(0, -1, 4), (0, -2, 15), (0, -3, 34)]) {
          expect(spiralNumberAt(x, y), n);
          expect(classifyAt(x, y), HighlightCategory.axis, reason: '($x, $y)');
        }
        expect(classifyAt(-1, -1), HighlightCategory.diagonal); // 3
        expect(classifyAt(1, -1), HighlightCategory.diagonal); // 5
        expect(classifyAt(-1, -2), HighlightCategory.eighth); // 14
        expect(classifyAt(1, -2), HighlightCategory.eighth); // 16
        // Classification is symmetric under rotation/mirroring, so pin the
        // orientation through the forward mapping alone: every 90° axis cell
        // is straight above cell 1, every 270° cell straight below.
        for (var n = 2; n <= 81; n++) {
          final c = spiralCell(n);
          if (c.angle == 90) {
            expect((c.x == 0, c.y < 0), (true, true), reason: '90° n=$n');
          } else if (c.angle == 270) {
            expect((c.x == 0, c.y > 0), (true, true), reason: '270° n=$n');
          }
        }
      },
    );

    test('is exact at the outermost ring (maxSpiralRing)', () {
      const k = maxSpiralRing; // even
      final b = (2 * k - 1) * (2 * k - 1);
      expect(k.isEven, isTrue);
      // j = i + (k − 1), so n = b + 1 + j = b + k + i.
      final axis = spiralCell(b + k); // i = 0
      final diagonal = spiralCell(b + 2 * k); // i = k
      final eighth = spiralCell(b + k + k ~/ 2); // i = k / 2
      final none = spiralCell(b + k + 1); // i = 1
      expect(
        [
          axis.stepsFromAxis,
          diagonal.stepsFromAxis,
          eighth.stepsFromAxis,
          none.stepsFromAxis,
        ],
        [0, k, k ~/ 2, 1],
      );
      expect(classifyHighlight(axis), HighlightCategory.axis);
      expect(classifyHighlight(diagonal), HighlightCategory.diagonal);
      expect(classifyHighlight(eighth), HighlightCategory.eighth);
      expect(classifyHighlight(none), isNull);
    });

    test('matches the geometric oracle for every cell of a 61×61 square', () {
      for (var x = -30; x <= 30; x++) {
        for (var y = -30; y <= 30; y++) {
          if (x == 0 && y == 0) continue;
          expect(classifyAt(x, y), geometricCategory(x, y), reason: '($x, $y)');
        }
      }
    });

    test('Appendix B: odd rings 4/4/0, even rings 4/4/8 (rings 1–6)', () {
      // Literal values from Appendix B: blue / yellow / gray per ring.
      const appendixB = {
        1: [4, 4, 0],
        2: [4, 4, 8],
        3: [4, 4, 0],
        4: [4, 4, 8],
        5: [4, 4, 0],
        6: [4, 4, 8],
      };
      appendixB.forEach((k, expected) {
        final counts = {for (final c in HighlightCategory.values) c: 0};
        for (
          var n = (2 * k - 1) * (2 * k - 1) + 1;
          n <= (2 * k + 1) * (2 * k + 1);
          n++
        ) {
          final category = classifyHighlight(spiralCell(n));
          if (category != null) counts[category] = counts[category]! + 1;
        }
        expect(
          [
            counts[HighlightCategory.axis],
            counts[HighlightCategory.diagonal],
            counts[HighlightCategory.eighth],
          ],
          expected,
          reason: 'ring $k',
        );
      });
    });

    test('axis exactly at 0/90/180/270 and diagonal exactly at 45/135/225/315 (literal angles), 61×61', () {
      final axisAngles = {0.0, 90.0, 180.0, 270.0};
      final diagonalAngles = {45.0, 135.0, 225.0, 315.0};
      for (var n = 2; n <= 3721; n++) {
        final cell = spiralCell(n);
        final category = classifyHighlight(cell);
        expect(
          category == HighlightCategory.axis,
          axisAngles.contains(cell.angle),
          reason: 'n=$n θ=${cell.angle}',
        );
        expect(
          category == HighlightCategory.diagonal,
          diagonalAngles.contains(cell.angle),
          reason: 'n=$n θ=${cell.angle}',
        );
      }
    });

    test('a 9×9 square has 16 blue, 16 yellow and 16 gray', () {
      final counts = {for (final c in HighlightCategory.values) c: 0};
      for (var n = 2; n <= 81; n++) {
        final category = classifyHighlight(spiralCell(n));
        if (category != null) counts[category] = counts[category]! + 1;
      }
      expect(counts, {
        HighlightCategory.axis: 16,
        HighlightCategory.diagonal: 16,
        HighlightCategory.eighth: 16,
      });
    });

    test('priority: blue before yellow before gray', () {
      // Cell 2: i = 0 satisfies all three tests → blue wins.
      expect(classifyHighlight(spiralCell(2)), HighlightCategory.axis);
      // Cell 13: ring 2, i = 2 = k satisfies yellow and gray → yellow wins.
      final c13 = spiralCell(13);
      expect((c13.ring, c13.stepsFromAxis), (2, 2));
      expect(classifyHighlight(c13), HighlightCategory.diagonal);
      // Cell 12: ring 2, i = 1 satisfies gray only.
      expect(classifyHighlight(spiralCell(12)), HighlightCategory.eighth);
      // Cell 26: ring 3, i = 22 satisfies none.
      final c26 = spiralCell(26);
      expect((c26.ring, c26.stepsFromAxis), (3, 22));
      expect(classifyHighlight(c26), isNull);
    });

    test(
      "agrees with the default rules' angles (FND-012) on every cell of 61×61",
      () {
        for (var n = 2; n <= 3721; n++) {
          final cell = spiralCell(n);
          expect(
            matchingDefaultRuleId(cell),
            classifyHighlight(cell)?.defaultRuleId,
            reason: 'n=$n θ=${cell.angle}',
          );
        }
      },
    );
  });

  group('HighlightCategory', () {
    test('defaultRuleId maps to the FND-012 default rule ids', () {
      expect(HighlightCategory.axis.defaultRuleId, 'axes');
      expect(HighlightCategory.diagonal.defaultRuleId, 'diagonals');
      expect(HighlightCategory.eighth.defaultRuleId, 'eighths');
    });
  });

  group('highlightRuleFor', () {
    test('finds the default rule for each category', () {
      expect(
        highlightRuleFor(
          HighlightCategory.axis,
          defaultHighlightRules,
        )?.colorToken,
        'axis',
      );
      expect(
        highlightRuleFor(
          HighlightCategory.diagonal,
          defaultHighlightRules,
        )?.colorToken,
        'diag',
      );
      expect(
        highlightRuleFor(
          HighlightCategory.eighth,
          defaultHighlightRules,
        )?.colorToken,
        'eighth',
      );
    });

    test('returns null when the square has no rule for the category', () {
      for (final category in HighlightCategory.values) {
        expect(
          highlightRuleFor(category, const []),
          isNull,
          reason: '$category',
        );
      }
      final withoutEighths = defaultHighlightRules
          .where((r) => r.id != 'eighths')
          .toList();
      expect(
        highlightRuleFor(HighlightCategory.eighth, withoutEighths),
        isNull,
      );
      expect(
        highlightRuleFor(HighlightCategory.axis, withoutEighths)?.id,
        'axes',
      );
      expect(
        highlightRuleFor(HighlightCategory.diagonal, withoutEighths)?.id,
        'diagonals',
      );
    });
  });
}
