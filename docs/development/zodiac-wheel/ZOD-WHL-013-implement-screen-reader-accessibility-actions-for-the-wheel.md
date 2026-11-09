# ZOD-WHL-013 - Implement screen-reader accessibility actions for the wheel

## Metadata

- **ID:** ZOD-WHL-013
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Provide VoiceOver/TalkBack-equivalent actions for the same 1°/10° movement that keyboard arrows provide, since the wheel is a custom-painted control with no native semantics.

## Implementation Details

- Expose custom accessibility actions (increment/decrement, or equivalent) matching the 1°/10° step sizes of [ZOD-WHL-012](../zodiac-wheel/ZOD-WHL-012-implement-external-keyboard-controls-for-the-wheel.md).
- Ensure the wheel's semantic label communicates current readout content (sign/degree/minute under the pointer) for screen-reader users.

## Design Reference

No direct design reference applies — this is a non-visual accessibility behavior layered on the already-designed wheel.

## Acceptance Criteria

- [ ] VoiceOver and TalkBack can both move the wheel by 1° and 10° via accessibility actions.
- [ ] The wheel's accessibility label announces the current under-pointer reading.

## Dependencies

- [ZOD-WHL-012](../zodiac-wheel/ZOD-WHL-012-implement-external-keyboard-controls-for-the-wheel.md) — Implement external-keyboard controls for the wheel

## Specification References

- WH-10 ("with a screen reader, equivalent accessibility actions")
- NFR-X2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
