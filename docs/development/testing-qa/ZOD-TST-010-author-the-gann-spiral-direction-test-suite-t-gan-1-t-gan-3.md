# ZOD-TST-010 - Author the Gann spiral/direction test suite (T-GAN-1, T-GAN-3)

## Metadata

- **ID:** ZOD-TST-010
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Verify the spiral's direction/position (T-GAN-1) and the axis/diagonal angle assignments (T-GAN-3) as standalone tests.

## Implementation Details

- T-GAN-1: assert cell 2 is left of cell 1 and the spiral moves clockwise through at least the first several dozen cells (explicit positions, not just "it looks right").
- T-GAN-3: assert the 90° axis (the cells straight above cell 1: x = 0, y < 0) and the 270° axis (straight below: x = 0, y > 0) are blue (corrected 2026-11-12; see Notes), and only 45/135/225/315 are yellow — directly exercising the Appendix C table.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [x] T-GAN-1 passes against explicit expected (x,y) coordinates for the first ~40 cells.
- [x] T-GAN-3 passes for every angle in Appendix C's table, both the positive (is this color) and negative (is not another color) assertions.

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- T-GAN-1
- T-GAN-3
- Appendix C

## Notes

- 2026-11-12 (product-owner decision): this task owns the dedicated T-GAN-1 verification of the spiral formulas implemented in ZOD-GAN-001, whose criterion was amended to point here. As with ZOD-TST-002:
  - expected coordinates come from an independent source (explicit literal coordinates and/or the design reference), never from production helpers;
  - add a mutation proof showing the suite fails on a flipped direction or a moved cell.
- **Spec conflict (resolved 2026-11-12, see the decision below):** T-GAN-3's text says "the 270 axis (the row above cell 1 on screen) is blue". But the spiral formula (x right, y down, signs flipped), SQ-8, Appendix C (90° = North axis, 270° = South axis) and the design reference (`02-square-of-nine_numbers_desktop_en_dark.png`: "90° N" above the square, "270° S" below) all put **90°** on the row above cell 1 and 270° below. Flagged during ZOD-GAN-001 planning; GAN-001 follows the formula and Appendix C.
  - **Product-owner decision (2026-11-12): 90° is the axis above cell 1.** The T-GAN-3 wording is treated as a typo, and this task's T-GAN-3 implementation detail is corrected accordingly: the 90° axis is above cell 1 and the 270° axis below, both blue. The spec file itself isn't edited; this note records the correction. Same correction in ZOD-GAN-002.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
