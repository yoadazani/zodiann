# ZOD-SET-007 - Implement `UserSettings` persistence wiring

## Metadata

- **ID:** ZOD-SET-007
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Connect every control built in [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) through 006 to the `UserSettings` storage wrapper ([ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md)), so every change survives app restart.

## Implementation Details

- **Define the `UserSettings` data class first** (deferred here from ZOD-FND-012 by product-owner decision, 2026-11-12). It's an immutable class with JSON, holding exactly the spec's fields: theme, time zone, aspect orbs, visible bodies, node type, ephemeris source, zodiac system, square defaults. Use the resolutions of D-1, D-3 and D-5/D19 available at that time, and the conventions set by FND-012 (hand-written JSON, constructor validation, `FormatException` on invalid input). `Body` JSON already exists in `astro_core`.
- Each setting row writes through immediately (no separate "Save" step for settings — matches the mockup's direct-manipulation controls).
- Verify every field in the `UserSettings` entity (theme, time zone, aspect orbs, visible bodies, node type, ephemeris source, zodiac system, square defaults) round-trips through storage.

## Design Reference

No direct design reference applies — this is the persistence wiring behind the already-built [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md)–006 screens.

## Acceptance Criteria

- [ ] Every settings row persists across a full app restart.
- [ ] `UserSettings` JSON round-trip (ZOD-FND-012) covers every field exercised by the Settings screen.

## Dependencies

- [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) through [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md)
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- DATA-1
- DATA-2
- "UserSettings" row in the data model table

## Notes

- 2026-11-22 (ZOD-FND-006): build `UserSettings` on the generic `SettingsStore` / `SettingsKey<T>` in `packages/shared_storage` (keys are declared by the feature, none exist yet); a read of a wrong-typed value throws `StorageException(corrupt)`, so default and carry on. Android Auto Backup is on by default and would upload the stored data to the user's Google backup (and iOS Application Support to iCloud), against DATA-5 and DATA-6; **Android is settled by ZOD-L10-002 (2026-11-23): `android:allowBackup="false"`, pinned by `platform_links_test.dart`.** iOS is not: `NSUserDefaults` (what `shared_preferences` writes) is part of iCloud and device backups and cannot be excluded per key, and the SQLite file needs `NSURLIsExcludedFromBackupKey` (ZOD-DAT-002); unverified, no macOS access. See the ZOD-FND-006 Notes.
- **2026-11-23 (ZOD-L10-002):** the language is already saved from the first launch, as `SettingsKey<String>('language')` with the value `he` or `en` (`apps/astro_mobile/lib/src/localization/language.dart`), through `SharedPreferencesAsync` (on Android a DataStore file). `UserSettings` must **include or migrate that key** so it does not become a second source of truth (L-3 says the choice is saved in the user settings), and must use the same async preferences backend: mixing in the legacy `SharedPreferences` API would hide the saved value.
- **From ZOD-L10-007 (2026-11-14):** `UserSettings` stores visible bodies as `Body` keys and orbs keyed by `AspectKind.name`, never display names (L-9). Entity-valued fields are typed as their key enum.

- **iOS split (2026-11-24, owner decision):** the iOS side of the backup item above (`NSURLIsExcludedFromBackupKey`, iCloud) is [ZOD-IOS-003](../ios/tasks/ZOD-IOS-003-verify-local-storage-on-ios-and-exclude-it-from-icloud-backup.md). Android Auto Backup is already off (ZOD-L10-002), so this task is not held up by it on Android; the exclusion must be in place before an iOS production build wires the stores.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
