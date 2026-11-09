# ZOD-EPH-005 - Implement retrograde detection and position formatting

## Metadata

- **ID:** ZOD-EPH-005
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the two small, pure transforms every screen depends on: retrograde flag from speed sign, and longitude → sign/degree/minute.

## Implementation Details

- Retrograde: `speed < 0` (from the ephemeris directly, never from a two-point finite difference) — except the node, which is always "mean ℞" per [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md).
- Format: `sign = ⌊l ÷ 30⌋`, `degree = ⌊l mod 30⌋`, `minute = ⌊(l mod 30 − degree)·60⌋`. Minute is rounded **down**, not rounded to nearest.
- Produce a stable sign key (Aries…Pisces) decoupled from any display string, for localization (feeds L-9).

## Design Reference

No direct design reference applies — pure computation; the resulting formatted string's typography (tabular figures, 14°32′ style) is specified in `design-reference/zodiann/MASTER.md` §3 and implemented where this function is consumed ([ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md), [ZOD-WHL-018](../zodiac-wheel/ZOD-WHL-018-build-the-positions-table.md)).

## Acceptance Criteria

- [ ] T-EPH-3 passes: retrograde marking matches a published Venus or Mercury retrograde window.
- [ ] Minute is floored, never rounded — verified with a value whose true minute fraction is e.g. .99.
- [ ] Sign/degree/minute decomposition is exact at both the 0° and 29°59′ boundary of a sign.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula

## Specification References

- "Position format"
- "Retrograde" (Planet position section)
- T-EPH-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
