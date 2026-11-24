# ZOD-IOS-003 - Verify local storage on iOS and exclude it from iCloud backup

## Metadata

- **ID:** ZOD-IOS-003
- **Category:** iOS (`ios/tasks/`)
- **Parent tasks:** [ZOD-FND-006](../../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) (iOS verification and the iOS side of the backup item); [ZOD-L10-002](../../localization/ZOD-L10-002-implement-first-launch-language-detection.md) (iOS language detection and `NSUserDefaults` backup)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

Verify on iOS the storage built in ZOD-FND-006 and the first-launch language handling built in ZOD-L10-002, and settle and implement the iOS half of the backup question (DATA-5, DATA-6).

## Implementation Details

Moved from ZOD-FND-006 (Android and host verification stay there):

- Run the storage verification on iOS: settings persist across a real process restart (two launches, force-quit between); a `SquareConfig` with every mode, both match types, custom rules and a non-UTC anchor round-trips; full and blocked storage give typed errors; the `sqlite3` package's build hook builds for iOS.
- **Backup (iOS side of the owner item found in the ZOD-FND-006 whole-branch review):** on iOS, Application Support is backed up to iCloud unless excluded (`NSURLIsExcludedFromBackupKey`). Decide and implement the exclusion for the square database and settings, against DATA-5 and DATA-6. The Android side (Auto Backup) stays in ZOD-FND-006 and was applied in ZOD-L10-002 (`android:allowBackup="false"`).

Moved from ZOD-L10-002:

- iOS `NSUserDefaults` (the settings store on iOS) is a recorded, unverified backup limit: verify and close it with the exclusion above.
- Verify first-launch language detection on an iOS device or simulator: the ordered device-language list resolves as on Android (`[fr, he]` gives Hebrew), the concrete `he` or `en` is saved, and a true system-language change is observed (the Android check used the per-app locale override only).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Storage passes the ZOD-FND-006 criteria on iOS: persistence across a real restart, round-trip of every `SquareConfig` shape, typed errors for full and blocked storage. *(ZOD-FND-006 criteria, iOS run.)*
- [ ] Settings and saved squares are excluded from iCloud and device backup on iOS, with a test or inspection that shows the exclusion flag set. *(Owner item from ZOD-FND-006; DATA-5, DATA-6.)*
- [ ] First-launch language detection behaves on iOS as specified in ZOD-L10-002 and survives a real system-language change. *(ZOD-L10-002, iOS run.)*

## Dependencies

- [ZOD-FND-006](../../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Android and host half (Completed)
- [ZOD-L10-002](../../localization/ZOD-L10-002-implement-first-launch-language-detection.md) — Android and host half (Done)
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build

## Specification References

- DATA-5
- DATA-6
- L-2

## Notes

- **Blocked: macOS access** (owner constraint 2026-11-20: no spending).
- **Timing.** The exclusion must be decided and applied before the stores are wired into an iOS production build. It does not block ZOD-SET-007 or ZOD-DAT-002 on Android, whose own backup item (Android Auto Backup) is already applied.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
