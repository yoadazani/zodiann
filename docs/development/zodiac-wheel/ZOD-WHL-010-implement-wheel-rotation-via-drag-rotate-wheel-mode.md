# ZOD-WHL-010 - Implement wheel rotation via drag (rotate-wheel mode)

## Metadata

- **ID:** ZOD-WHL-010
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the primary touch interaction: dragging rotates the wheel around its center, following the angle of the touch point, with time held fixed.

## Implementation Details

- Compute rotation from the angle between the wheel's center and the current touch point, updated continuously during the drag (not just on release).
- Active only in "Rotate wheel" mode (the other mode is [ZOD-WHL-011](../zodiac-wheel/ZOD-WHL-011-implement-change-date-drag-mode.md)); mode is chosen via the segmented control in the wheel panel head (WH-9).
- Must sustain 60fps-class smoothness with all 11 bodies and aspect chords visible (performance budget verified in [ZOD-NFR-002](../performance-accessibility-reliability/ZOD-NFR-002-measure-and-tune-wheel-drag-frame-rate.md)).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` ("Rotate wheel" segmented control, selected, with the hint text "Drag to turn the wheel. Time stays fixed." at the top-right of the panel); `design-reference/zodiann/MASTER.md` §7.3 "Drag mode".

## Acceptance Criteria

- [ ] T-UI-2 passes (rotate-mode portion): dragging rotates the wheel display; underlying time does not change.
- [ ] Rotation tracks the touch angle continuously and smoothly during the drag.
- [ ] Hint text updates to match the active mode, per the screenshot.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-WHL-009](../zodiac-wheel/ZOD-WHL-009-implement-the-fixed-pointer-and-under-the-pointer-readout.md) — Implement the fixed pointer and "under the pointer" readout
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component

## Specification References

- WH-8
- WH-9
- T-UI-2
- MASTER.md §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
