# ZOD-WHL-023 - Implement initial wheel state on screen open

## Metadata

- **ID:** ZOD-WHL-023
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

On first opening the wheel screen, set time to the current moment and rotate the wheel so the Sun sits under the pointer.

## Implementation Details

- Equivalent to performing [ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md)'s "Now" action and then [ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md)'s snap-to-body targeting the Sun, as the screen's initial state — but should not visibly animate on cold load (instant initial position, not a 450ms snap on every app launch).

## Design Reference

No direct design reference applies — behavioral initial-state rule.

## Acceptance Criteria

- [ ] On fresh app open, the wheel shows the current moment with the Sun under the pointer, with no animation flourish on load.
- [ ] Returning to the wheel screen after navigating away preserves the last-viewed time rather than resetting (distinct from the cold-open case).

## Dependencies

- [ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md) — Build the Time panel: date/time field and Now button
- [ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md) — Implement tap-row-to-snap wheel animation

## Specification References

- WH-14

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
