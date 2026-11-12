# ZOD-TST-011 — T-GAN-2 Ring Counts Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: 2 rounds, Approve), awaiting approval · **Branch:** `task/ZOD-TST-011-gann-ring-counts-suite` (from `main` @ `3a447d5`) · **Written:** 2026-11-12

**Goal:** Verify, independently of production, the blue / yellow / gray counts per ring and the 9×9 total (T-GAN-2) against Appendix B's literal ring table. Back it with a mutation proof that catches any changed classification rule or priority order.

**Architecture:**
- **Test-only deliverable:** one suite, `packages/gann_core/test/accuracy/t_gan_2_ring_counts_test.dart`, following the PROGRESS "Accuracy tests" convention. No production changes.
- **Expectations are literal, from the spec:**
  - Appendix B's table rows 1–6, every column: cells in ring, angle per cell, blue, yellow, gray, square side, last number.
  - T-GAN-2's own sentence: "each ring has exactly four blue cells, four yellow, and in even rings also eight gray". This covers rings 7–30 (61×61), with 0 gray in odd rings, stated directly by the parity table after SQ-15 and by Appendix B rows 1, 3 and 5.
  - Appendix B's 9×9 total of 16 / 16 / 16, and "the center … is not highlighted".
- **Ring membership is never taken from production `ring`:**
  - For rows 1–6, a ring's cells are the range `(previous row's last number) + 1 … last number`, both read from the table's literal column.
  - Each of those cells must also satisfy `max(|x|, |y|) == k`, a geometric check on the forward mapping.
  - Beyond row 6, the range is `(2k−1)² + 1 … (2k+1)²`, which follows SQ-9 ("the last cell in ring k is (2k+1)²").

**Tech Stack:** Dart 3.14, `package:test` (existing dev dependency). No new dependencies.

**Spec:**
- `docs/development/testing-qa/ZOD-TST-011-author-the-ring-highlight-count-test-t-gan-2.md` (Notes dated 2026-11-12)
- `assets/zodiann-specification.md`:
  - T-GAN-2 (line 659);
  - Appendix B (the table plus the 9×9 total and the center sentence);
  - SQ-9 and SQ-12 to SQ-15 (lines 159–168), plus the parity table after SQ-15 (odd rings: 4 / 4 / 0).

## Product-owner decisions already in force (2026-11-12)

1. **TST-011 owns the dedicated T-GAN-2 verification**, because GAN-002's criterion points here. Expected counts come from Appendix B's literal table, never from production helpers. The suite needs a mutation proof showing it fails when a classification rule or the priority order changes (TST-011 Notes).
2. The classifier is fixed and integer-based, and categories map to the default rule ids (GAN-002 Notes). This suite counts **categories**; colours via rules are out of scope.

No new product decisions are needed.

## Global Constraints

- **Test-only.** No file under `lib/` changes. Pure Dart; the ARCH-2 guard stays green.
- **Independence:**
  - The suite imports with `show spiralCell, classifyHighlight, HighlightCategory`.
  - It never reads `ring`, `indexInRing` or `stepsFromAxis`.
  - `angle` is only compared against literal steps.
- **Out of scope:**
  - *Where* the highlights sit (orientation, axes above or below): that is T-GAN-3, ZOD-TST-010. Counts are invariant under rotation and mirroring, so a spiral orientation mutant is expected to pass this suite.
  - Colour tokens and rule lookup (`highlightRuleFor`, SQR tasks).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Location | `packages/gann_core/test/accuracy/t_gan_2_ring_counts_test.dart` | PROGRESS convention |
| Appendix B rows | `const` records `(k, cells, anglePerCell, blue, yellow, gray, side, last)`: `(1, 8, 45.0, 4, 4, 0, 3, 9)`, `(2, 16, 22.5, 4, 4, 8, 5, 25)`, `(3, 24, 15.0, 4, 4, 0, 7, 49)`, `(4, 32, 11.25, 4, 4, 8, 9, 81)`, `(5, 40, 9.0, 4, 4, 0, 11, 121)`, `(6, 48, 7.5, 4, 4, 8, 13, 169)`. One test per row, named `'Appendix B ring $k: $cells cells, $blue blue / $yellow yellow / $gray gray'` | Every row is asserted individually (criterion 1). The literal values were verified by a scratch run against `main` @ `3a447d5` |
| Per-row assertions | For the cells `prevLast + 1 … last`:<br>• **cells:** the number of n in 2 … 225 (15×15, through ring 7) whose forward mapping has `max(|x|, |y|) == k` equals the `cells` column. This counts production's placement geometrically, and also catches ring-k cells placed outside the range. For row 1, `prevLast` is 1 (the center, which Appendix B says is not counted in a ring). The literal identity `last − prevLast == cells` stays as a table self-consistency check;<br>• **ring:** every cell has `max(|x|, |y|) == k`;<br>• **side:** `2·max|x| + 1` equals the `side` column;<br>• **angle per cell:** each consecutive pair's `(angle₂ − angle₁ + 360) % 360` equals `anglePerCell` (exact equality: every `45·i/k` quotient for k ≤ 6 is representable; see Risks);<br>• **counts:** the axis, diagonal and eighth counts equal blue, yellow and gray, and the unhighlighted count is `cells − blue − yellow − gray`;<br>• **last number:** cell `last` has `max(|x|, |y|) == k` and cell `last + 1` has `k + 1` | Every column of the table is asserted, not just the colours |
| 9×9 total | A separate named test, `'9×9 square (rings 1–4): 16 blue, 16 yellow, 16 gray'`, over n = 2…81. Also assert that the center, n = 1, has category `null` | Criterion 2 needs its own named case. The center rule comes from Appendix B |
| Beyond the table | `'T-GAN-2 for rings 7–30: 4 blue, 4 yellow, 8 gray in even rings, 0 in odd'`. The per-ring counts use the SQ-9 ranges, with the geometric ring check | The T-GAN-2 sentence is itself a spec literal. A rule bug that only appears for larger `k` (for example, a divisor that coincides for k ≤ 6) would otherwise escape |

## File Structure

```
packages/gann_core/test/accuracy/
  t_gan_2_ring_counts_test.dart    T-GAN-2: Appendix B rows 1–6 (every column), 9×9 total, rings 7–30
```

## Review Focus

1. **Self-confirming ring membership:** cell ranges come from the table's literal "last number" column and SQ-9, cross-checked geometrically. Production `ring` is never used.
2. **A rule bug that coincides on rings 1–6:** rings 7–30 are covered by T-GAN-2's sentence. (Mutant H3 matches on rings 2 and 6; only row 4, the 9×9 total and rings 8, 12, … catch it.)
3. **Priority order:** a reordered check moves cells between categories while the total highlighted count stays the same. Per-category counts catch it. (Mutants H5, H6.)
4. **The center:** it must not be counted or highlighted. (Mutant H7.)
5. **Orientation is not this suite's job:** a rotation or mirror leaves the counts unchanged. That is documented, and owned by TST-010.

## Tasks

TDD note: production already exists, so the suite is expected to pass on its first run. The RED evidence is the mutation proof, which runs before the suite is committed, as in TST-010, TST-012 and TST-013.

### Task 1: Suite and mutation proof

**Files:** create `packages/gann_core/test/accuracy/t_gan_2_ring_counts_test.dart`.

**Interfaces (from GAN-001 / GAN-002):**
- `SpiralCell spiralCell(int n)`, with `x`, `y` and `angle` (a nullable double);
- `HighlightCategory? classifyHighlight(SpiralCell)`, with `axis`, `diagonal` and `eighth`.

- [ ] **Step 1: Write the suite.**
  - **Header:** the independence rules and where the expected values come from.
  - **Helper:** `_counts(int from, int to)`. It returns `(axis, diagonal, eighth, none, rings)`, where `rings` is the set of `max(|x|, |y|)` values over the range.
  - **Tests:** the 6 Appendix B row tests, the 9×9 total test and the rings 7–30 test (8 tests in total).
- [ ] **Step 2: Run the suite.**
  - Run `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy`.
  - Expected: `All tests passed!`, with 8 new tests.
  - If a test fails, re-derive its expected value by hand from the spec.
    - If the test is wrong, fix it and record a ruling.
    - If production is wrong, stop and report a GAN-002 defect. Never edit `lib/`, and never change an expectation to match production.
- [ ] **Step 3: Run the gates:** `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: exit 0.
- [ ] **Step 4: Mutation proof.**
  - Copy `packages/gann_core/lib/src/highlight/highlight_classification.dart` to the session scratch directory.
  - For each mutant:
    - apply it;
    - confirm it is in place: `git diff -- packages/gann_core/lib` shows exactly the intended change. A passing run with an empty diff is a failed mutation, not a surviving mutant;
    - run `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy/t_gan_2_ring_counts_test.dart`;
    - confirm **test failures, not compile errors**, and record the T-GAN-2 failing-test count;
    - restore the file.
  - Expected T-GAN-2 failures (of 8): H1 8, H2 8, H3 3, H4 5, H5 8, H6 8, H7 1.
  - At the end, confirm that `git diff --exit-code -- packages/gann_core/lib` exits 0.

  | # | Mutant | Must fail (at least) |
  |---|---|---|
  | H1 | axis rule `i % (2 * k)` → `i % k` (diagonals turn blue) | every row test, 9×9, rings 7–30 |
  | H2 | diagonal rule `i % k` → `i % (2 * k)` (no yellow) | every row test, 9×9, rings 7–30 |
  | H3 | gray rule `(2 * i) % k` → `(4 * i) % k` | row 4, 9×9, rings 7–30 (rings 2 and 6 coincide: for k ≡ 2 (mod 4), 4i mod k = 0 ⇔ 2i mod k = 0; odd rings are unaffected) |
  | H4 | gray removed: the eighth line returns `null` | rows 2, 4 and 6, 9×9, rings 7–30 |
  | H5 | priority: the diagonal check before the axis check | every row test, 9×9, rings 7–30 |
  | H6 | priority: the eighth check before the diagonal check | every row test, 9×9, rings 7–30 |
  | H7 | the center classified: `if (cell.isCenter) return HighlightCategory.axis;` | 9×9 (center) |

- [ ] **Step 5: Commit.** Use the message `test(ZOD-TST-011): T-GAN-2 ring counts suite; mutation proof H1–H7`, and put each mutant's failing-test count in the body, followed by "All restored; lib/ unchanged."

### Task 2: Close out (zodiann-development workflow)

- [ ] **Step 1: Code review.** Run a whole-branch review (`requesting-code-review`, a fresh reviewer on the most capable model). Re-grade its findings, then fix the important ones test-first.
- [ ] **Step 2: Documentation.**
  - TST-011 task file: set `Status: Done` and tick both criteria.
  - `TASKS.md`: set the row to Done.
  - `docs/PROGRESS.md`: completed row, verification, and Current / Next task. Square of Nine core and suites are complete.
- [ ] **Step 3: Publish.** Commit, push and open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| Every row of Appendix B's table is individually asserted | 6 named row tests, each asserting every column (cells, angle per cell, blue, yellow, gray, side, last number); mutants H1–H6 |
| The 9×9 total assertion exists as its own named test case | `'9×9 square (rings 1–4): 16 blue, 16 yellow, 16 gray'`, including the unhighlighted center; mutant H7 |
| (T-GAN-2) each ring 4 / 4 / and 8 gray in even rings | Rings 1–6 from the table, rings 7–30 from the sentence |

## Risks

- **Floating-point angle steps:** production computes `(45·i)/k`. For k ≤ 6, every quotient (multiples of 45, 22.5, 15, 11.25, 9 and 7.5) is exactly representable, and IEEE division is correctly rounded, so consecutive differences equal the Appendix B literal exactly. This was verified in a scratch run. Compare with `equals`, not a tolerance. The wrap pair (i = 8k−1 → 0) is handled by `+ 360) % 360`.
- **H3 coincides on rings 2 and 6** (any k ≡ 2 mod 4). This is expected and documented. Row 4, the 9×9 total and rings 7–30 catch it.

## Plan review

**Round 1: Approve after corrections.** The reviewer built a scratch harness with a draft suite and ran every mutant against it.
- **I1 (Important), applied.** H3 coincides on rings 2 *and* 6 (k ≡ 2 mod 4), not only on ring 2. The H3 row, Review Focus and Risks are corrected.
- **I2 (Important), applied.** The plan contradicted itself on the angle comparison. Exact equality is kept: every quotient for k ≤ 6 is representable, so no tolerance is needed.
- **I3 (Important), applied.** The "cells" check compared one literal with another. It now counts production's placement geometrically over 2…225, and row 1's previous last number is 1.
- **Minors M1–M4, applied:**
  - the odd-ring zero is cited to the parity table after SQ-15;
  - mutants run only the T-GAN-2 file, with expected counts;
  - the path is fixed;
  - each mutant is confirmed to be in place before its run.

**Round 2: Approve.** Re-running the harness with the revised cells check, production passes (8/8), and every mutant reproduces the expected counts exactly (H1 8, H2 8, H3 3, H4 5, H5 8, H6 8, H7 1). Minor M1 (the test-name template) is applied; M2 is this record. No open items and no user decisions.

