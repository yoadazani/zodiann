# ZOD-FND-011 - Decide and document the ephemeris data-file coverage range

## Metadata

- **ID:** ZOD-FND-011
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Swiss Ephemeris data files are split by time period; which range ships with the app determines both app size and the maximum usable date range in the UI (crossing table, square anchors). This decision must be made and documented before interface range limits (WH-16, SQ-10) are finalized.

## Implementation Details

- Evaluate candidate file sets against size budget and the spec's 10-year (3,660-day) crossing-table range and Excel's pre-1900 limitation.
- Record the chosen range and expected app size impact.
- Define the "outside range" user-facing message content (feeds ZOD-WHL and ZOD-SQR validation tasks, R-2).

## Design Reference

No direct design reference applies — this is a data/content decision. The resulting warning banner UI follows `design-reference/zodiann/MASTER.md` §10 "Feedback" (neutral banner for range warnings).

## Acceptance Criteria

- [ ] A documented date range is chosen and recorded.
- [ ] The "outside range" message text exists and is ready for translation (feeds ZOD-L10).
- [ ] The chosen range is cross-checked against the Excel pre-1900 limitation (EX limits section).

## Dependencies

- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS

## Specification References

- "Data files" row in "Decisions and implications"
- R-2
- "Limits that will remain in the file"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
