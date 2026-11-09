# ZOD-TST-010 - Author the Gann spiral/direction test suite (T-GAN-1, T-GAN-3)

## Metadata

- **ID:** ZOD-TST-010
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify the spiral's direction/position (T-GAN-1) and the axis/diagonal angle assignments (T-GAN-3) as standalone tests.

## Implementation Details

- T-GAN-1: assert cell 2 is left of cell 1 and the spiral moves clockwise through at least the first several dozen cells (explicit positions, not just "it looks right").
- T-GAN-3: assert angle 270° (the row above cell 1) is blue, and only 45/135/225/315 are yellow — directly exercising the Appendix C table.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] T-GAN-1 passes against explicit expected (x,y) coordinates for the first ~40 cells.
- [ ] T-GAN-3 passes for every angle in Appendix C's table, both the positive (is this color) and negative (is not another color) assertions.

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- T-GAN-1
- T-GAN-3
- Appendix C

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
