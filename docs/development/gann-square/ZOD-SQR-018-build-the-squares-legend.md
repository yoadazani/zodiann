# ZOD-SQR-018 - Build the square's legend

## Metadata

- **ID:** ZOD-SQR-018
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the legend row below the square explaining the highlight colors/marks and how the angle is measured.

## Implementation Details

- Six swatches: Axes (+), Diagonals (×), Eighths, Center, Today, Selected — each with its angle list where applicable.
- One line explaining the angle measurement rule (e.g., "Angle = 45° × i ÷ k, where k is the ring and i counts steps clockwise from the axis of cell 2, west of the center").

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` legend row (exact swatch set and angle-measurement sentence).

## Acceptance Criteria

- [ ] All six swatches render with correct color/mark and match the reference screenshot.
- [ ] Angle-measurement sentence matches the spec's formula description.

## Dependencies

- [ZOD-SQR-006](../gann-square/ZOD-SQR-006-render-highlight-fills-blue-yellow-gray-on-the-square-canvas.md) — Render highlight fills (blue/yellow/gray) on the square canvas
- [ZOD-SQR-007](../gann-square/ZOD-SQR-007-render-non-color-highlight-marks-and.md) — Render non-color highlight marks (+ and ×)
- [ZOD-SQR-008](../gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md) — Implement cell border stacking (selected, today, center)

## Specification References

- SQ-22
- MASTER.md §8.2 "Legend"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
