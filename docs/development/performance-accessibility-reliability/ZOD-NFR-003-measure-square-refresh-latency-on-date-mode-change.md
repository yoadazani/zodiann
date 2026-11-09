# ZOD-NFR-003 - Measure square refresh latency on date/mode change

## Metadata

- **ID:** ZOD-NFR-003
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Measure time from a date/mode-changing touch event to the square's redraw, ensuring no noticeable delay.

## Implementation Details

- Instrument the touch-to-paint latency for mode switches, anchor changes, and size changes at the maximum 61×61 size.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-P2 passes: measured latency shows no noticeable delay at any tested size/mode combination.

## Dependencies

- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation
- [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md) — Build the anchor field and "Anchor to today/now" shortcut
- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)

## Specification References

- NFR-P2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
