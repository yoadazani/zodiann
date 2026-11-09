# ZOD-WHL-009 - Implement the fixed pointer and "under the pointer" readout

## Metadata

- **ID:** ZOD-WHL-009
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw the fixed pointer at 12 o'clock (which never moves — the wheel rotates under it) and the readout panel showing exactly what's under it.

## Implementation Details

- Pointer: `accent`-colored 18×18 triangle above the rim, plus a 1.5px `accent` line across the sign band at 12 o'clock.
- Readout: label "Under the pointer," then position in display type (44/300): `17°03′`, sign glyph in element color, sign name at 26 in `text-2`.
- Below it: "Within 3° of the pointer" with one pill chip per body currently within 3° of the pointer (glyph, name, position).
- Degree/minute under the pointer is derived purely from current wheel rotation + fixed body positions — it is not a separate computation (reuses [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md)'s formatting).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` ("17°03′ Scorpio" readout and the "Sun 17°03′ / Moon 18°41′" pill chips below it); `design-reference/zodiann/MASTER.md` §7.2 "Pointer" and §7.3 "Readout".

## Acceptance Criteria

- [ ] Pointer position is fixed on screen at all times; only the wheel rotates beneath it.
- [ ] Readout text updates live as the wheel rotates (drag or playback).
- [ ] Pill chips appear/disappear correctly as bodies cross the 3° threshold.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)

## Specification References

- WH-7
- MASTER.md §7.2, §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
