# ZOD-WHL-014 - Build the Time panel: date/time field and Now button

## Metadata

- **ID:** ZOD-WHL-014
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the date-and-time input and Now shortcut that drive the wheel's displayed moment.

## Implementation Details

- Date-and-time field (uses [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)) bound to the shared wheel-time state.
- **Now** button in accent-outline style ([ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md)) sets the field to the current device moment.
- Device time zone displayed at the end of the transport row (e.g., "Device time, Asia/Jerusalem (UTC+2)").

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` "Time" panel (date field "09/11/2026 12:00", Now button, time-zone text at the end of the transport row); `design-reference/zodiann/MASTER.md` §7.3 "Time panel".

## Acceptance Criteria

- [ ] Field and Now button match the reference screenshot.
- [ ] Changing the field updates the wheel, readout, and positions table immediately.
- [ ] Time zone label reflects the actual device zone, not a hard-coded value.

## Dependencies

- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states
- [ZOD-WHL-009](../zodiac-wheel/ZOD-WHL-009-implement-the-fixed-pointer-and-under-the-pointer-readout.md) — Implement the fixed pointer and "under the pointer" readout

## Specification References

- WH-11
- MASTER.md §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
