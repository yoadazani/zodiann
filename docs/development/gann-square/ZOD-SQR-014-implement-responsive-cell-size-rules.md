# ZOD-SQR-014 - Implement responsive cell-size rules

## Metadata

- **ID:** ZOD-SQR-014
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Pick the largest cell size that fits the available width within each mode's allowed range, falling back to horizontal scroll ([ZOD-SQR-015](../gann-square/ZOD-SQR-015-implement-the-squares-own-horizontal-scroll-container.md)) when even the minimum doesn't fit.

## Implementation Details

- Numbers: 30–56px (desktop 50, tablet 52, phone 38). Dates: 40–64px (desktop/tablet 52, phone 44). Date and time: 46–72px (desktop/tablet 58, phone 50).
- Selection algorithm: "use the largest size in range that fits the available width; if even the minimum doesn't fit, scroll" (explicit rule from MASTER.md §8.2).

## Design Reference

`design-reference/zodiann/MASTER.md` §8.2 "Cell sizes" table (exact per-mode, per-breakpoint values and the selection rule).

## Acceptance Criteria

- [ ] At each tested viewport width, the rendered cell size matches the table's desktop/tablet/phone value for the active mode.
- [ ] NFR-P4 passes: the 61×61 maximum size renders with no unnecessary horizontal scroll and no slowdown at an appropriately sized viewport.

## Dependencies

- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)

## Specification References

- SQ-20
- NFR-P4
- MASTER.md §8.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
