# ZOD-EPH-003 - Implement the Swiss Ephemeris built-in (Moshier) fallback mode

## Metadata

- **ID:** ZOD-EPH-003
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the intermediate-accuracy mode used when the data files are missing, with a user-facing message explaining the accuracy tradeoff.

## Implementation Details

- Same `EphemerisPort` contract as [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md), but using Swiss Ephemeris's built-in Moshier mode (no external data files).
- Not selectable as the default (ZOD-SET settings task enforces this); surfaces a message to the user when active.
- Shares the settings radio group with the primary and backup sources (wired in [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md)).

## Design Reference

No direct design reference applies to the computation; the settings radio control itself follows `design-reference/zodiann/screens/04-settings_desktop_en_dark.png` ("Ephemeris source" radio list) and is built in [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md).

## Acceptance Criteria

- [ ] Mode produces a position without requiring data files present.
- [ ] A message is surfaced (via the settings screen) explaining this is lower accuracy than the primary source.
- [ ] Mode is never auto-selected as default.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Specification References

- "Data sources, in order of priority" (Swiss Ephemeris built-in row)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
