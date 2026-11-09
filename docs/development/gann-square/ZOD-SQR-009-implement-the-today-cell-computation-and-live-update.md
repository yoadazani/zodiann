# ZOD-SQR-009 - Implement the "today" cell computation and live update

## Metadata

- **ID:** ZOD-SQR-009
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Wire [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md)'s "cell of today" into the square's live state so the today border ([ZOD-SQR-008](../gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md)) and the controls panel's "Today — Cell N" tag stay correct as real time passes or the anchor changes.

## Implementation Details

- Recompute today's cell whenever the anchor, mode, or size changes.
- Controls-panel summary row shows a "Today" tag plus the cell number (e.g., "Today — Cell 209," visible in the mockup's summary line).
- Only applies in dates and date-and-time modes (no "today" concept in numbers mode).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` summary row: "289 cells, 17 × 17 — Today — Cell 209".

## Acceptance Criteria

- [ ] Today's cell number updates correctly after any anchor/mode/size change.
- [ ] T-GAN-4's today-marking portion passes, including across a DST boundary.

## Dependencies

- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode
- [ZOD-SQR-008](../gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md) — Implement cell border stacking (selected, today, center)

## Specification References

- SQ-7
- T-GAN-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
