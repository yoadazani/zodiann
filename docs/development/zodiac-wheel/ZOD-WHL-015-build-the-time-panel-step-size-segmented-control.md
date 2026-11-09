# ZOD-WHL-015 - Build the Time panel: step-size segmented control

## Metadata

- **ID:** ZOD-WHL-015
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the Hour/Day/Week/30 days step-size selector that governs the back/forward buttons and playback speed-of-advance.

## Implementation Details

- Full-width segmented control ([ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md)) with four options: Hour, Day, Week, 30 days.
- Selected step size is read by [ZOD-WHL-016](../zodiac-wheel/ZOD-WHL-016-build-the-time-panel-back-forward-step-buttons.md) (back/forward) and [ZOD-WHL-017](../zodiac-wheel/ZOD-WHL-017-build-automatic-playback-play-pause.md) (playback).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` "Step" row (Hour / Day selected / Week / 30 days).

## Acceptance Criteria

- [ ] Matches the reference screenshot exactly (default selection: Day).
- [ ] Selecting a step size immediately changes the back/forward button's time delta.

## Dependencies

- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md) — Build the Time panel: date/time field and Now button

## Specification References

- WH-11
- MASTER.md §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
