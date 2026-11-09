# ZOD-WHL-012 - Implement external-keyboard controls for the wheel

## Metadata

- **ID:** ZOD-WHL-012
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

When the wheel has keyboard focus, left/right arrows move one degree (ten with Shift), honoring whichever drag mode is currently selected.

## Implementation Details

- Arrow key = 1° step; Shift+arrow = 10° step.
- Behavior depends on the active mode exactly as the touch-drag does: rotate-wheel mode moves the display, change-date mode moves time by the equivalent days.
- A visible dashed `focus` ring renders outside the rim when the wheel holds keyboard focus.

## Design Reference

`design-reference/zodiann/MASTER.md` §7.2 "Focus (WH-10)" row for the dashed-ring treatment.

## Acceptance Criteria

- [ ] Arrow keys move the wheel/date by exactly 1° (10° with Shift), matching the active mode.
- [ ] Focus ring appears exactly per the MASTER.md spec when the wheel is focused via Tab.
- [ ] Behavior is equivalent whether triggered by physical keyboard or an external Bluetooth keyboard on mobile.

## Dependencies

- [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) — Implement wheel rotation via drag (rotate-wheel mode)
- [ZOD-WHL-011](../zodiac-wheel/ZOD-WHL-011-implement-change-date-drag-mode.md) — Implement change-date drag mode

## Specification References

- WH-10
- MASTER.md §7.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
