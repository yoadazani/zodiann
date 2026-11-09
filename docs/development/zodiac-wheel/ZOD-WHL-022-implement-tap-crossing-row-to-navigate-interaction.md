# ZOD-WHL-022 - Implement tap-crossing-row-to-navigate interaction

## Metadata

- **ID:** ZOD-WHL-022
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Tapping a degree-crossing row sets the wheel's time to that crossing's moment, rotates the wheel so that degree sits under the pointer, and scrolls the screen up to the wheel.

## Implementation Details

- Reuses the snap-animation behavior from [ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md) (same 450ms/reduced-motion rule) but targets a specific degree rather than "wherever a body currently is."
- Scroll-to-wheel must work from any scroll position, including deep in a long crossings list.

## Design Reference

No new visual element — this is an interaction wired across the already-specified wheel ([ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md)–019) and crossings list ([ZOD-WHL-021](../zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md)).

## Acceptance Criteria

- [ ] Tapping a row sets the date/time field to that exact crossing moment.
- [ ] The wheel rotates (animated per ZOD-WHL-019's rules) so the crossing's degree is under the pointer.
- [ ] The screen auto-scrolls to bring the wheel into view.

## Dependencies

- [ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md) — Implement tap-row-to-snap wheel animation
- [ZOD-WHL-021](../zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md) — Build the degree-crossings results table/list and Moon-exclusion rule

## Specification References

- WH-19

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
