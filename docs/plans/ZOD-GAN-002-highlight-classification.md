# ZOD-GAN-002 — Gann Highlight Classification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-GAN-002-highlight-classification` · **Written:** 2026-11-12

**Goal:** Classify every Square of Nine cell into blue (axis), yellow (diagonal) or gray (eighth), or none, exactly as the spec defines it. Do it in strict priority order, using float-free integer arithmetic on the spiral's `i` and `k`. Then link each category to its default highlight rule, so the UI and export take colors from the square's rules.

**Architecture:**
- A small `HighlightCategory` enum and a pure function `classifyHighlight(SpiralCell)` in `packages/gann_core/lib/src/highlight/`.
- It consumes ZOD-GAN-001's `SpiralCell`.
- A tiny lookup, `highlightRuleFor`, maps a category to the matching rule in a square's `highlights` list (FND-012), by default rule id.
- A convenience getter `SpiralCell.isCenter` is added for consumers (a GAN-001 review recommendation).

**Tech Stack:** Dart 3.14. No new dependencies.

**Spec:**
- `docs/development/computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md` (amended 2026-11-12)
- `assets/zodiann-specification.md`: "Gann spiral" (blue / yellow / gray rules), SQ-11 … SQ-15, Appendix B, Appendix C
- `design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png` (cross-check)

## Product-owner decisions (2026-11-12)

1. **Cycle resolution, same as EPH-001 / GAN-001.** The "T-GAN-2 passes" and "T-GAN-3 passes" criteria were amended to "covered by GAN-002's own unit tests; dedicated T-GAN-2 / T-GAN-3 tracked by ZOD-TST-011 / ZOD-TST-010". TST-011's notes got the independence and mutation-proof rules.
2. **Fixed classifier.** GAN-002 implements exactly the spec's integer tests and maps categories to the default rule ids (`axes` / `diagonals` / `eighths`). Evaluating arbitrary user rules is ZOD-EXT-008 (recorded in its notes).
3. **T-GAN-3 wording** (decided during GAN-001): 90° is the cells straight above cell 1 (x = 0, y < 0), and 270° straight below. Both are blue.

## Global Constraints

- Pure Dart in `gann_core` (ARCH-2). No new dependencies. Follow `docs/PROGRESS.md` → Architecture Conventions, including "Square of Nine spiral": classify on the integers `i` and `k`, never on the `double` angle.
- The rules, exactly:
  - **Blue (axis):** `i mod 2k = 0`.
  - **Yellow (diagonal):** `i mod k = 0` and not blue.
  - **Gray (eighth):** `2i mod k = 0` and not blue or yellow.
  - **Priority:** blue, then yellow, then gray. No match means unhighlighted.
  - **The center** (n = 1) has no angle and is never classified (it gets its own amber marker elsewhere).
- Out of scope:
  - Drawing / fills / marks (→ SQR-006/007).
  - The center and today markers (→ SQR-008/009).
  - User-defined rules (→ EXT-008).
  - Dedicated T-GAN-2/3 suites (→ TST-011/010).
  - Excel conditional formatting (→ XLS-004).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| API | `enum HighlightCategory { axis, diagonal, eighth }`, plus `String get defaultRuleId` (`'axes'` / `'diagonals'` / `'eighths'`). `HighlightCategory? classifyHighlight(SpiralCell cell)` returns `null` for the center or a cell matching no rule | The names match the design reference's legend ("Axes", "Diagonals", "Eighths") and FND-012's default rule ids. A nullable result makes "no highlight" explicit |
| Rule lookup | `HighlightRule? highlightRuleFor(HighlightCategory category, List<HighlightRule> rules)` returns the rule whose `id == category.defaultRuleId`, or `null` if absent | Colors come from the square's rules (`colorToken`), not from code. `null` (the rule is missing) means the UI shows no highlight for that category, which is a safe default for future EXT-008 edits |
| `SpiralCell.isCenter` | `bool get isCenter => n == 1;` added to GAN-001's `SpiralCell` | Lets consumers branch before reading the nullable `i` / `θ`. A GAN-001 review recommendation, small and additive |
| Implementation | Integer arithmetic only: `i % (2*k) == 0`, `i % k == 0`, `(2*i) % k == 0`, using `cell.stepsFromAxis!` and `cell.ring` after an `isCenter` check | Exact for every ring up to `maxSpiralRing`: no floating point, and `2*i < 16k` fits easily in int64 |

## Independent oracles (pre-verified on 61×61, 0 mismatches)

- **Geometric:** for every non-center cell (x, y):
  - axis ⇔ `x == 0 || y == 0`;
  - otherwise diagonal ⇔ `|x| == |y|`;
  - otherwise eighth ⇔ `|x| == 2|y| || |y| == 2|x|`;
  - otherwise none.

  This is independent of `i` and `k`, and matches the design reference's blue cross, yellow diagonals and gray cells.
- **Appendix B:** odd rings have 4 axis, 4 diagonal, 0 eighth. Even rings have 4 / 4 / 8. Rings 1–4 (9×9) total 16 / 16 / 16.
- **Default-rule angles (FND-012):** axes `[0, 90, 180, 270]`, diagonals `[45, 135, 225, 315]`, eighths multiples of 22.5. Evaluated in the test on the cell's θ with a 1e-9 tolerance and lowest priority winning, they must give the same category as the classifier for every cell. This ties the data-model defaults to the classifier.

## File Structure

```
packages/gann_core/lib/
  gann_core.dart                               + export src/highlight/highlight_classification.dart
  src/highlight/highlight_classification.dart  HighlightCategory, classifyHighlight, highlightRuleFor
  src/spiral/spiral.dart                       + SpiralCell.isCenter
packages/gann_core/test/highlight/
  highlight_classification_test.dart
packages/gann_core/test/spiral/spiral_test.dart  + isCenter test
```

## Review Focus

1. **Priority order:** an axis cell also satisfies the diagonal and eighth tests (`i = 0` divides everything), and a diagonal cell satisfies the eighth test. The classifier must return the highest-priority category. Pinned in Task 1 by explicit multi-match cells and a mutation proof (swapping the order fails).
2. **Odd rings must have no gray:** `2i mod k = 0` with odd k only holds where `i mod k = 0`. Pinned in Task 1 (Appendix B per-ring counts, rings 1–6).
3. **Center and no-match** must both give `null`, never a default category. Pinned in Task 1.
4. **The 90° axis is the column straight above cell 1** (T-GAN-3, as decided), not the row y = −1. Pinned in Task 1 by the geometric oracle and explicit cells (4, 15, 34 blue; 3 and 5 yellow; 14 and 16 not axis).
5. **Divergence between FND-012's default rules and the classifier**, for example someone editing `defaultHighlightRules`. Pinned in Task 1 by the default-rule-angle equivalence over 61×61.

---

### Task 1: `HighlightCategory`, `classifyHighlight`, `highlightRuleFor`, `SpiralCell.isCenter` (TDD)

**Files:**
- Create `packages/gann_core/lib/src/highlight/highlight_classification.dart`.
- Modify `packages/gann_core/lib/src/spiral/spiral.dart` and `packages/gann_core/lib/gann_core.dart`.
- Tests: `packages/gann_core/test/highlight/highlight_classification_test.dart`, `packages/gann_core/test/spiral/spiral_test.dart`.

**Interfaces:**
- Consumes `SpiralCell` / `spiralCell` / `spiralNumberAt` (GAN-001) and `HighlightRule` / `defaultHighlightRules` / `AnglesMatch` / `MultipleOfMatch` (FND-012).
- Produces `HighlightCategory` (+ `defaultRuleId`), `classifyHighlight` and `highlightRuleFor`, as in the decision table, and `SpiralCell.isCenter`.

- [ ] **Step 1: Write the failing tests.** `group('classifyHighlight')`:
  - `'the center is never classified'`: `classifyHighlight(spiralCell(1))` is `null`.
  - `'Appendix C directions on the first ring'`:
    - 2 (west, 0°) is axis;
    - 3 (NW, 45°) diagonal;
    - 4 (north, 90°, straight above cell 1) axis;
    - 5 (NE) diagonal;
    - 6 (east) axis;
    - 7 (SE) diagonal;
    - 8 (south, 270°, straight below) axis;
    - 9 (SW) diagonal.
  - `'the 90° axis is the column straight above cell 1, not the row y = −1'`:
    - `(0, -1)`, `(0, -2)`, `(0, -3)` → cells 4, 15, 34 → axis;
    - `(−1, −1)`, `(1, −1)` → 3, 5 → diagonal;
    - `(−1, −2)`, `(1, −2)` → 14, 16 → eighth, never axis.
  - `'matches the geometric oracle for every cell of a 61×61 square'`: for each (x, y) in [−30, 30]² except the center, the category from `classifyHighlight(spiralCell(spiralNumberAt(x, y)))` equals the oracle above.
  - `'Appendix B: odd rings 4/4/0, even rings 4/4/8 (rings 1–6)'`: count per ring for k = 1…6.
  - `'a 9×9 square has 16 blue, 16 yellow and 16 gray'`: rings 1–4 (n = 2…81).
  - `'priority: blue before yellow before gray'`:
    - cell 2 (i = 0, divisible by everything) → axis, not diagonal or eighth;
    - cell 13 (ring 2, i = 2 = k: it satisfies both the yellow and gray tests) → diagonal, not eighth;
    - cell 12 (ring 2, i = 1: gray only) → eighth;
    - cell 26 (ring 3, i = 22: no rule) → `null`.
  - `'agrees with the default rules' angles (FND-012) on every cell of 61×61'`. In the test, evaluate `defaultHighlightRules` on `cell.angle` (`AnglesMatch`: any angle within 1e-9; `MultipleOfMatch`: `angle / degrees` within 1e-9 of an integer), lowest priority first. The matched rule's id must equal `classifyHighlight(cell)?.defaultRuleId`.

  `group('HighlightCategory')`:
  - `'defaultRuleId maps to the FND-012 default rule ids'`: axis → `'axes'`, diagonal → `'diagonals'`, eighth → `'eighths'`.

  `group('highlightRuleFor')`:
  - `'finds the default rule for each category'`: in `defaultHighlightRules`, it finds `colorToken` `axis` / `diag` / `eighth`.
  - `'returns null when the square has no rule for the category'`: an empty list, and a list without `eighths`.

  `spiral_test.dart`: `'isCenter is true only for n = 1'`, checking cells 1, 2 and 81.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/highlight test/spiral`. Expected: compilation FAIL (`classifyHighlight`, `HighlightCategory`, `highlightRuleFor` and `isCenter` are undefined).
- [ ] **Step 3: Implement** per the Interfaces and the decision table. The doc comments cite the spec rules (SQ-12 … SQ-15) and the EXT-008 boundary.
- [ ] **Step 4:** Same command, then `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: all PASS / exit 0.
- [ ] **Step 5: Mutation proof** (priority, AC 3). Temporarily make each change below in `classifyHighlight`, confirm the suite FAILS each time, then restore and check that `git diff packages/gann_core/lib` shows only the intended changes:
  - (a) swap the yellow and gray checks;
  - (b) check yellow before blue;
  - (c) change `2*k` to `k` in the blue test.

  Record the results in the commit message.
- [ ] **Step 6:** Commit `feat(ZOD-GAN-002): classify Square of Nine highlights (axis/diagonal/eighth)`.

### Task 2: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch code review (`requesting-code-review`), then resolve any important findings. Re-run lint and test (`verification-before-completion`).
- [ ] **Step 2:**
  - Set `Status: Done` in the GAN-002 task file and `TASKS.md`, and tick its acceptance criteria. (The GAN-002, TST-011 and EXT-008 notes are committed in the planning commits.)
  - Update `docs/PROGRESS.md`: completed task, decisions, conventions (`classifyHighlight` and `highlightRuleFor` as the single source of highlight categories and colors), verification, next task.
- [ ] **Step 3:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as amended 2026-11-12) | Proven by |
|---|---|
| Implemented and covered by own unit tests: 9×9 totals 16/16/16; Appendix B per-ring counts; T-GAN-2 → TST-011 | Task 1: 9×9 totals test, Appendix B rings 1–6 test, geometric oracle over 61×61 |
| Own unit tests cover axes and diagonals per Appendix C (90° straight above, 270° straight below, only 45/135/225/315 yellow); T-GAN-3 → TST-010 | Task 1: first-ring directions, the column-above test, geometric oracle (diagonals exactly at \|x\| = \|y\|) |
| Priority order verified with multi-match cells | Task 1: the priority test (cells 2, 13, 12, 26) and mutation proof (a)–(c) |

## Risks

- **EXT-008 rule evaluation:** user rules on arbitrary angles need exact matching on θ = 45°·i/k. Recorded in EXT-008's notes. The default-rule equivalence test here shows today's defaults match the fixed classifier.
- **A square missing a default rule:** `highlightRuleFor` returns `null`, so no highlight is shown. Defined behaviour, with no crash.
