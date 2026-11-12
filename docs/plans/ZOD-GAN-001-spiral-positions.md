# ZOD-GAN-001 — Gann Spiral Position Formulas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-GAN-001-spiral-positions` · **Written:** 2026-11-12

**Goal:** Implement the Square of Nine's core spiral math in `gann_core`. For a cell number `n`, compute its ring `k`, its index in the ring `j`, its steps from the west axis `i`, its discrete angle `θ` and its grid position `(x, y)`. Also implement the inverse, `(x, y) → n`.

**Architecture:**
- One immutable value type, `SpiralCell`, plus pure top-level functions in `packages/gann_core/lib/src/spiral/`.
- Formulas exactly as in the spec's "Gann spiral" block, with the fixed orientation of SQ-8 (2 left of 1, clockwise).
- `k` uses the spec formula and then an **integer correction**, so floating-point `sqrt` can never put a cell in the wrong ring.
- No state and no Flutter (ARCH-2).

**Tech Stack:** Dart 3.14, `dart:math`. No new dependencies.

**Spec:**
- `docs/development/computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md` (amended 2026-11-12)
- `assets/zodiann-specification.md`: "Gann spiral" (formula block), SQ-8, SQ-9, SQ-11, Appendix B, Appendix C
- `design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png`, used only to cross-check values

## Product-owner decisions (2026-11-12)

1. **GAN-001 and TST-010 stay separate**, with the same resolution as EPH-001/TST-002. GAN-001's criterion "T-GAN-1 passes" was amended to "covered by GAN-001's own unit tests; dedicated T-GAN-1 tracked by ZOD-TST-010". TST-010 gets the independence and mutation-proof rules. (GAN-001 / TST-010 task Notes.)

## Spec observation (recorded, not decided here)

T-GAN-3's prose says "the 270 axis (the row above cell 1 on screen)". The formula, SQ-8, Appendix C (90° = North, 270° = South) and the design reference ("90° N" above, "270° S" below) all put **90°** above cell 1. GAN-001 follows the formula and Appendix C. The conflict is recorded in ZOD-TST-010's Notes for a product-owner decision when TST-010 is planned. It doesn't change any GAN-001 output.

## Global Constraints

- Pure Dart in `gann_core` (ARCH-2), no new dependencies. Follow `docs/PROGRESS.md` → Architecture Conventions.
- The formulas exactly as specified:
  - `k = ceil((√n − 1)/2)`
  - `j = n − (2k−1)² − 1`
  - `i = (j − (k−1)) mod 8k`
  - `θ = 45°·i/k`
  - The position is `(k, j−k+1)` if `j < 2k`; `(3k−1−j, k)` if `j < 4k`; `(−k, 5k−1−j)` if `j < 6k`; otherwise `(j−7k+1, −k)`. Then `(x, y) ← (−x, −y)`.
  - x is positive to the right and y is positive **downward**.
- **The center** (`n = 1`): ring 0, position (0, 0), no `j`, no `i`, no angle.
- **Orientation is fixed** to SQ-8: 2 left of 1, clockwise. `SquareConfig.spiralStart` / `spiralRotation` exist in the data model, but configurable orientation is ZOD-EXT-010 and out of scope. The functions document that they implement SQ-8's fixed orientation.
- Out of scope:
  - Highlight classification blue/yellow/gray (→ GAN-002).
  - Date/number mapping (→ GAN-003).
  - T-GAN-1/2/3 dedicated suites (→ TST-010/011).
  - Drawing (→ SQR-005).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| API | `final class SpiralCell { final int n; final int ring; final int? indexInRing; final int? stepsFromAxis; final double? angle; final int x; final int y; }` with doc comments naming the spec letters `k`, `j`, `i`, `θ`. Functions: `SpiralCell spiralCell(int n)`, `int spiralNumberAt(int x, int y)`, `int cellsInRing(int k)` (= 8k), `int squareSideForRing(int k)` (= 2k+1), `int lastNumberInRing(int k)` (= (2k+1)²) | Descriptive names for consumers (GAN-002/003, SQR-*). Nullable `j`, `i` and `θ` make "the center has no angle" type-checked rather than a sentinel |
| Ring computation | The spec formula, then a correction loop: increment while `(2k+1)² < n`, decrement while `k > 0 && (2k−1)² ≥ n` | Guards against `sqrt` rounding at perfect squares. Pre-computed: the plain formula agrees with the integer definition for every n in 2…1,000,000, but the guard makes this true by construction for any n |
| Valid range | `1 ≤ n ≤ 2^53`; otherwise `ArgumentError`. `spiralNumberAt` accepts any `(x, y)` with `max(\|x\|, \|y\|) ≤ 47,453,132` (so the result fits in 2^53) | 61×61 = 3,721 is the UI maximum. Larger n may still occur in date mapping (SQ-6). 2^53 keeps `sqrt` meaningful |
| Angle type | `double` degrees: `45 * i / k`. Integer arithmetic before one division | Exact for every k dividing 45·i; otherwise the nearest double. GAN-002 classifies by `i` and `k` (integers), not by `θ` |
| Inverse algorithm (the spec gives only the forward direction) | `k = max(\|x\|, \|y\|)`; if `k == 0`, return 1. Undo the flip: `(a, b) = (−x, −y)`. Then `j = b + k − 1` if `a == k && b > −k`; else `j = 3k − 1 − a` if `b == k`; else `j = 5k − 1 − b` if `a == −k`; else (`b == −k`) `j = a + 7k − 1`. `n = (2k−1)² + 1 + j` | Each branch inverts one forward segment, and the corner (k, −k) belongs to the last segment (j = 8k−1). Round-trip tests prove it |

## File Structure

```
packages/gann_core/lib/
  gann_core.dart                     + export src/spiral/spiral.dart
  src/spiral/spiral.dart             SpiralCell, spiralCell, spiralNumberAt, cellsInRing, squareSideForRing, lastNumberInRing
packages/gann_core/test/spiral/
  spiral_test.dart
```

## Reference values (from the formula; cross-checked against the design reference)

| n | k | j | i | θ | (x, y) | Design reference |
|---|---|---|---|---|---|---|
| 2 | 1 | 0 | 0 | 0° | (−1, 0) | left of 1, blue |
| 3 | 1 | 1 | 1 | 45° | (−1, −1) | up-left, yellow |
| 4 | 1 | 2 | 2 | 90° | (0, −1) | above 1, blue ("90° N") |
| 5 | 1 | 3 | 3 | 135° | (1, −1) | |
| 6 | 1 | 4 | 4 | 180° | (1, 0) | right of 1 ("180° E") |
| 7 | 1 | 5 | 5 | 225° | (1, 1) | |
| 8 | 1 | 6 | 6 | 270° | (0, 1) | below 1 ("270° S") |
| 9 | 1 | 7 | 7 | 315° | (−1, 1) | |
| 10 | 2 | 0 | 15 | 337.5° | (−2, 1) | gray |
| 13 | 2 | 3 | 2 | 45° | (−2, −2) | yellow |
| 25 | 2 | 15 | 14 | 315° | (−2, 2) | |
| 26 | 3 | 0 | 22 | 330° | (−3, 2) | |
| 49 | 3 | 23 | 21 | 315° | (−3, 3) | "Ring 3, Angle 315°, 3 left, 3 down" |
| 81 | 4 | 31 | 28 | 315° | (−4, 4) | |
| 82 | 5 | 0 | 36 | 324° | (−5, 4) | |
| 3721 | 30 | 239 | 210 | 315° | (−30, 30) | 61×61 corner |

## Review Focus

1. **Ring boundaries:** last cell of a ring and first of the next (9/10, 25/26, 81/82, 3720/3721/3722), where `sqrt` rounding could misplace a cell. Pinned in Task 1 (boundary tests plus the integer-definition sweep).
2. **The center:** `n = 1` has no `j` / `i` / `θ`, and n ≤ 0 is rejected rather than producing garbage (`mod 0`). Pinned in Task 1.
3. **Orientation flips:** a sign error makes the spiral counter-clockwise or puts 2 on the right. Pinned in Task 1 by explicit positions for 2–9 and a geometric clockwise check, independent of `i`, for every cell in rings 1–6.
4. **The inverse at corners and edges:** each segment boundary and corner (k, −k), (k, k), (−k, k), (−k, −k). Pinned in Task 2 by a full round-trip over the 61×61 square in both directions.
5. **Large n:** the integer correction keeps `k` right where `sqrt` loses precision, and inputs above 2^53 are rejected. Pinned in Task 1.

---

### Task 1: `spiralCell(n)` and the ring helpers (TDD)

**Files:** create `gann_core/lib/src/spiral/spiral.dart`; modify `gann_core/lib/gann_core.dart`; test `gann_core/test/spiral/spiral_test.dart`.

**Interfaces (produced):**
- `SpiralCell spiralCell(int n)`
- `int cellsInRing(int k)`, `int squareSideForRing(int k)`, `int lastNumberInRing(int k)` (each `ArgumentError` for `k < 0`; `cellsInRing(0)` is 1, for the center)
- `SpiralCell` has value equality and `toString`.

- [ ] **Step 1: Write the failing tests** (`group('spiralCell')`, `group('ring helpers')`):
  - `'center: n = 1 is ring 0 at (0, 0) with no index, steps or angle'`.
  - `'rejects n < 1 and n > 2^53'`: inputs 0, −5, `(1 << 53) + 1` → `throwsArgumentError`.
  - `'matches the reference table'`: every row of the Reference values table (k, j, i, θ, x, y).
  - `'cell 2 is left of cell 1 and the first ring runs clockwise: left, up, right, down'`: positions of 2–9 in order, as in the table.
  - `'every ring 1–6 runs clockwise on screen'`. For each ring, take the cells in number order and compute the geometric screen angle `ψ = (180 − atan2(−y, x)·180/π) mod 360` (west = 0°, north = 90°, with y down). `ψ` must strictly increase from the ring's first cell to its last, with one wrap through 360 at most.
  - `'θ equals the geometric angle on axes and diagonals'`: for every cell in rings 1–6 with `i mod k == 0`, `θ == ψ`.
  - `'consecutive cells are grid neighbours'`: for n = 1…3720, `|Δx| + |Δy| == 1` between n and n+1.
  - `'ring boundaries'`: rings of 9, 10, 25, 26, 81, 82, 3721, 3722 are 1, 2, 2, 3, 4, 5, 30, 31.
  - `'ring agrees with the integer definition'`: for n = 2…200,000, `ring == smallest k with (2k+1)² ≥ n`. Also for a few large n near perfect squares: `(2·10⁷+1)²` and that value ± 1.
  - Ring helpers per Appendix B for k = 1…6: `cellsInRing` 8, 16, 24, 32, 40, 48; `squareSideForRing` 3…13; `lastNumberInRing` 9, 25, 49, 81, 121, 169. Ring 1 ends at 9 and ring 4 at 81 (AC 2). Negative k → `throwsArgumentError`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/spiral`. Expected: compilation FAIL (`spiralCell` and the others are undefined).
- [ ] **Step 3: Implement** per Interfaces and the decision table, with doc comments that cite the spec formula and SQ-8/SQ-11.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat(ZOD-GAN-001): implement spiral position formulas (k, j, i, θ, x, y)`.

### Task 2: Inverse mapping `spiralNumberAt(x, y)` (TDD)

**Files:** modify `gann_core/lib/src/spiral/spiral.dart`; test `gann_core/test/spiral/spiral_test.dart`.

**Interfaces:**
- Consumes `spiralCell` (Task 1).
- Produces `int spiralNumberAt(int x, int y)`: `ArgumentError` if `max(|x|, |y|) > 47453132`.

- [ ] **Step 1: Write the failing tests** (`group('spiralNumberAt')`):
  - `'center and the first ring'`: `(0, 0)` → 1, `(−1, 0)` → 2, `(0, −1)` → 4, `(1, 0)` → 6, `(0, 1)` → 8, `(−1, 1)` → 9.
  - `'design reference spot values'`: `(−2, −2)` → 13, `(−3, 3)` → 49, `(−4, 4)` → 81.
  - `'corners of ring k map to the expected segments'`: for k = 1…5, `(k, −k)` (after the flip, the last cell of the ring) → `(2k+1)²`; the other three corners → `spiralCell(n)` with matching position.
  - `'round-trips with spiralCell for every cell of a 9×9 square'` (AC 3). For n = 1…81, `spiralNumberAt(spiralCell(n).x, spiralCell(n).y) == n`. For every (x, y) in [−4, 4]², `spiralCell(spiralNumberAt(x, y))` has that (x, y).
  - `'round-trips over the full 61×61 square'`: the same in both directions for n = 1…3721 and (x, y) in [−30, 30]².
  - `'rejects coordinates outside the supported range'`: `(47453133, 0)` → `throwsArgumentError`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/spiral`. Expected: compilation FAIL (`spiralNumberAt` is undefined).
- [ ] **Step 3: Implement** the inverse algorithm from the decision table, with a doc comment on the segment mapping.
- [ ] **Step 4:** Same command, then `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: all PASS / exit 0.
- [ ] **Step 5:** Commit `feat(ZOD-GAN-001): add the inverse mapping (x, y) → n`.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch code review (`requesting-code-review`), then resolve any important findings. Re-run lint and test (`verification-before-completion`).
- [ ] **Step 2:**
  - Set `Status: Done` in the GAN-001 task file and `TASKS.md`, and tick its acceptance criteria. (The GAN-001 / TST-010 notes are already committed in the planning commit.)
  - Update `docs/PROGRESS.md`: completed task, decisions, conventions (spiral API, fixed SQ-8 orientation), verification, next task.
- [ ] **Step 3:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as amended 2026-11-12) | Proven by |
|---|---|
| Spiral position formulas implemented and covered by GAN-001's own unit tests (2 left of 1, clockwise, Appendix B ring ends, 9×9 round-trip); dedicated T-GAN-1 tracked by TST-010 | Task 1: reference table, first-ring order, geometric clockwise check for rings 1–6, neighbour adjacency. Tasks 1–2 overall |
| Ring 1 has last number 9, ring 4 has last number 81 (Appendix B) | Task 1 ring-helper tests (all six Appendix B rows) and ring-boundary tests |
| The (x, y) mapping round-trips with the forward mapping for every cell in a 9×9 square | Task 2 9×9 round-trip in both directions (plus 61×61) |

## Risks

- **Configurable spiral start and rotation** (EXT-010) will need these functions parameterised. They're fixed now and documented as SQ-8's orientation, so EXT-010 can generalise them.
- **The T-GAN-3 wording conflict** is recorded for TST-010 (see "Spec observation").
