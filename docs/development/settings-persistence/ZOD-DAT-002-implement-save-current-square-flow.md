# ZOD-DAT-002 - Implement "Save current square" flow

## Metadata

- **ID:** ZOD-DAT-002
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the primary action that captures the Square screen's current mode/anchor/size/highlight-rules into a new named `SquareConfig`.

## Implementation Details

- Opens the save dialog ([ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md)) prompting for a name, default pre-filled suggestion (e.g., based on anchor/date).
- Enforces the 100-saved-squares cap (DATA-2) — saving beyond the cap must show a clear message, not silently fail or silently evict an old entry.

## Design Reference

`design-reference/zodiann/components/components_dark.png` "Save square" dialog (name field, Cancel/Save buttons).

## Acceptance Criteria

- [ ] Saving creates a `SquareConfig` that, when reopened, reproduces the exact same square (mode, anchor, size, highlights).
- [ ] Attempting to save a 101st square is blocked with a clear message.

## Dependencies

- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes
- [ZOD-SQR-019](../gann-square/ZOD-SQR-019-build-the-controls-panel-layout-and-summary-row.md) — Build the controls-panel layout and summary row

## Specification References

- DATA-2
- UC10

## Notes

- **From ZOD-UI-013 (2026-11-23):** open it with `showZodiannDialog<T>(context, builder: ...)` returning a `ZodiannDialog(title:, message:, actions:)`; the caller localizes every string and builds the `ZodiannButton`s. Escape, a scrim tap and the back button complete the future with `null` and run no callback, so treat only an explicit value (the confirm button pops `true`) as consent. Put `autofocus: true` on Cancel for a destructive confirmation. There is **no re-entry guard**: disable the trigger while the future is pending, or a second tap stacks a second dialog. For the naming dialog pass the field as `content` (a `ZodiannTextField`, label `Name`); it sits 16 below the message and 24 above the actions, Escape dismisses it while the field has focus, and the dialog rises above the keyboard. The saved name is the explicit result (`pop(name)`), `null` means cancelled.
- 2026-11-22 (ZOD-FND-006): save through `SquareStore.save` (an upsert by id; `createdAt` is the caller's); the 100-square limit is this task's rule, not the store's; `openSquareStore(File)` takes the database path from the app. Android Auto Backup is on by default and would upload the stored data to the user's Google backup (and iOS Application Support to iCloud), against DATA-5 and DATA-6; **Android is settled by ZOD-L10-002 (2026-11-23): `android:allowBackup="false"`, pinned by `platform_links_test.dart`.** iOS is not: `NSUserDefaults` (what `shared_preferences` writes) is part of iCloud and device backups and cannot be excluded per key, and the SQLite file needs `NSURLIsExcludedFromBackupKey` (ZOD-DAT-002); unverified, no macOS access. See the ZOD-FND-006 Notes.

- **iOS split (2026-11-24, owner decision):** the iOS side of the backup item above (`NSURLIsExcludedFromBackupKey`, iCloud) is [ZOD-IOS-003](../ios/tasks/ZOD-IOS-003-verify-local-storage-on-ios-and-exclude-it-from-icloud-backup.md). Android Auto Backup is already off (ZOD-L10-002), so this task is not held up by it on Android; the exclusion must be in place before an iOS production build wires the stores.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
