# ZOD-WHL-011 - Implement change-date drag mode

## Metadata

- **ID:** ZOD-WHL-011
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the second drag mode: a counterclockwise drag advances time at a fixed ratio of one degree of drag to one day of time, instead of rotating the display.

## Implementation Details

- Selected via the same "Rotate wheel" / "Change date" segmented control as [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md).
- Counterclockwise drag → time advances; clockwise → time moves backward, at exactly 1°/day.
- Changing time in this mode must update every dependent panel (positions table, readout, time field) through the same state the Time panel controls use ([ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md)), not a separate code path.

## Design Reference

`design-reference/zodiann/MASTER.md` §7.3 "Drag mode" (the hint text changes to describe this mode); the mockup's static screenshots show "Rotate wheel" mode active, so this mode's hint copy and any unique visual treatment are a design gap if not otherwise specified — implement the hint text change, flag anything beyond that as needing design confirmation.

## Acceptance Criteria

- [ ] T-UI-2 passes (change-date portion): dragging in this mode moves the date at 1° per day.
- [ ] Switching to this mode changes the hint text to describe date-changing behavior.
- [ ] Date changes from dragging are reflected immediately in the Time panel's date field and the positions table.

## Dependencies

- [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) — Implement wheel rotation via drag (rotate-wheel mode)
- [ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md) — Build the Time panel: date/time field and Now button

## Specification References

- WH-9
- T-UI-2

## Notes

- This task has an **explicit design gap** — no design reference covers it yet. Do not invent a visual treatment; request design work before implementing (see Design Reference above).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
