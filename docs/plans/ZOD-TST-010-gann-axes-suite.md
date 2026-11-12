# ZOD-TST-010 — T-GAN-1 / T-GAN-3 Spiral and Axes Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: 2 rounds, Approve), approved and implemented 2026-11-12 (see PROGRESS.md) · **Branch:** `task/ZOD-TST-010-gann-axes-suite` (from `main` @ `c5e442f`) · **Written:** 2026-11-12

**Goal:** Verify, independently of production, the spiral's direction and positions (T-GAN-1: 2 left of 1, clockwise, explicit coordinates) and the Appendix C axis and diagonal assignments (T-GAN-3: 0/90/180/270 blue, with 90° above cell 1 and 270° below; only 45/135/225/315 yellow). Back this with a mutation proof that catches a flipped direction or a moved cell.

**Architecture:**
- **Test-only deliverable.** Two suites in `packages/gann_core/test/accuracy/`:
  - `t_gan_1_spiral_test.dart`
  - `t_gan_3_axes_test.dart`

  They follow the PROGRESS "Accuracy tests" convention. There are no production changes.
- **Independent expectations:**
  - **Literal coordinates** for the full 13×13 square (169 cells), transcribed from the design reference `design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png`.
  - **Geometric properties** computed from (x, y) alone, never from the production `i`, `k` or `θ` formulas:
    - unit steps;
    - a positive clockwise cross product;
    - the ring entry and exit corners;
    - ray membership (`x == 0`, `y == 0`, `|x| == |y|`).
  - **Literal Appendix C rows:** angle, direction vector, type.
  - **Literal lists** of the design's 24 blue and 24 yellow cells.
- Orientation is pinned **through the forward mapping** `spiralCell(n)`, never by routing through `spiralNumberAt` or through category alone, per the PROGRESS carry note from GAN-002: classification is invariant under mirroring and rotation.

**Tech Stack:** Dart 3.14, `package:test` (existing dev dependency). No new dependencies.

**Spec:**
- `docs/development/testing-qa/ZOD-TST-010-author-the-gann-spiral-direction-test-suite-t-gan-1-t-gan-3.md` (Notes dated 2026-11-12)
- `assets/zodiann-specification.md`:
  - T-GAN-1 (line 658);
  - T-GAN-3 (line 660, with the "270 above" wording corrected by the product-owner decision);
  - SQ-8, SQ-9 and SQ-11 (lines 158–164);
  - Appendix C (line 787).
- Design: `02-square-of-nine_numbers_desktop_en_dark.png` (13×13 numbers, "90° N" above and "270° S" below; blue, yellow and gray cells).

## Product-owner decisions already in force (2026-11-12)

1. **TST-010 owns the dedicated T-GAN-1 / T-GAN-3 verification**, because the GAN-001 and GAN-002 criteria point here. The TST-010 Notes set two conditions:
   - expected coordinates come from an independent source (literals and/or the design reference);
   - the suite needs a mutation proof showing that a flipped direction or a moved cell fails.
2. **T-GAN-3 wording:** 90° is the axis above cell 1 and 270° the axis below. The spec's "270 above" is a typo (TST-010 / GAN-002 Notes, PROGRESS decisions).

No new product decisions are needed.

## Global Constraints

- **Test-only.** No file under `lib/` changes. Pure Dart; the ARCH-2 guard stays green.
- **Independence:**
  - Import with `show spiralCell, spiralNumberAt` (T-GAN-1) and `show spiralCell, classifyHighlight, HighlightCategory` (T-GAN-3).
  - Expected values never use `stepsFromAxis`, `indexInRing`, `ring` or any production formula.
  - `cell.angle` is only *compared against* literals.
- **Out of scope:**
  - The per-ring blue/yellow/gray counts of T-GAN-2 (ZOD-TST-011).
  - Rendering, colour tokens and the legend (SQR tasks).
  - Configurable start or direction (ZOD-EXT-010).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| "First ~40 cells" | All **169** cells of the design's 13×13 square as a literal `const` grid (rows top to bottom, columns left to right; position `(col − 6, row − 6)`) | More than the criterion requires, and taken from the design reference, so it is independent of the formula. The transcription was checked by a scratch run (0 mismatches against `main` @ `c5e442f`) |
| Clockwise beyond the grid | For every n in 1…3720, cells n and n+1 are one unit step apart (`|Δx| + |Δy| == 1`, ring changes included). When `max(|x|, |y|)` is equal for both cells (decided **geometrically**, never via production `ring`), the cross product `x₁·y₂ − y₁·x₂ > 0` (clockwise on screen, y down). The test also asserts that exactly 3690 same-ring pairs were checked (3719 pairs from 2…3720, minus 29 ring changes), so it cannot pass vacuously | T-GAN-1's "moves clockwise", proven across the largest square with geometry only. The scratch run found 0 violations |
| Ring corners | For k = 1…30: cell `(2k−1)²+1` is at `(−k, k−1)` (the entry, just below the west axis), and cell `(2k+1)²` is at `(−k, k)` (the exit, the south-west corner) | SQ-9's "the last cell in ring k is (2k+1)²", placed on screen. A rotated, mirrored or shifted spiral fails here at every ring |
| Appendix C rows | `(0, (−1, 0), axis)`, `(45, (−1, −1), diagonal)`, `(90, (0, −1), axis)`, `(135, (1, −1), diagonal)`, `(180, (1, 0), axis)`, `(225, (1, 1), diagonal)`, `(270, (0, 1), axis)`, `(315, (−1, 1), diagonal)`. Directions use x right, y down: W, NW, N, NE, E, SE, S, SW | The table, transcribed. 90° N is above (`y < 0`), per the decision |
| Ray cells | Walk n = 2…3721 forward. A cell lies on a row's ray when `(x, y) = m·(dx, dy)` with `m = max(|x|, |y|)`. For it, assert `angle == row angle` and `category == row type`. **Negative:** `isNot` each of the other two categories. Each of the 8 rays has exactly 30 cells | Positive and negative assertions per Appendix C row (criterion 2), using forward mapping only |
| "Only" | For every n in 2…3721: `diagonal` ⇔ `|x| == |y|`, and `axis` ⇔ exactly one of x, y is 0. Also assert: `angle ∈ {45, 135, 225, 315}` ⇔ diagonal, and `angle ∈ {0, 90, 180, 270}` ⇔ axis | T-GAN-3's "only 45, 135, 225, 315 are yellow": no other cell is yellow, and no cell off an axis is blue |
| Design highlight literals | Blue: N `4, 15, 34, 61, 96, 139`; W `2, 11, 28, 53, 86, 127`; E `6, 19, 40, 69, 106, 151`; S `8, 23, 46, 77, 116, 163`. Yellow: NW `3, 13, 31, 57, 91, 133`; NE `5, 17, 37, 65, 101, 145`; SE `7, 21, 43, 73, 111, 157`; SW `9, 25, 49, 81, 121, 169`. Each is checked for its category and for its literal angle per direction. Cell numbers come from the image; the per-direction angles come from Appendix C (the image labels the axes, and shows 315° SW for cell 49) | Read from the design image. The scratch run confirmed all 48 |

## File Structure

```
packages/gann_core/test/accuracy/
  t_gan_1_spiral_test.dart    T-GAN-1: literal 13×13 design grid, 2 left of 1, clockwise (geometric), ring corners
  t_gan_3_axes_test.dart      T-GAN-3: Appendix C rows on rays (positive + negative), "only", design highlight literals
```

## Review Focus

1. **Orientation hidden by category:** a mirrored or rotated spiral keeps every category the same. T-GAN-3 therefore pins **angles** and **(x, y) rays** from the forward mapping, and T-GAN-1 pins literal coordinates. (Mutants S1–S4, C3.)
2. **"270 above" regression:** if angles were mirrored (`360 − θ`), N would read 270 and S 90 while categories stay unchanged. The ray-angle literals catch this. (Mutant C3.)
3. **A single moved cell:** only a per-cell literal comparison catches it, and the 169-cell grid is that comparison. (Mutant S5.)
4. **Wrong highlight in the outer rings only:** the rays run to ring 30 (61×61), beyond the design grid. (Mutants S6, C1, C2, C4.)
5. **A self-confirming oracle:** "same ring" is geometric (`max(|x|, |y|)`), not production `ring`, and no expectation uses `i`, `j` or `k`.

## Tasks

TDD note: production already exists, so each suite is expected to pass on its first run. The RED evidence is the mutation proof in Task 2.

### Task 1: The two suites

**Files:** create the two test files above.

**Interfaces** (from GAN-001 and GAN-002):
- `SpiralCell spiralCell(int n)`, with fields `x`, `y`, `angle` (`double?`) and `isCenter`;
- `int spiralNumberAt(int x, int y)`;
- `HighlightCategory? classifyHighlight(SpiralCell)`, with `HighlightCategory.axis`, `.diagonal` and `.eighth`.

- [ ] **Step 1: Write `t_gan_1_spiral_test.dart`.**
  - **Header:** independence rules; the grid's provenance (the design image path, transcribed); and the axis convention (x right, y down).
  - **Grid** (rows top to bottom, transcribed from the design image; independently re-transcribed by the plan reviewer, with 0 differences):
    ```
    [133,134,135,136,137,138,139,140,141,142,143,144,145],
    [132, 91, 92, 93, 94, 95, 96, 97, 98, 99,100,101,146],
    [131, 90, 57, 58, 59, 60, 61, 62, 63, 64, 65,102,147],
    [130, 89, 56, 31, 32, 33, 34, 35, 36, 37, 66,103,148],
    [129, 88, 55, 30, 13, 14, 15, 16, 17, 38, 67,104,149],
    [128, 87, 54, 29, 12,  3,  4,  5, 18, 39, 68,105,150],
    [127, 86, 53, 28, 11,  2,  1,  6, 19, 40, 69,106,151],
    [126, 85, 52, 27, 10,  9,  8,  7, 20, 41, 70,107,152],
    [125, 84, 51, 26, 25, 24, 23, 22, 21, 42, 71,108,153],
    [124, 83, 50, 49, 48, 47, 46, 45, 44, 43, 72,109,154],
    [123, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73,110,155],
    [122,121,120,119,118,117,116,115,114,113,112,111,156],
    [169,168,167,166,165,164,163,162,161,160,159,158,157],
    ```
  - **Tests:**
    - `'cell 1 is the center and cell 2 is directly left of it'`: `(0, 0)` and `(−1, 0)`.
    - `'all 169 cells of the 13×13 design reference'`: every grid cell's `spiralCell(n)` equals `(col − 6, row − 6)`. Also assert that the grid holds each of 1…169 exactly once, as a check on the transcription.
    - `'the inverse agrees on the design grid'`: `spiralNumberAt(col − 6, row − 6) == grid[row][col]`.
    - `'moves clockwise, one step at a time, through 61×61'`: the unit step for every pair from 1→2 to 3720→3721, and the cross product for the 3690 same-ring pairs (count asserted).
    - `'ring k is entered at (−k, k−1) and left at (−k, k), for k = 1…30'`.
- [ ] **Step 2: Write `t_gan_3_axes_test.dart`.**
  - **Header:** independence rules; and the decision that 90° is above.
  - **Tests:**
    - `'Appendix C: <angle>° <direction> is <type>'`: one test per row (8 tests). Each covers the ray walk with positive and negative assertions and asserts that the ray has 30 cells.
    - `'only the diagonals are yellow and only the axes are blue (61×61)'`.
    - `'the design reference highlights'`: the 48 literal cells, with category and per-direction literal angle.
    - `'every angle is in [0, 360) (Appendix C: 360 is 0)'`: for n = 2…3721, `cell.angle` is not null and `0 <= angle < 360`.
- [ ] **Step 3: Run the suites.**
  - Run: `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy`
  - Expected: `All tests passed!`. The new files add 5 tests (T-GAN-1) and 11 tests (T-GAN-3: 8 rows, "only", design, angle range).
  - If a test fails, re-derive the expectation by hand from the design image or the spec.
    - If the test is wrong, fix it and record a ruling.
    - If production is wrong, stop and report it to the user as a GAN-001/002 defect.
    - Never edit `lib/`, and never change an expectation to match production.
- [ ] **Step 4: Run the gates:** `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: exit 0.

### Task 2: Mutation proof

- [ ] **Step 1: Run the mutants.** Copy `packages/gann_core/lib/src/spiral/spiral.dart` and `packages/gann_core/lib/src/highlight/highlight_classification.dart` to the session scratch directory. Then for each mutant:
  - apply it;
  - run the Task 1 Step 3 command;
  - confirm **test failures, not compile errors**, and record the failing-test count and which suite failed;
  - restore the file.

  At the end, confirm that `git diff --exit-code -- packages/gann_core/lib` exits 0.

  | # | Mutant | Must fail (at least) |
  |---|---|---|
  | S1 | mirrored x: `x: a` (2 right of 1) | T-GAN-1 grid, cell 2, clockwise, corners; T-GAN-3 rays (W/E angles) |
  | S2 | mirrored y: `y: b` (counter-clockwise) | T-GAN-1 grid, clockwise, corners; T-GAN-3 rays (N/S angles) |
  | S3 | no flip: `x: a, y: b` | T-GAN-1 grid, cell 2; T-GAN-3 rays |
  | S4 | 90° rotation: `x: b, y: −a` | T-GAN-1 grid, cell 2; T-GAN-3 rays |
  | S5 | one moved cell: cell 40 placed one row lower (`y: n == 40 ? −b + 1 : −b`) | T-GAN-1 grid |
  | S6 | steps off by one: `i = (j − k) % (8 * k)` | T-GAN-3 rays, design highlights |
  | S7 | index off by one: `j = n − (2k−1)²` (missing `− 1`) | T-GAN-1 grid, corners |
  | S8 | segment boundary: `j < 2 * k` → `j <= 2 * k` | T-GAN-1 grid, clockwise (unit step); T-GAN-3 N ray, "only" |
  | S9 | `%` → `remainder`: `i = (j − (k−1)).remainder(8 * k)` | T-GAN-3 angle range |
  | C1 | axis rule `i % (2 * k)` → `i % k` (diagonals turn blue) | T-GAN-3 diagonal rays (NW/NE/SE/SW), "only", design |
  | C2 | priority swapped: the diagonal check before the axis check | T-GAN-3 rays, "only", design |
  | C3 | mirrored angle: `angle: (360 − 45 * i / k) % 360` ("270 above") | T-GAN-3 ray angles, design angles |
  | C4 | diagonal rule `i % k` → `(2 * i) % k` (eighths turn yellow) | T-GAN-3 "only" |

- [ ] **Step 2: Commit** the two suites as `test(ZOD-TST-010): T-GAN-1 spiral and T-GAN-3 axes suites; mutation proof S1–S9, C1–C4`. The body lists each mutant with its failing-test count and the suites that failed, then "All restored; lib/ unchanged." This is the same pattern as `4e9c991`: the proof runs before the suites are committed, so nothing else needs a commit.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1: Code review.** Run a whole-branch review (`requesting-code-review`, a fresh reviewer on the most capable model). Re-grade the findings, then fix the important ones test-first.
- [ ] **Step 2: Documentation.**
  - In the TST-010 task file, set `Status: Done` and tick both criteria.
  - Set the `TASKS.md` row to Done.
  - Update `docs/PROGRESS.md`: completed row, verification (including the mutant table), and Current / Next task.
- [ ] **Step 3: Publish.** Commit, push and open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| T-GAN-1 passes against explicit expected (x, y) coordinates for the first ~40 cells | All 169 cells of the 13×13 design grid as literals; 2 at (−1, 0); geometric clockwise to 61×61; ring corners for k ≤ 30; mutants S1–S5, S7, S8 |
| T-GAN-3 passes for every angle in Appendix C's table, both the positive (is this colour) and negative (is not another colour) assertions | 8 per-row tests over the 30-cell rays (positive category and angle; `isNot` the other two); "only" over 61×61; 48 design literals; angle range in [0, 360); mutants C1–C4, S6, S9 |

## Risks

- **Transcription error in the 169-cell grid:** self-checked (each number exactly once), and the scratch run confirms it against production. Production was itself checked against the same image in GAN-001.
- **Floating-point `angle` comparisons:** ray angles are exact multiples (`45·i/k` with `i` a multiple of `k`), so comparing with `==` against literal doubles is safe. The scratch run returned exact `0.0 … 315.0`.

## Plan review

**Round 1: Approve after corrections.** The reviewer re-transcribed the design grid independently (0 differences) and ran every planned test and mutant in a scratch harness.
- **I1 (Important), applied.** The clockwise test skipped cross-ring pairs, so S8 escaped it. The test now checks the unit step for every pair and the cross product for same-ring pairs, and asserts the count of 3690.
- **I2 (Important), applied.** The 169-cell grid literal is now in the plan.
- **I3 (Important), applied.** The Task 2 commit had no changes. The mutation proof now runs before the suites are committed, following the TST-012/013 pattern.
- **I4 (Important), applied.** The carried `%` → `remainder` mutant survived. Added the test "every angle is in [0, 360)" and mutant S9.
- **Minors M1–M5, applied:**
  - "Must fail (at least)";
  - "Also assert:";
  - the task-file path;
  - the angle provenance note;
  - the expected test counts.

**Round 2: Approve.** The harness, re-run on the revised tests, found:
- production passes all 16 planned tests;
- 3690 same-ring pairs are checked;
- every mutant S1–S9 and C1–C4 fails at least the tests its row lists. S9 is caught only by the angle-range test.

Minor M1 (the C1 row wording: the negative assertions can't fail on their own, so C1 is caught by the positive check on the diagonal rays) is applied. No open items and no user decisions.

