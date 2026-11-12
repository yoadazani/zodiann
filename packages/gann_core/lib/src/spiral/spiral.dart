/// The Square of Nine spiral (spec "Gann spiral", SQ-8, SQ-9, SQ-11,
/// Appendix B): from a cell number to its ring, index, angle and grid
/// position.
///
/// The orientation is the spec's fixed choice (SQ-8): 1 in the center, 2 to
/// its left, and the spiral continues clockwise — left, up, right, down.
/// (A configurable start and direction is ZOD-EXT-010.) Positions are relative
/// to the center with **x to the right and y downward**, as on screen.
library;

import 'dart:math' as math;

/// The outermost supported ring: the largest full ring whose last cell is
/// ≤ 2^53. Forward ([spiralCell]) and inverse mapping share this range, so
/// every supported cell round-trips. (Assumes 64-bit VM/AOT integers — the
/// mobile targets.)
const int maxSpiralRing = 47453132;

/// The last cell of [maxSpiralRing]: (2·47453132 + 1)². The largest `n`
/// [spiralCell] accepts.
const int maxSpiralNumber = 9007199136250225;

/// One cell of the spiral. Derived from [spiralCell] only (no public
/// constructor, no JSON), so its fields are always consistent.
final class SpiralCell {
  const SpiralCell._({
    required this.n,
    required this.ring,
    required this.indexInRing,
    required this.stepsFromAxis,
    required this.angle,
    required this.x,
    required this.y,
  });

  /// The cell number, ≥ 1.
  final int n;

  /// The ring `k`: 0 for the center, otherwise `ceil((√n − 1) / 2)`.
  final int ring;

  /// The index within the ring, `j = n − (2k−1)² − 1` (0 … 8k−1); `null` for
  /// the center.
  final int? indexInRing;

  /// `i = (j − (k−1)) mod 8k`: the number of steps from the axis where 2 sits
  /// (west of the center), clockwise; `null` for the center.
  final int? stepsFromAxis;

  /// The discrete ring angle `θ = 45° · i / k` in degrees, `[0, 360)`; `null`
  /// for the center, which has no angle.
  final double? angle;

  /// Column offset from the center; positive to the right.
  final int x;

  /// Row offset from the center; positive downward.
  final int y;

  @override
  bool operator ==(Object other) =>
      other is SpiralCell &&
      other.n == n &&
      other.ring == ring &&
      other.indexInRing == indexInRing &&
      other.stepsFromAxis == stepsFromAxis &&
      other.angle == angle &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode =>
      Object.hash(n, ring, indexInRing, stepsFromAxis, angle, x, y);

  @override
  String toString() =>
      'SpiralCell(n: $n, k: $ring, j: $indexInRing, i: $stepsFromAxis, '
      'θ: $angle, x: $x, y: $y)';
}

/// The spiral cell for number [n] (spec "Gann spiral"):
///
/// ```
/// k = ceil((√n − 1) / 2),   j = n − (2k−1)² − 1,
/// i = (j − (k−1)) mod 8k,   θ = 45° · i / k
/// ```
///
/// Position: `(k, j−k+1)` when `j < 2k`; `(3k−1−j, k)` when `j < 4k`;
/// `(−k, 5k−1−j)` when `j < 6k`; otherwise `(j−7k+1, −k)`; then both signs
/// are flipped so that 2 is left of 1 and the spiral runs clockwise.
///
/// Throws [ArgumentError] if [n] is not in `1 … maxSpiralNumber`.
SpiralCell spiralCell(int n) {
  if (n < 1 || n > maxSpiralNumber) {
    throw ArgumentError.value(n, 'n', 'must be in 1…$maxSpiralNumber');
  }
  if (n == 1) {
    return const SpiralCell._(
      n: 1,
      ring: 0,
      indexInRing: null,
      stepsFromAxis: null,
      angle: null,
      x: 0,
      y: 0,
    );
  }

  final k = _ringOf(n);
  final j = n - (2 * k - 1) * (2 * k - 1) - 1;
  final i = (j - (k - 1)) % (8 * k);

  final int a, b;
  if (j < 2 * k) {
    (a, b) = (k, j - k + 1);
  } else if (j < 4 * k) {
    (a, b) = (3 * k - 1 - j, k);
  } else if (j < 6 * k) {
    (a, b) = (-k, 5 * k - 1 - j);
  } else {
    (a, b) = (j - 7 * k + 1, -k);
  }

  return SpiralCell._(
    n: n,
    ring: k,
    indexInRing: j,
    stepsFromAxis: i,
    angle: (45 * i) / k,
    x: -a,
    y: -b,
  );
}

/// The cell number at screen position ([x], [y]) relative to the center
/// (x right, y down) — the inverse of [spiralCell].
///
/// The spec defines only `n → (x, y)`; this inverts it segment by segment.
/// With `k = max(|x|, |y|)` and the flip undone, `(a, b) = (−x, −y)`:
///
/// * `a == k && b > −k` → `j = b + k − 1` (first segment);
/// * `b == k` → `j = 3k − 1 − a`;
/// * `a == −k` → `j = 5k − 1 − b`;
/// * otherwise (`b == −k`) → `j = a + 7k − 1` (last segment, which owns the
///   pre-flip corner `(k, −k)` — on screen `(−k, k)`, the ring's last cell).
///
/// Then `n = (2k − 1)² + 1 + j`; the center is 1.
///
/// Throws [ArgumentError] if `max(|x|, |y|) > maxSpiralRing`.
int spiralNumberAt(int x, int y) {
  final k = math.max(x.abs(), y.abs());
  if (k > maxSpiralRing) {
    throw ArgumentError.value(
      (x, y),
      '(x, y)',
      'ring $k is outside 0…$maxSpiralRing',
    );
  }
  if (k == 0) return 1;

  final a = -x, b = -y;
  final int j;
  if (a == k && b > -k) {
    j = b + k - 1;
  } else if (b == k) {
    j = 3 * k - 1 - a;
  } else if (a == -k) {
    j = 5 * k - 1 - b;
  } else {
    j = a + 7 * k - 1;
  }
  return (2 * k - 1) * (2 * k - 1) + 1 + j;
}

/// `ceil((√n − 1) / 2)` from the spec, corrected in integer arithmetic so a
/// rounded `sqrt` can never place a cell in the wrong ring: the result is
/// the smallest `k` with `(2k+1)² ≥ n`.
int _ringOf(int n) {
  var k = ((math.sqrt(n) - 1) / 2).ceil();
  while ((2 * k + 1) * (2 * k + 1) < n) {
    k++;
  }
  while (k > 0 && (2 * k - 1) * (2 * k - 1) >= n) {
    k--;
  }
  return k;
}

void _checkRing(int k) {
  if (k < 0 || k > maxSpiralRing) {
    throw ArgumentError.value(k, 'k', 'must be in 0…$maxSpiralRing');
  }
}

/// The number of cells in ring [k] (Appendix B): `8k`, or 1 for the center
/// (`k = 0`). Throws [ArgumentError] if [k] is not in `0 … maxSpiralRing`.
int cellsInRing(int k) {
  _checkRing(k);
  return k == 0 ? 1 : 8 * k;
}

/// The side of the square up to and including ring [k]: `2k + 1`.
/// Throws [ArgumentError] if [k] is not in `0 … maxSpiralRing`.
int squareSideForRing(int k) {
  _checkRing(k);
  return 2 * k + 1;
}

/// The last number in ring [k]: `(2k + 1)²` (ring 1 ends at 9, ring 4 at 81).
/// Throws [ArgumentError] if [k] is not in `0 … maxSpiralRing`.
int lastNumberInRing(int k) {
  _checkRing(k);
  return (2 * k + 1) * (2 * k + 1);
}
