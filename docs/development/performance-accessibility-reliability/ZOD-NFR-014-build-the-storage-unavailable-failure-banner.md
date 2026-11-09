# ZOD-NFR-014 - Build the storage-unavailable failure banner

## Metadata

- **ID:** ZOD-NFR-014
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Wire the red "storage unavailable" banner ([ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md)) to the real failure path from [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md), so a blocked/full disk degrades gracefully with a visible message instead of silently losing writes.

## Implementation Details

- When any write to `shared_preferences`/drift fails, show the banner and keep the app otherwise fully functional (read-only against last-known state) rather than crashing or silently discarding the user's change.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Feedback" (red banner for unavailable storage).

## Acceptance Criteria

- [ ] NFR-R1 passes: simulating a storage failure shows the banner and the app continues functioning without saving.
- [ ] No crash occurs on a simulated full/blocked disk.

## Dependencies

- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md) — Implement the banner component (neutral + danger)

## Specification References

- NFR-R1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
