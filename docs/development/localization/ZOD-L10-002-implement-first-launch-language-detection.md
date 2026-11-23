# ZOD-L10-002 - Implement first-launch language detection

## Metadata

- **ID:** ZOD-L10-002
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

On first launch, set the app language from the device language; default to English if unsupported.

## Implementation Details

- Read device locale once on first launch (not on every launch, since a later in-app override — ZOD-L10-003 — must persist and not be overwritten by this check again).
- Supported set: `he`, `en`. Anything else → English.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [x] A device set to Hebrew opens the app in Hebrew on first launch. (`first_launch_test.dart` through the real store and `ZodiannApp`; on an emulator with a Hebrew per-app locale: Hebrew title and the menu button on the right; see Completion notes.)
- [x] A device set to e.g. French opens the app in English on first launch. (`language_test.dart`, `first_launch_test.dart`, and the emulator with a French per-app locale: English, left to right.)
- [x] After the first launch, this detection never re-runs and silently override a user's explicit language choice. (`load_or_detect_test.dart`: a saved value wins and nothing is written; `first_launch_test.dart`: two launches over one store with a changed device language, and an explicit choice seeded beforehand; on the emulator the app stayed Hebrew after the locale went to English.)

## Dependencies

- ZOD-L10-001

## Specification References

- L-2

## Notes

- **From ZOD-L10-001 (2026-11-14):** `ZodiannLocalizations.supportedLocales` is generated from the ARB files in `packages/shared_ui/lib/l10n/`, with English first, so Flutter's default resolution already falls back to English. `ZodiannApp` uses that default resolution, so this task replaces it with the persisted first-launch choice (for example `MaterialApp.locale` or `localeResolutionCallback`).

## Completion notes

- **Delivered:** `resolveDeviceLanguage`, `languageKey` and `loadOrDetectLanguage` (`apps/astro_mobile/lib/src/localization/language.dart`), `appLocaleProvider`, `bootstrapOverrides` (`lib/src/bootstrap.dart`), an async `main()` that resolves the language before the first frame, `MaterialApp.locale` in `ZodiannApp`, `shared_storage` and `shared_preferences` as runtime dependencies of the app, and `android:allowBackup="false"`.
- **Owner-approved defaults (2026-11-23):** O1 the device's languages are matched in the order the user listed them (`[fr, he]` gives Hebrew); O2 Android Auto Backup off (iOS `NSUserDefaults` stays a recorded, unverified limit); O3 the concrete language (`he` or `en`) is saved at first launch, and what the settings control's "System" segment means is left to ZOD-L10-003 and ZOD-SET-002; O4 resolve before the first frame; O5 an invalid or corrupt saved language is treated as a first launch and overwritten.
- **Behaviour worth knowing:** storage failures never stop the app (an unreadable store resolves from the device and writes nothing; a failed write still returns the detected language); after the first launch a change of device language never changes the app's language by itself.
- **Verified on an emulator** with Android's per-app locale override (`cmd locale set-app-locales`; the emulator is not rootable, so this is not a true system-language change): Hebrew on cleared data gave a Hebrew title with the menu button on the right and the `language` key saved; switching the locale to English and relaunching without clearing data kept Hebrew; French on cleared data gave English. The release APK has no `INTERNET` permission, a merged manifest with `allowBackup=false`, and no `libsqlite3.so`.
- **Not covered:** a physical device and iOS (no macOS access); a read timeout on the first storage read (a store that never answers would hold the native splash; recorded as a known limit); announcing a bootstrap storage failure (ZOD-NFR-014, note added); the in-app override (ZOD-L10-003).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
