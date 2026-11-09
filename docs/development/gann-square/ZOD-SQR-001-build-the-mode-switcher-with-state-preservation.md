# ZOD-SQR-001 - Build the mode switcher with state preservation

## Metadata

- **ID:** ZOD-SQR-001
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the Numbers/Dates/Date-and-time segmented control, preserving size and the selected cell across a mode switch when the cell is still valid.

## Implementation Details

- Uses [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) segmented control.
- Switching mode must keep the current size and selected-cell index; if the previously selected cell no longer exists at the current size, clear the selection rather than erroring.
- Mode switch also toggles visibility of mode-specific controls (anchor field type, "Show up to today" availability) wired in [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md)/004.

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` "Mode" control (Numbers / Dates selected / Date and time).

## Acceptance Criteria

- [ ] T-UI-3 passes (mode-switch portion): switching mode preserves size and selected cell when still valid.
- [ ] Switching from a larger to a smaller size and back does not crash if the previous selection is out of range.

## Dependencies

- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- SQ-1
- T-UI-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
