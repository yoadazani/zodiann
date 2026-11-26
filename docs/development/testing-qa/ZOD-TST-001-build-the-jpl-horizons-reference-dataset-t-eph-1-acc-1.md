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

- 2026-11-12 (product-owner decision): the shared reference **date set** is defined by [ZOD-TST-002](ZOD-TST-002-author-the-mean-node-formula-exactness-test-t-eph-2.md), as a versioned fixture in `packages/astro_core/test/fixtures/`. This task reuses those UTC instants for its JPL Horizons queries, so T-EPH-1 and T-EPH-2 run on the same dates. It may **add** instants (for example inside each body's retrograde windows, which the node's date set doesn't need), but must not drop or change the shared ones. If it does add instants, bump the fixture version.
- 2026-11-26 (owner decisions at planning; description and acceptance criteria unchanged): (1) the retrograde criterion applies to **Mercury to Pluto only** (Sun and Moon excluded), and every selected date is confirmed from JPL Horizons data, not our own calculations; (2) the backup package **tests** may restrict their assertions to the backup's own supported range, with no change to its implementation or range, no weakened guarantee, and explicit boundary tests preserved; (3) every comparison is at the same instant in Terrestrial Time: the approved conversion from 1972, and before 1972 no independently estimated UTC value; (4) node tolerance 0.01°, final only after the matching Swiss setting and frame are verified; (5) the far-future ΔT blocker is closed for the Swiss primary source on its verified accuracy through 2100-01-01, and the backup discrepancy stays open for ZOD-TST-005.
- 2026-11-26 (from [ZOD-FND-011](../../decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md) section 6): the dataset extends through 2100-12-31, on the production UTC-to-TT path at equivalent TT instants. Design: [`docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md`](../../superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md); plan: [`docs/plans/ZOD-TST-001-horizons-reference-dataset.md`](../../plans/ZOD-TST-001-horizons-reference-dataset.md).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
