# ZOD-FND-006 - Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Metadata

- **ID:** ZOD-FND-006
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Stand up the two on-device storage mechanisms the data model requires, with a versioned schema so later structural changes can migrate safely.

## Implementation Details

- `shared_preferences` wrapper for `UserSettings` (key-based, typed accessors).
- `drift` (SQLite) schema v1 for `SquareConfig` (embedding `HighlightRule` as a nested JSON column or child table) with a `schemaVersion` field and a migration stub.
- Wrap both behind a `packages/shared_storage` interface so feature code never touches `shared_preferences`/`drift` directly (keeps infrastructure swappable and testable).
- Implement the "storage unavailable" failure path: writes fail silently from the user's perspective except for a surfaced message (NFR-R1, feeds [ZOD-NFR-015](../performance-accessibility-reliability/ZOD-NFR-015-audit-invalid-input-handling-app-wide.md)).

## Design Reference

No direct design reference applies to the storage layer itself; the failure-path banner UI follows `design-reference/zodiann/MASTER.md` §10 "Feedback" (red banner for unavailable storage) and is implemented in [ZOD-NFR-015](../performance-accessibility-reliability/ZOD-NFR-015-audit-invalid-input-handling-app-wide.md).

## Acceptance Criteria

- [ ] Settings persist across app restarts.
- [ ] A `SquareConfig` round-trips through drift with all `HighlightRule` fields intact.
- [ ] Simulating a full/blocked disk surfaces a typed error without crashing the app.
- [ ] Schema version field is present and a no-op migration (v1→v1) is wired as the template for future migrations.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- DATA-1
- DATA-2
- NFR-R1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
