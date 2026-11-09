# ZOD-WHL-024 - Build the compact (phone/tablet) wheel drawing variant

## Metadata

- **ID:** ZOD-WHL-024
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Apply the compact proportion set from [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) across every wheel-drawing task so the wheel reads correctly on small screens, per the documented D6 deviation.

## Implementation Details

- Switch all radius fractions, glyph sizes, and label sizes to the "Compact" column of MASTER.md §7.2's table at the tablet/phone breakpoints.
- Apply the 16° (not 11°) display-spread threshold from [ZOD-WHL-005](../zodiac-wheel/ZOD-WHL-005-implement-the-body-display-spread-collision-avoidance-algorithm.md) only in this compact mode.

## Design Reference

`design-reference/zodiann/responsive/mobile/zodiac-wheel_mobile_{en,he}_{dark,light}.png` and `responsive/tablet/zodiac-wheel_{tablet,tablet-landscape}_*`; `design-reference/zodiann/MASTER.md` §7.2 compact column; `DESIGN_DECISIONS.md` D6.

## Acceptance Criteria

- [ ] Rendered phone/tablet wheel matches the responsive screenshots' proportions.
- [ ] Glyphs are legible (not the ~9px desktop-scaled-down size D6 explicitly rejects).

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) through [ZOD-WHL-009](../zodiac-wheel/ZOD-WHL-009-implement-the-fixed-pointer-and-under-the-pointer-readout.md)

## Specification References

- DESIGN_DECISIONS.md D6
- MASTER.md §7.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
