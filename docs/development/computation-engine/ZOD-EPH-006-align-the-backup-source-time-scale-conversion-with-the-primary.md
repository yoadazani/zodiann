# ZOD-EPH-006 - Align the backup source's time-scale conversion with the primary source

## Metadata

- **ID:** ZOD-EPH-006
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Make the astronomy-engine backup obtain terrestrial time the same way the Swiss Ephemeris adapter does, so that switching to the backup changes no time handling. Scheduled after ZOD-EPH-002.

## Implementation Details

- Use the one conversion defined for ZOD-EPH-002 ([decision record](../../decisions/ZOD-EPH-002-time-scale.md)): leap seconds from 1972, the continuous-UTC assumption and its label after the table's validity end.
- Historical handling before 1972 must follow the same policy for both sources **without needing the Swiss library at run time** (the backup is used when that library does not load). The two libraries' ΔT models differ before 1972, so this task must resolve how, and record the decision.
- Change the backup adapter and its fixtures only within this task, with the changed figures reviewed.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] From 1972, both sources assign the same TT to the same UTC instant (within 1 millisecond), from a single shared conversion definition.
- [ ] Before 1972 the two sources follow the same documented policy; any remaining TT difference is measured and recorded.
- [ ] Instants after the table's validity end are handled explicitly and carry the same basis label for both sources.
- [ ] Tests cover the 1972 boundary, leap-second steps, the validity end and far-future instants for both sources.
- [ ] The remaining position differences per body, due to the two libraries' astronomical models, are measured and documented.
- [ ] Using either source as the fallback changes no time handling.
- [ ] The accuracy comparison for the backup (ACC-2) still passes, with regenerated fixtures reviewed.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) — Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)

## Specification References

- "Computation settings that must be fixed and documented" (Time)
- ACC-2
- ARCH-4

## Notes

- Created 2026-11-25 on the owner's decision during ZOD-EPH-002 planning. Recommended before ZOD-TST-005.
- The vendored library offers a global ΔT hook (`Astronomy_SetDeltaTFunction`); it also keeps unsynchronised global state, so calls must be serialized (ZOD-EPH-004).
- The backup's covered range (ending 2100-01-01T12:00Z) is not changed by this task without a separate decision.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
