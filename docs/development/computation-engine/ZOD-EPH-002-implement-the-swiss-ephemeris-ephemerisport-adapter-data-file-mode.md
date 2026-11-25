# ZOD-EPH-002 - Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Metadata

- **ID:** ZOD-EPH-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the primary position source: Swiss Ephemeris with packaged JPL-based data files, via the FFI binding proven in [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md).

## Implementation Details

- Implement `EphemerisPort` for all ten bodies (`sun`…`pluto`); the node uses [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md), not this adapter.
- Fixed, documented computation settings (must match exactly): geocentric viewpoint; apparent position (light time, aberration, light deflection, nutation); ecliptic and equinox of date (tropical), **no extra precession correction**; local time converted to UTC then to terrestrial time via ΔT.
- Return longitude speed (degrees/day) directly from the ephemeris, not derived by finite-differencing two calls (CRS-A1).
- Detect and surface "requested date outside packaged file coverage" as a typed error (uses [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md)'s chosen range), rather than silently returning an inaccurate value (R-2).
- Package/propagate a ΔT-forecast warning for dates far in the future (ΔT for the future is a forecast; Moon accuracy drops) — expose this as a flag the UI can turn into a banner (feeds ZOD-NFR banner work).

## Design Reference

No direct design reference applies — pure computation.

## Acceptance Criteria

- [ ] T-EPH-1 passes: Sun and Moon longitude within 1 arcsecond of JPL Horizons/Swiss Ephemeris reference data on 10+ dates.
- [ ] Requesting a date outside the packaged range returns the typed "out of range" error, not a silently wrong value.
- [ ] No code path applies an additional precession correction on top of the library's tropical-of-date output (guarded by the regression test T-EPH-1/ACC-5).
- [ ] Longitude speed is read from the ephemeris, never finite-differenced.

## Dependencies

- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract
- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range

## Specification References

- "Planet position"
- "Computation settings that must be fixed and documented"
- CRS-A1
- NFR-A1
- R-2

## Notes

- **From ZOD-FND-003 (2026-11-20; superseded by the 2026-11-24 note at the end of these Notes): blocked.** The owner split ZOD-FND-003: its Android half is verified (findings: [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md)) and its iOS half is pending (no macOS access; no spending allowed). The specification (R-7, ARCH-6) requires both platforms, so this task stays blocked until a real iOS computation is verified. Its status, scope and acceptance criteria are unchanged. The spike findings (section 6) list what this adapter must do, notably: check `usedSwissEphemerisFiles` on every call (a missing or out-of-range file falls back to Moshier without an error) and serialize calls to the library (global state, untested).

- **From ZOD-EPH-004 (owner decision of 2026-11-21, D5): this task owns the automatic source selection.** The astronomy-engine task text said to wire its adapter as the automatic fallback when the Swiss Ephemeris FFI binding is unavailable. That cannot be done there (this adapter did not exist), so it is deferred here: this task defines the primary adapter and its availability, and so decides when and how the astronomy-engine backup (`AstronomyEphemeris`, `packages/ephemeris_astronomy`, DI-swappable by one `ephemerisPortProvider` override) is selected. Nothing was wired in production by ZOD-EPH-004, and no `FallbackEphemerisPort` was added to `astro_core`. Facts for that decision: the backup's covered range is 1899-12-31 to 2100-01-01 (the Swiss adapter's will differ); its longitude is within 17.6 arcseconds of Horizons at equivalent TT instants, but at UTC instants the Moon is up to 78.6 arcseconds off late in the range because of the library's ΔT (`docs/spikes/ZOD-EPH-004-delta-t.md`), so the two sources disagree for the far-future Moon by design; release builds drop an unreferenced native library, so the backup's native asset enters a build only when app code references it; the vendored library keeps unsynchronised global state (the Pluto segment cache), so calls into it must be serialized like Swiss's; and the backup applies no gravitational light deflection for any body (documented in the adapter and the findings), so it does not match Swiss near solar conjunction.

- **iOS split (2026-11-24, owner decision):** ZOD-FND-003 is Done for its Android and shared scope; its iOS half is [ZOD-IOS-001](../ios/tasks/ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md). This task is no longer blocked by the iOS half: it is built and verified on the host and Android, and its adapter is exercised on iOS by [ZOD-IOS-001](../ios/tasks/ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md). **Risk accepted by that decision:** if iOS shows the binding or data-file packaging needs a different design, shared adapter code here may need rework. Scope and acceptance criteria are unchanged.

- **Owner decisions 2026-11-25 (planning):** the time conversion is the approved deviation in [`docs/decisions/ZOD-EPH-002-time-scale.md`](../../decisions/ZOD-EPH-002-time-scale.md): leap seconds from 1972, the library's historical ΔT before, a labelled continuous-UTC assumption after the table's validity end. From 1972 it replaces "via ΔT" in the computation-settings bullet. The "ΔT-forecast warning" flag is delivered as two separate outputs, the conversion basis and the ΔT data status; no accuracy warning threshold is set. Native calls use one shared state with a lock; the backup is selected automatically only if the Swiss library does not load. The backup's time conversion is [ZOD-EPH-006](ZOD-EPH-006-align-the-backup-source-time-scale-conversion-with-the-primary.md). The acceptance criteria are unchanged.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
