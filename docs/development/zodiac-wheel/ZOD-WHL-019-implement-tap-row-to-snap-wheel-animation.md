# ZOD-WHL-019 - Implement tap-row-to-snap wheel animation

## Metadata

- **ID:** ZOD-WHL-019
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Tapping a positions-table row rotates the wheel until that body sits under the pointer, animated.

## Implementation Details

- Animation: 450ms, `easeInOutCubic`, taking the shortest rotational arc to the target.
- Under reduced motion (system setting), the wheel jumps instantly with no animation (WH-13's explicit accessibility carve-out).

## Design Reference

`design-reference/zodiann/MASTER.md` §12 "Motion" ("Wheel snap to a body (WH-13): 450ms, easeInOutCubic, taking the shortest arc").

## Acceptance Criteria

- [ ] Tapping any row rotates the wheel to put that body under the pointer within 450ms via the shortest arc.
- [ ] With reduced motion enabled, the same tap produces an instant jump with no animation frames.

## Dependencies

- [ZOD-WHL-018](../zodiac-wheel/ZOD-WHL-018-build-the-positions-table.md) — Build the positions table
- [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) — Implement wheel rotation via drag (rotate-wheel mode)

## Specification References

- WH-13
- MASTER.md §12

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
