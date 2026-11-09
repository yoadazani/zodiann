# ZOD-WHL-025 - Implement responsive wheel-screen layout (desktop/tablet/phone)

## Metadata

- **ID:** ZOD-WHL-025
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Arrange the wheel panel, readout, Time panel, Positions table, and Degree crossings panel per breakpoint.

## Implementation Details

- Desktop: grid `1fr | 470`; wheel panel spans two rows on the start side; Time and Positions stack on the end side; Degree crossings spans full width below.
- Tablet: wheel panel full width with a 250px readout column beside it; Time full width; Positions and Degree crossings side by side (crossings as a list).
- Phone: single column stack — wheel, readout + aspect legend, Time, Positions, Degree crossings.

## Design Reference

`design-reference/zodiann/MASTER.md` §7.1 "Layout" (exact grid/stacking rules per breakpoint); `design-reference/zodiann/screens/01-zodiac-wheel_desktop_*`, `responsive/tablet/zodiac-wheel_tablet*`, `responsive/mobile/zodiac-wheel_mobile_*`.

## Acceptance Criteria

- [ ] Layout matches each breakpoint's screenshot (panel order, grid proportions, column counts).
- [ ] No horizontal page scroll is introduced at any breakpoint (NFR-C2).

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) through [ZOD-WHL-022](../zodiac-wheel/ZOD-WHL-022-implement-tap-crossing-row-to-navigate-interaction.md)
- [ZOD-WHL-024](../zodiac-wheel/ZOD-WHL-024-build-the-compact-phone-tablet-wheel-drawing-variant.md) — Build the compact (phone/tablet) wheel drawing variant

## Specification References

- MASTER.md §6, §7.1
- NFR-C2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
