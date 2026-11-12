# ZOD-GAN-002 - Implement Gann highlight classification (blue/yellow/gray)

## Metadata

- **ID:** ZOD-GAN-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Classify each cell's angle into the three highlight categories, with the exact priority order the spec requires.

## Implementation Details

- Blue: `i mod 2k = 0` (equivalently, angle is a multiple of 90°: 0°, 90°, 180°, 270°).
- Yellow: `i mod k = 0` and not blue (angle is 45°, 135°, 225°, 315°).
- Gray: `2i mod k = 0` and not blue or yellow (other multiples of 22.5°).
- Priority order is strict: blue, then yellow, then gray; a cell matching none is unhighlighted. The center has no angle and is never classified by this function (it gets its own amber "center" marker elsewhere).
- Verify against the ring table: odd rings → 4 blue, 4 yellow, 0 gray; even rings → 4 blue, 4 yellow, 8 gray (Appendix B).

## Design Reference

No direct design reference applies to the classification math itself; the resulting color tokens are `design-reference/zodiann/MASTER.md` §2.2 (`axis-fill`/`diag-fill`/`eighth-fill` etc.), consumed in [ZOD-SQR-011](../gann-square/ZOD-SQR-011-implement-keyboard-cell-selection-navigation.md).

## Acceptance Criteria

- [x] Classification is implemented and covered by GAN-002's own unit tests: a 9×9 square (rings 1–4) totals 16 blue, 16 yellow, 16 gray; Appendix B per-ring counts. Dedicated T-GAN-2 verification is tracked by [ZOD-TST-011](../testing-qa/ZOD-TST-011-author-the-ring-highlight-count-test-t-gan-2.md).
- [x] Own unit tests cover the axes and diagonals per Appendix C: the 90° axis (the cells straight above cell 1: x = 0, y < 0) and the 270° axis (straight below: x = 0, y > 0) are blue; only 45/135/225/315 are yellow (corrected 2026-11-12; see Notes). Dedicated T-GAN-3 verification is tracked by [ZOD-TST-010](../testing-qa/ZOD-TST-010-author-the-gann-spiral-direction-test-suite-t-gan-1-t-gan-3.md).
- [x] Priority order is verified with a cell that would otherwise match more than one category conceptually (none should, if the math is right — this test guards the *order* of the `if` chain itself).

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)

## Specification References

- "Gann spiral" (Blue/Yellow/Gray rules)
- SQ-11 to SQ-15
- Appendix B
- Appendix C
- T-GAN-2
- T-GAN-3

## Notes

- 2026-11-12 (flagged during ZOD-GAN-001 planning): this task's T-GAN-3 criterion said "angle 270° (the row above cell 1) is blue". The spiral formula, SQ-8, Appendix C (90° = North axis, 270° = South axis) and the design reference all put **90°** on the row above cell 1. **Product-owner decision (2026-11-12): 90° is the axis above cell 1.** The T-GAN-3 wording is treated as a typo, and the criterion above is corrected to "the 90° axis (the cells straight above cell 1: x = 0, y < 0) and the 270° axis (straight below: x = 0, y > 0) are blue". The spec file itself isn't edited; this note records the correction. The same correction is applied in [ZOD-TST-010](../testing-qa/ZOD-TST-010-author-the-gann-spiral-direction-test-suite-t-gan-1-t-gan-3.md).
- 2026-11-12 (product-owner decision, same resolution as ZOD-EPH-001 / ZOD-GAN-001): the criteria "T-GAN-2 passes" and "T-GAN-3 passes" were amended to "covered by GAN-002's own unit tests; dedicated T-GAN-2 / T-GAN-3 verification tracked by ZOD-TST-011 / ZOD-TST-010". Those test tasks depend on this one, so the original wording was a cycle. The tasks stay separate.
- 2026-11-12 (product-owner decision): **fixed classifier.** This task implements exactly the spec's integer tests on `i` and `k` (blue `i mod 2k = 0`, yellow `i mod k = 0`, gray `2i mod k = 0`, priority blue > yellow > gray). It returns a category, with a documented mapping from each category to its default highlight rule id (`axes` / `diagonals` / `eighths`) so color tokens come from the square's rules. Evaluating arbitrary user-defined `HighlightRule`s is **not** part of this task; it belongs to [ZOD-EXT-008](../optional-extensions/ZOD-EXT-008-user-defined-highlight-angles-and-colors.md).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
