# ZOD-GAN-002 - Implement Gann highlight classification (blue/yellow/gray)

## Metadata

- **ID:** ZOD-GAN-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
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

- [ ] T-GAN-2 passes: a 9×9 square (rings 1–4) totals 16 blue, 16 yellow, 16 gray.
- [ ] T-GAN-3 passes: angle 270° (the row above cell 1) is blue; only 45/135/225/315 are yellow.
- [ ] Priority order is verified with a cell that would otherwise match more than one category conceptually (none should, if the math is right — this test guards the *order* of the `if` chain itself).

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

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
