# ZOD-EPH-007 - Updatable Earth-rotation and leap-second data

## Metadata

- **ID:** ZOD-EPH-007
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Deferred (after the MVP, when a feature needs the data)
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Post-MVP (deferred)

## Description

Let Earth-rotation data (UT1 − UTC, and so ΔT) and the leap-second table be updated without an app release. Build it when topocentric positions, sidereal time or houses need UT1; geocentric positions from 1972 do not depend on it.

## Implementation Details

- Authoritative source: IERS (Bulletin A, `finals.all`, `Leap_Second.dat`). Findings and a proposed architecture: [`docs/spikes/ZOD-EPH-002-time-scale.md`](../../spikes/ZOD-EPH-002-time-scale.md) section 5.2.
- `ΔT = 32.184 + (TAI − UTC) − (UT1 − UTC)`: UT1 − UTC and ΔT are not interchangeable. Interpolate UT1 − TAI.
- Never write downloaded data into a file the C library parses.
- **Settle first, with the owner:** the delivery method (file import or download), the specification changes a download needs (offline rules, DATA-7, DATA-8, NFR-R3), and the IERS terms of use.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Newer validated observations replace estimated or forecast values; predictions never overwrite observations; an older issue is ignored.
- [ ] The ΔT data status (observed, estimated, forecast) follows the loaded dataset, with no hardcoded boundary.
- [ ] Invalid or inconsistent data is rejected and the current dataset is kept.
- [ ] The last validated dataset is stored locally and the app works offline; updating never blocks startup or a calculation.
- [ ] The UT1 − UTC to ΔT conversion, including leap seconds, is covered by tests against published values.
- [ ] The Forecast classification stays separate from any Moon accuracy warning threshold.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Specification References

- "Computation settings that must be fixed and documented" (Time, Viewpoint)
- DATA-7
- NFR-R3

## Notes

- Created 2026-11-25 on the owner's decision during ZOD-EPH-002 planning. Not part of the Gate 1 critical path; do not start it without the owner's authorization.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
