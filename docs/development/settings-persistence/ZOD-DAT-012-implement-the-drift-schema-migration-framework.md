# ZOD-DAT-012 - Implement the drift schema migration framework

## Metadata

- **ID:** ZOD-DAT-012
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Completed
- **Scope:** MVP

## Description

Harden the migration stub from [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) into a real, documented process so future schema changes (e.g., adding a field to `SquareConfig`) don't corrupt existing saved squares.

## Implementation Details

- Document the step-by-step process for adding a migration (bump `schemaVersion`, write an `onUpgrade` step, add a migration test).
- Add at least one real migration test (even a trivial v1→v2 additive-column case) as a template for future schema work.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [x] A simulated schema change (adding a nullable column) migrates existing stored data without loss. (`test/migrations_test.dart`, `rows written at v1 survive the upgrade unchanged`: three rows incl. Hebrew text, `migrateAndValidate`, rows equal, `note` null.)
- [x] The migration process is documented clearly enough for a future task to follow without re-deriving it. (`docs/storage/schema-migrations.md`: numbered procedure, exact commands, a worked example, what never to do, failure behaviour; the command list was run and leaves a clean diff.)

## Dependencies

- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- DATA-1 ("a schema version number and a migration when the structure changes")

## Notes

- 2026-11-22 (ZOD-FND-006): the stub exists: `applyMigrations` and the empty `migrationSteps` in `packages/shared_storage/lib/src/database/migrations.dart`, wired into `MigrationStrategy.onUpgrade`; a newer on-disk version throws `StorageException(unsupportedVersion)`. This task owns the documented process, the schema dumps and the first real step.
- 2026-11-22 (ZOD-DAT-012, completion): by owner decision the **shipped schema stays at version 1**; the migration is proved on a test-only `SimulatedV2Database` (same table plus a nullable `note`), so no unused column ships. The real version 2 belongs to the first task that needs a column; `docs/storage/schema-migrations.md` says how to add it. Found and fixed: drift runs `onUpgrade` without a transaction and writes `user_version` afterwards, so a failing step left its change in the file; `applyMigrations` now runs the range in one transaction. Plan: `docs/plans/ZOD-DAT-012-drift-migration-framework.md`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
