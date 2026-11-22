# ZOD-EPH-004 - Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)

## Metadata

- **ID:** ZOD-EPH-004
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the backup position source (astronomy-engine, C version via FFI) used both as a runtime fallback and as an independent test oracle.

## Implementation Details

- Same FFI-binding process as [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md), applied to the astronomy-engine C library.
- Implement `EphemerisPort` for the ten bodies at arcminute-level accuracy; the node is computed by formula ([ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md)), since astronomy-engine doesn't provide it per the spec's data-sources table.
- Wire as the automatic fallback when the Swiss Ephemeris FFI binding is unavailable (ARCH-4: swapping is a single injection).

## Design Reference

No direct design reference applies — pure computation / native binding.

## Acceptance Criteria

- [ ] ACC-2 passes: proved on this task's own device test over the 53 instants of `reference_dates.json`, ten physical bodies, within 1 arcminute of JPL Horizons at equivalent TT instants (the position model; the UT-to-TT conversion is documented separately in `docs/spikes/ZOD-EPH-004-delta-t.md`); the shared T-EPH-1 suite run is tracked by ZOD-TST-005.
- [ ] Swapping from Swiss Ephemeris to this backup requires only a DI override, no feature-code changes.
- [ ] Node longitude from this path still uses the ZOD-EPH-001 formula, not an astronomy-engine-derived value.

## Dependencies

- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract
- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula

## Specification References

- "Data sources, in order of priority" (astronomy-engine row)
- ACC-2
- ARCH-4

## Notes

- **Criterion 1 amended (owner decisions of 2026-11-21 and 2026-11-22).** The original wording was: "ACC-2 passes: same reference-date set as T-EPH-1, within 1 arcminute of JPL Horizons." (a) 2026-11-21 (D6, Option A): T-EPH-1 (ZOD-TST-001) is not built, and ZOD-TST-005 owns the T-EPH-1 run against this adapter, so this task proves ACC-2's bound on its own device test over all 53 instants of `packages/astro_core/test/fixtures/reference_dates.json` and ten physical bodies. (b) 2026-11-22 (D12, Option 2): the comparison is made at equivalent TT instants, because the library's UT-to-TT model (ΔT) differs from Horizons's for future dates (the Moon is 78.6 arcseconds from Horizons at 2099-12-31 at UTC instants and 3.4 at the TT the library assigns). The 60-arcsecond bound, the covered range (1899-12-31 to 2100-01-01) and the ΔT model are unchanged; ΔT and the limits of the TT test are documented in [`docs/spikes/ZOD-EPH-004-delta-t.md`](../../spikes/ZOD-EPH-004-delta-t.md). The specification's literal ACC-1 and ACC-2 text is not edited.
- **Implementation Details bullet 3 ("Wire as the automatic fallback…") is deferred to ZOD-EPH-002 by the owner's decision of 2026-11-21 (D5):** the Swiss adapter does not exist yet, so there is nothing to fall back from; this task delivers the DI-swappable adapter (criterion 2, proved by a host test) and no production fallback wiring. No criterion is edited for this.
- **Scope: Android and host. iOS is not verified** (no macOS access, no spending: owner constraint of 2026-11-20); the iOS checklist is in the findings.
- **Findings:** [`docs/spikes/ZOD-EPH-004-astronomy-engine-adapter.md`](../../spikes/ZOD-EPH-004-astronomy-engine-adapter.md) (including the proposed, unapplied `EphemerisPort` wording for an analytically derived speed). Plan: [`docs/plans/ZOD-EPH-004-astronomy-engine-adapter.md`](../../plans/ZOD-EPH-004-astronomy-engine-adapter.md).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
