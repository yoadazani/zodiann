# ZOD-WHL-018 - Build the positions table

## Metadata

- **ID:** ZOD-WHL-018
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the 11-row table listing every body's glyph, name, sign, position, and motion state.

## Implementation Details

- Columns: Body (glyph + name), Sign (glyph + name), Position (`14°32′`, 500 weight), Motion (Direct in `text-2` / `℞ Retrograde` / `℞ Mean` for the node).
- The row corresponding to the body currently under the pointer is selected (`accent-soft` + start-edge accent bar) — ties the table to the readout (DESIGN_DECISIONS D8).
- On phone, the Motion column and sign names are dropped; ℞ moves next to the position value instead (responsive content reduction, not just visual scaling).
- Minute is floored per [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md), not rounded.

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` "Positions" panel (full 11-row table with Sun selected); `design-reference/zodiann/responsive/mobile/zodiac-wheel_mobile_*` for the phone column-drop variant; `design-reference/zodiann/MASTER.md` §7.3 "Positions table" and `DESIGN_DECISIONS.md` D8.

## Acceptance Criteria

- [ ] All 11 rows render with correct data, matching the live positions.
- [ ] Row under the pointer is selected and updates live as the wheel rotates.
- [ ] Phone layout correctly drops Motion/sign-name columns and relocates ℞, matching the mobile screenshot.

## Dependencies

- [ZOD-UI-010](../shared-ui-design-system/ZOD-UI-010-implement-the-table-component-header-rows-hover-selected.md) — Implement the table component (header, rows, hover, selected)
- [ZOD-WHL-009](../zodiac-wheel/ZOD-WHL-009-implement-the-fixed-pointer-and-under-the-pointer-readout.md) — Implement the fixed pointer and "under the pointer" readout
- [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) — Implement retrograde detection and position formatting

## Specification References

- WH-15
- DESIGN_DECISIONS.md D8
- MASTER.md §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
