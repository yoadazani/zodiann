# ZOD-WHL-016 - Build the Time panel: back/forward step buttons

## Metadata

- **ID:** ZOD-WHL-016
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the two transport buttons that step the wheel's time backward/forward by the currently selected step size.

## Implementation Details

- 46px boxed icon buttons, using the `chevL`/`chevR` icons (which already swap sides under RTL per [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md)).
- Each tap moves time by exactly one unit of the selected step (Hour/Day/Week/30 days).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (back/forward buttons flanking the play button); `design-reference/zodiann/MASTER.md` §7.3 "Transport".

## Acceptance Criteria

- [ ] Each tap advances/retreats time by exactly one step unit.
- [ ] Buttons visually and functionally swap sides under RTL (back points right in Hebrew).

## Dependencies

- [ZOD-WHL-015](../zodiac-wheel/ZOD-WHL-015-build-the-time-panel-step-size-segmented-control.md) — Build the Time panel: step-size segmented control
- [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) — Integrate the 33-icon set as SVG assets

## Specification References

- WH-11
- MASTER.md §7.3
- L-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
