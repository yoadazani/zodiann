# ZOD-XLS-015 - Implement PNG/PDF screen export (wheel and square)

## Metadata

- **ID:** ZOD-XLS-015
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Export an image of the wheel or square screen as currently displayed, with a choice of light or dark theme for the exported image independent of the app's current theme.

## Implementation Details

- Render the relevant screen's `RepaintBoundary` to an image (PNG) or wrap it in a single-page PDF.
- Theme choice is a separate, explicit export-time option, not tied to whatever theme the app is currently running in.

## Design Reference

No direct design reference applies to the export mechanism; the rendered output should match whichever theme's screenshot (`design-reference/zodiann/screens/01-zodiac-wheel_*` or `02-square-of-nine_*`) the user selected.

## Acceptance Criteria

- [ ] Exported image/PDF visually matches the live screen at the moment of export.
- [ ] Choosing "light" theme for the export produces a light-themed image even while the app is running in dark mode, and vice versa.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)

## Specification References

- "Other formats" table (png/pdf row)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
