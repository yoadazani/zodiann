# ZOD-SQR-019 - Build the controls-panel layout and summary row

## Metadata

- **ID:** ZOD-SQR-019
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Assemble Mode, Anchor, Size, Cells, and "Show up to today" into the single wrapping control row, plus the summary rule/line below it.

## Implementation Details

- One wrapping row: Mode | Anchor + shortcut (date modes only) | Size | Cells | Show up to today (date modes only).
- Below a horizontal rule: actual count + dimensions, Today tag + today's cell number (when applicable).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` (full controls panel, top of the screen).

## Acceptance Criteria

- [ ] Row wraps gracefully at narrow widths without overlapping controls.
- [ ] Mode-conditional visibility (anchor, Show up to today) matches ZOD-SQR-002/004.

## Dependencies

- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation
- [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md) — Build the anchor field and "Anchor to today/now" shortcut
- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-SQR-004](../gann-square/ZOD-SQR-004-implement-show-up-to-today-show-up-to-now.md) — Implement "Show up to today" / "Show up to now"
- [ZOD-SQR-009](../gann-square/ZOD-SQR-009-implement-the-today-cell-computation-and-live-update.md) — Implement the "today" cell computation and live update

## Specification References

- SQ-10
- MASTER.md §8.1 "Controls panel"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
