// T-GAN-2 (ZOD-TST-011): each ring has exactly four blue cells, four yellow,
// and in even rings also eight gray; a 9×9 square has 16 blue, 16 yellow and
// 16 gray (spec T-GAN-2, Appendix B, SQ-9, SQ-12 to SQ-15).
//
// Independence rules (product-owner decision, see the TST-011 task file):
// * Only the code under test is imported (`show` list).
// * Expected values are Appendix B's table, transcribed as literals, and
//   T-GAN-2's own sentence (with the parity table after SQ-15: odd rings have
//   no gray) for rings beyond the table.
// * Ring membership never comes from production's `ring`: ranges come from
//   the table's "last number" column (and SQ-9's (2k+1)² beyond it), and are
//   cross-checked geometrically with max(|x|, |y|) on the forward mapping.
//
// Counts are invariant under rotation and mirroring, so where the highlights
// sit is T-GAN-3's job (t_gan_3_axes_test.dart, ZOD-TST-010). Known survivors
// here, caught there: a rotated or mirrored spiral, and a classifier reading
// the ring index j instead of the steps i (each ring rotated by k−1 steps).
import 'package:gann_core/gann_core.dart'
    show spiralCell, classifyHighlight, HighlightCategory;
import 'package:test/test.dart';

/// Appendix B: (ring k, cells in ring, angle per cell, blue, yellow, gray,
/// square side up to the ring, last number).
const _appendixB = [
  (1, 8, 45.0, 4, 4, 0, 3, 9),
  (2, 16, 22.5, 4, 4, 8, 5, 25),
  (3, 24, 15.0, 4, 4, 0, 7, 49),
  (4, 32, 11.25, 4, 4, 8, 9, 81),
  (5, 40, 9.0, 4, 4, 0, 11, 121),
  (6, 48, 7.5, 4, 4, 8, 13, 169),
];

int _geometricRing(int n) {
  final c = spiralCell(n);
  final x = c.x.abs(), y = c.y.abs();
  return x > y ? x : y;
}

/// Category counts over cells [from]…[to], plus the geometric rings seen.
({int axis, int diagonal, int eighth, int none, Set<int> rings}) _counts(
  int from,
  int to,
) {
  var axis = 0, diagonal = 0, eighth = 0, none = 0;
  final rings = <int>{};
  for (var n = from; n <= to; n++) {
    rings.add(_geometricRing(n));
    switch (classifyHighlight(spiralCell(n))) {
      case HighlightCategory.axis:
        axis++;
      case HighlightCategory.diagonal:
        diagonal++;
      case HighlightCategory.eighth:
        eighth++;
      case null:
        none++;
    }
  }
  return (
    axis: axis,
    diagonal: diagonal,
    eighth: eighth,
    none: none,
    rings: rings,
  );
}

void main() {
  var prevLast = 1; // the center, not counted in a ring (Appendix B)
  for (final (k, cells, step, blue, yellow, gray, side, last) in _appendixB) {
    final first = prevLast + 1;
    test(
      'Appendix B ring $k: $cells cells, $blue blue / $yellow yellow / $gray gray',
      () {
        // Table self-consistency.
        expect(last - first + 1, cells);

        // Cells in ring: production's placement, counted geometrically.
        var placed = 0;
        for (var n = 2; n <= 15 * 15; n++) {
          if (_geometricRing(n) == k) placed++;
        }
        expect(placed, cells, reason: 'cells placed in ring $k');

        final c = _counts(first, last);
        expect(c.rings, {k}, reason: 'cells $first…$last all in ring $k');
        expect(c.axis, blue, reason: 'blue');
        expect(c.diagonal, yellow, reason: 'yellow');
        expect(c.eighth, gray, reason: 'gray');
        expect(c.none, cells - blue - yellow - gray, reason: 'unhighlighted');

        // Square side up to the ring (mirrors the table; implied by the ring
        // check above for a square ring).
        var maxX = 0;
        for (var n = first; n <= last; n++) {
          final x = spiralCell(n).x.abs();
          if (x > maxX) maxX = x;
        }
        expect(2 * maxX + 1, side, reason: 'side');

        // Angle per cell: consecutive cells, including the wrap to 0° (rings ≥ 2;
        // in ring 1, 0° is the first cell).
        for (var n = first; n < last; n++) {
          final d =
              (spiralCell(n + 1).angle! - spiralCell(n).angle! + 360) % 360;
          expect(d, step, reason: 'angle step $n → ${n + 1}');
        }

        // Last number: the ring ends at `last`.
        expect(_geometricRing(last), k, reason: 'last number $last');
        expect(
          _geometricRing(last + 1),
          k + 1,
          reason: '${last + 1} starts ring ${k + 1}',
        );
      },
    );
    prevLast = last;
  }

  test('9×9 square (rings 1–4): 16 blue, 16 yellow, 16 gray', () {
    expect(classifyHighlight(spiralCell(1)), isNull, reason: 'center');
    final c = _counts(2, 81);
    expect(c.rings, {1, 2, 3, 4});
    expect(c.axis, 16);
    expect(c.diagonal, 16);
    expect(c.eighth, 16);
  });

  test(
    'T-GAN-2 for rings 7–30: 4 blue, 4 yellow, 8 gray in even rings, 0 in odd',
    () {
      for (var k = 7; k <= 30; k++) {
        final first = (2 * k - 1) * (2 * k - 1) + 1;
        final last = (2 * k + 1) * (2 * k + 1);
        final c = _counts(first, last);
        expect(c.rings, {k}, reason: 'ring $k range');
        expect(c.axis, 4, reason: 'ring $k blue');
        expect(c.diagonal, 4, reason: 'ring $k yellow');
        expect(c.eighth, k.isEven ? 8 : 0, reason: 'ring $k gray');
      }
    },
  );
}
