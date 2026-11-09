# ZOD-NFR-017 - Implement the ΔT-forecast and out-of-range warning banners

## Metadata

- **ID:** ZOD-NFR-017
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Surface [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md)'s two flagged conditions — a date outside the packaged ephemeris coverage, and a far-future date where ΔT is a forecast (reducing Moon accuracy) — as visible, informative banners rather than silent inaccuracy (R-2).

## Implementation Details

- "Out of range" banner: shown when a requested wheel/square date falls outside [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md)'s chosen data-file coverage, with the message content defined in that same task.
- "ΔT forecast" banner: shown for far-future dates where Moon accuracy is reduced, worded per the spec's own framing ("Delta T for the future is a forecast, so Moon accuracy drops for dates far in the future. The interface warns about this").

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Feedback" (neutral banner, `accent-soft` fill) for the visual treatment, reusing [ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md).

## Acceptance Criteria

- [ ] Requesting a date outside the packaged range shows the out-of-range banner instead of a silently wrong position.
- [ ] A far-future date shows the ΔT-forecast banner.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range
- [ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md) — Implement the banner component (neutral + danger)

## Specification References

- R-2
- "Time" row in "Computation settings that must be fixed and documented"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
