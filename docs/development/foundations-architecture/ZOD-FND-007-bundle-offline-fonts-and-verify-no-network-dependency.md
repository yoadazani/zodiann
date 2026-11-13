# ZOD-FND-007 - Bundle offline fonts and verify no network dependency

## Metadata

- **ID:** ZOD-FND-007
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Done
- **Scope:** MVP

## Description

Ship IBM Plex Sans, IBM Plex Sans Hebrew, and the Noto Sans Symbols families as app assets (TTF/OTF, not the mockup's woff2) so the app works fully offline (DATA-7) and matches the design system's typography.

## Implementation Details

- Source TTF/OTF builds of the families referenced in `design-reference/zodiann/assets/fonts/` (the shipped woff2 files there are for the mockups only, per MASTER.md §3).
- Register them in `pubspec.yaml` with the correct weights (300/400/500/600).
- Verify the app does not request network permission (DATA-7) and that no package declares a runtime fetch of fonts/scripts.

## Design Reference

`design-reference/zodiann/assets/fonts/` (font family and weight list), `design-reference/zodiann/MASTER.md` §3 for the exact family/weight-per-role table. No visual design is invented here — this task only sources production-grade font files equivalent to the mockup fonts.

## Acceptance Criteria

- [x] All four weight variants of both families render correctly offline (airplane-mode test).
- [x] Noto Sans Symbols / Symbols 2 cover all glyphs listed in MASTER.md §3's Glyphs row (♈–♓, ☉☽☿♀♂♃♄♅♆♇☊, ℞, aspect glyphs).
- [x] No network permission is declared in the Android manifest or iOS entitlements.

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- DATA-7
- MASTER.md §3

## Notes

- **Fonts shipped (2026-11-13):** IBM Plex Sans and IBM Plex Sans Hebrew (300/400/500/600), Noto Sans Symbols, Noto Sans Symbols 2 and Noto Sans, as `shared_ui` assets (`packages/shared_ui/assets/fonts/`, sources and SHA-256s in `SOURCES.md`), named through `ZodiannFonts` with `package: ZodiannFonts.package`. Plan: `docs/plans/ZOD-FND-007-bundle-offline-fonts.md`.
- **Criterion 2 — product-owner decision (2026-11-13):** Noto Sans Symbols and Symbols 2 together cover 28 of MASTER §3's 29 glyphs; neither has ℞ (U+211E), and neither Plex family does. **Noto Sans Regular is bundled as the third glyph fallback** (`ZodiannFonts.glyphFallback` = Symbols, Symbols 2, Noto Sans), giving 29/29 from bundled fonts. Criterion 2 reads as met with this addition. MASTER.md is not edited.
- **Criterion 3 — product-owner decision (2026-11-13):** applies to the **release** manifest. `android/app/src/debug` and `src/profile` keep Flutter's tooling-only `INTERNET` (hot reload, DevTools, on-device tests). Evidence: `test/architecture/no_network_test.dart` (main manifest, iOS entitlements/plist, runtime dependency closures, `lib/` network APIs) and `aapt2 dump permissions` on the release APK (no network permission; only androidx's signature-level `com.zodiann.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). iOS has no network permission to declare; checked statically (no `.entitlements`, no ATS/Bonjour/local-network keys).
- **Licences — product-owner decision (2026-11-13):** each family's `OFL.txt` ships in the app as a `shared_ui` asset (OFL §2). ZOD-ABT-007 displays them.
- **Criterion 1 evidence:** `apps/astro_mobile/integration_test/offline_fonts_test.dart` on emulator-5554 (AOSP Android 9, x86 with ARM translation): online run fails only "the device is offline"; with `cmd connectivity airplane-mode enable` all pass. Flutter 3.50 lists this image as unsupported for `flutter test -d`, so the test runs as a debug APK: `fvm flutter build apk --debug -t integration_test/offline_fonts_test.dart`, `adb install -r`, `adb shell am start -n com.zodiann.app/.MainActivity`, then `adb logcat -s flutter` (look for "All tests passed"). The release APK contains all 11 TTFs and 5 `OFL.txt`.
- **iOS:** static checks only (no Mac). `integration_test` (dev) is the app's first plugin, so the outstanding iOS build (FND-005) will generate a Podfile / SwiftPM setup.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
