# ZOD-TST-001 - Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)

## Metadata

- **ID:** ZOD-TST-001
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Produce the ≥50-date reference fixture (ten bodies, 1900–2100, including retrograde and start-of-year dates) that the core Sun/Moon/body accuracy tests run against.

## Implementation Details

- Pull reference longitudes from JPL Horizons for the same fixed computation settings as the app (geocentric, apparent, tropical-of-date, per "Computation settings that must be fixed and documented") so the comparison is apples-to-apples.
- Store as a versioned JSON fixture in the test assets, with provenance notes (query parameters used).
- Node tested separately against Swiss Ephemeris output, not JPL Horizons (per ACC-1's explicit carve-out).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Dataset covers ≥50 dates across 1900–2100, all ten bodies, including at least one date inside a known retrograde window per body and one near a year boundary.
- [ ] T-EPH-1 (owned by ZOD-EPH-002) and ACC-1 both consume this exact fixture.
- [ ] Node accuracy is validated against Swiss Ephemeris separately, documented as such.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Specification References

- T-EPH-1
- ACC-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
