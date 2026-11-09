# ZOD-EXT-005 - Ascendant and houses (birth place/time input)

## Metadata

- **ID:** ZOD-EXT-005
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Implement a full house system requiring birth place and time input — explicitly out of scope for v1 because of the location-privacy question (D-2).

## Implementation Details

Blocked on resolving D-2 (does requiring a geographic location conflict with the app's no-data-leaves-device, no-location-collection posture); any implementation must still satisfy DATA-5/DATA-7 (no network, fully offline) even though it now needs a location input mechanism.

## Design Reference

No direct design reference applies — entirely unaddressed by the current mockups; would require new screens (birth data entry) not covered by any existing design reference.

## Acceptance Criteria

- [ ] D-2 is explicitly resolved before any implementation begins.
- [ ] Location input (if approved) never leaves the device, consistent with DATA-5/DATA-7.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Specification References

- "Planned extensions to the wheel"
- D-2
- "A birth chart with ascendant and houses" (out of scope note)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
