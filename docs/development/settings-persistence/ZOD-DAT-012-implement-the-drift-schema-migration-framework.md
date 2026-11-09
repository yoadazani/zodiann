# ZOD-DAT-012 - Implement the drift schema migration framework

## Metadata

- **ID:** ZOD-DAT-012
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Harden the migration stub from [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) into a real, documented process so future schema changes (e.g., adding a field to `SquareConfig`) don't corrupt existing saved squares.

## Implementation Details

- Document the step-by-step process for adding a migration (bump `schemaVersion`, write an `onUpgrade` step, add a migration test).
- Add at least one real migration test (even a trivial v1→v2 additive-column case) as a template for future schema work.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A simulated schema change (adding a nullable column) migrates existing stored data without loss.
- [ ] The migration process is documented clearly enough for a future task to follow without re-deriving it.

## Dependencies

- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- DATA-1 ("a schema version number and a migration when the structure changes")

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
