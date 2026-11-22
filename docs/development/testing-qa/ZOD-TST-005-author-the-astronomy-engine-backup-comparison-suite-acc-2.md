# ZOD-TST-005 - Author the astronomy-engine backup comparison suite (ACC-2)

## Metadata

- **ID:** ZOD-TST-005
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Run the same T-EPH-1 reference set against the astronomy-engine adapter, at the looser arcminute tolerance, to catch a fault in the backup source.

## Implementation Details

- Reuses [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md)'s fixture, swapping the `EphemerisPort` implementation under test to [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md)'s adapter.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Every body in the fixture is within 1 arcminute of the JPL Horizons reference using the astronomy-engine adapter.

## Dependencies

- [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) — Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)
- [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) — Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)

## Specification References

- ACC-2

## Notes

- **2026-11-22, from ZOD-EPH-004 (owner decision D12, Option 2): ΔT and the time scale of the comparison.** At **UT instants** the astronomy-engine adapter's Moon exceeds the 60-arcsecond bound of ACC-2 against JPL Horizons late in the range (78.6 arcseconds at 2099-12-31T23:59:59Z; about 3 arcseconds at 2025) because the library's UT-to-TT model (ΔT, 202.65 s at 2100) differs from Horizons's (about 69.18 s, held constant for the future); Swiss Ephemeris shows the same effect smaller (about 14 arcseconds at 2100). The theory is not at fault: asked at the same TT, every body is within 17.6 arcseconds over the 53 instants. ZOD-EPH-004 therefore judged its own ACC-2 test at **equivalent TT instants** (the adapter is called with the UTC instant; Horizons is asked at the TT the adapter's own conversion assigns, pinned by a device test), and documented ΔT separately in [`docs/spikes/ZOD-EPH-004-delta-t.md`](../../spikes/ZOD-EPH-004-delta-t.md). **This task must decide how its own T-EPH-1 comparison treats ΔT** (a TT-consistent reference as in ZOD-EPH-004, a restricted range for the Moon, or another bound), because a comparison at UT instants will meet the same effect. The specification's literal ACC-1 and ACC-2 text and ZOD-TST-001 are unchanged by that decision.
- **2026-11-21, from ZOD-EPH-004 (owner decision D6, Option A): the T-EPH-1 run stays here.** ZOD-EPH-004 proves ACC-2's bound with its own Horizons fixture and device test (all 53 instants of `reference_dates.json`, ten physical bodies, 60 arcseconds) and amended its first criterion to say so; this task keeps the shared T-EPH-1 comparison suite run against the astronomy-engine adapter. See the 2026-11-22 note above for the time scale.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
