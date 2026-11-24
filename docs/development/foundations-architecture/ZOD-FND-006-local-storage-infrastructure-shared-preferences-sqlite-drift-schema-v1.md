# ZOD-FND-006 - Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Metadata

- **ID:** ZOD-FND-006
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Completed (Android and host; iOS verification and the iOS backup item are [ZOD-IOS-003](../ios/tasks/ZOD-IOS-003-verify-local-storage-on-ios-and-exclude-it-from-icloud-backup.md))
- **Scope:** MVP

## Description

Stand up the two on-device storage mechanisms the data model requires, with a versioned schema so later structural changes can migrate safely.

## Implementation Details

- `shared_preferences` wrapper (key-based, typed accessors). **Amended 2026-11-22 (owner decision S2):** a generic typed key-value `SettingsStore`; the `UserSettings` class itself is ZOD-SET-007's (original wording: "wrapper for `UserSettings`").
- `drift` (SQLite) schema v1 for `SquareConfig` (embedding `HighlightRule` as a nested JSON column or child table) with a `schemaVersion` field and a migration stub.
- Wrap both behind a `packages/shared_storage` interface so feature code never touches `shared_preferences`/`drift` directly (keeps infrastructure swappable and testable).
- Implement the "storage unavailable" failure path: writes fail silently from the user's perspective except for a surfaced message (NFR-R1, feeds [ZOD-NFR-015](../performance-accessibility-reliability/ZOD-NFR-015-audit-invalid-input-handling-app-wide.md)).

## Design Reference

No direct design reference applies to the storage layer itself; the failure-path banner UI follows `design-reference/zodiann/MASTER.md` §10 "Feedback" (red banner for unavailable storage) and is implemented in [ZOD-NFR-015](../performance-accessibility-reliability/ZOD-NFR-015-audit-invalid-input-handling-app-wide.md).

## Acceptance Criteria

- [x] Settings persist across app restarts.
- [x] A `SquareConfig` round-trips through drift with all `HighlightRule` fields intact.
- [x] Simulating a full/blocked disk surfaces a typed error without crashing the app.
- [x] Schema version field is present and a no-op migration (v1→v1) is wired as the template for future migrations.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- DATA-1
- DATA-2
- NFR-R1

## Notes

- 2026-11-22 (implemented; Android and host, iOS not verified): plan `docs/plans/ZOD-FND-006-local-storage-infrastructure.md`. Public surface of `packages/shared_storage`: `SettingsStore`, `SettingsKey<T>`, `PrefsSettingsStore(SharedPreferencesAsync, {reporter})`, `SquareStore`, `openSquareStore(File, {reporter})`, `StorageException` (`unavailable`, `full`, `corrupt`, `unsupportedVersion`), `StorageFailureReporter`. Criteria evidence: persistence across a real process restart on the emulator (two launches, force-stop between); a `SquareConfig` with every mode, both match types, custom rules and a non-UTC anchor round-trips; full and blocked storage give typed errors (injected, and through the real drift isolate for a garbage file, an unopenable path and a newer-schema file); `schemaVersion` 1 and `applyMigrations` wired into `onUpgrade`. SQLite comes from the `sqlite3` package's build hook (a SHA-256-checked download at build time; no runtime network use).
- 2026-11-22: merged ([PR #51](https://github.com/yoadazani/zodiann/pull/51), merge commit `85e5f08`).
- **Open owner item (found in the whole-branch review), kept open and required before any task wires the stores into production:** Android Auto Backup is on by default (the manifest has no `allowBackup`, `fullBackupContent` or `dataExtractionRules`), so wired storage would be uploaded to the user's Google backup and restored on another device, against DATA-5 and DATA-6; on iOS, Application Support is backed up to iCloud unless excluded (`NSURLIsExcludedFromBackupKey`). Not changed here: nothing ships it yet (`shared_storage` is only a dev dependency of the app) and it changes app configuration. Decide before ZOD-SET-007 or ZOD-DAT-002 wire the stores.
- The 100-square limit (DATA-2) and the "Delete all data" flow are not enforced here: ZOD-DAT-002 and ZOD-DAT-010 own them (`SquareStore.deleteAll` and `SettingsStore.clear` are the primitives).

- **iOS split (2026-11-24, owner decision):** the iOS verification run and the iOS side of the backup item above (`NSURLIsExcludedFromBackupKey`, iCloud) moved to [ZOD-IOS-003](../ios/tasks/ZOD-IOS-003-verify-local-storage-on-ios-and-exclude-it-from-icloud-backup.md). The Android Auto Backup side of that item stays an owner decision here, and ZOD-L10-002 already turned it off in the manifest.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
