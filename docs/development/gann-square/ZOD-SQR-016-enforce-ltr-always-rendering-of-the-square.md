# ZOD-SQR-016 - Enforce LTR-always rendering of the square

## Metadata

- **ID:** ZOD-SQR-016
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

The square is always displayed left to right, even in the Hebrew interface, so the geometric spiral layout is preserved.

## Implementation Details

- Wrap the square's canvas (and any text drawn on it) in `Directionality(textDirection: TextDirection.ltr)`, mirroring the wheel's approach ([ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md)).
- Verify this holds for the controls panel's field *order* too, where applicable — only the square grid itself is exempted from mirroring; surrounding chrome (labels, buttons) still mirrors normally per L-4.

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_he_dark.png` (compare directly against the `_en_` version — the square grid itself must be pixel-identical, only the surrounding panel chrome mirrors); `design-reference/zodiann/MASTER.md` §8.2 "Direction".

## Acceptance Criteria

- [ ] The square grid is pixel-identical between the English and Hebrew screenshots.
- [ ] Surrounding controls (labels, buttons, panel order) still mirror correctly per L-4.

## Dependencies

- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)

## Specification References

- SQ-21
- L-6
- MASTER.md §8.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
