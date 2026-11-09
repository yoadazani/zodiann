# ZOD-SQR-010 - Implement cell tap-to-select and details-panel wiring

## Metadata

- **ID:** ZOD-SQR-010
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Tapping a cell selects it ([ZOD-SQR-008](../gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md)'s selected-border state) and populates the details panel ([ZOD-SQR-012](../gann-square/ZOD-SQR-012-build-cell-details-core-fields.md)/013).

## Implementation Details

- Single-selection model (tapping a new cell deselects the previous one).
- On a wide screen the details panel floats sticky beside the square; on a phone it appears above the square (SQ-16) — exact placement resolved per-breakpoint in [ZOD-SQR-020](../gann-square/ZOD-SQR-020-implement-responsive-square-screen-layout-desktop-tablet-portrait.md).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` (selected cell `31.8.26` with the "Cell 139" details panel populated beside it).

## Acceptance Criteria

- [ ] T-UI-4 passes: tapping a cell in numbers mode opens details including number, angle, direction, and number squared.
- [ ] Only one cell is ever selected at a time.

## Dependencies

- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)
- [ZOD-SQR-008](../gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md) — Implement cell border stacking (selected, today, center)
- [ZOD-SQR-012](../gann-square/ZOD-SQR-012-build-cell-details-core-fields.md) — Build cell details: core fields

## Specification References

- SQ-16
- T-UI-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
