# ZOD-FND-007 Bundle Offline Fonts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship IBM Plex Sans, IBM Plex Sans Hebrew and the glyph fonts as TTF assets of `shared_ui`, registered at weights 300/400/500/600, with their OFL licences. Prove three things: they render offline, they cover every astrological glyph, and the release app declares no network permission and depends on no network package.

**Architecture:**
- The font files live in `packages/shared_ui/assets/fonts/`, one folder per family, each with its `OFL.txt`.
  - The fonts are declared under `flutter: fonts:` in `packages/shared_ui/pubspec.yaml`, and the licences under `flutter: assets:`.
  - They live in `shared_ui` because the theme that will use them (ZOD-UI-002's `TextTheme`) lives there.
  - The app picks them up through its `shared_ui` dependency. At runtime the engine sees each family as `packages/shared_ui/<family>`.
- A small `ZodiannFonts` constants class holds the family names, the package name and the glyph fallback order. UI-002 builds the text styles from it. **This task builds no text styles.**
- Verification:
  - **Pure-file tests** parse the TTFs (`cmap`, `OS/2`, `name` tables) and check SHA-256s.
  - **In-host rendering test:** loads the fonts with `FontLoader`.
  - **On-device integration test:** runs on emulator-5554 in airplane mode, through the real font manifest.
  - **Architecture test:** guards the manifests, the iOS plist, runtime dependencies and network APIs.
  - **Release APK check:** confirms the release APK's permissions and assets.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test, integration_test (SDK), yaml ^3.1.4 and crypto ^3.0.8 (dev, shared_ui), Android build-tools 36.0.0 `aapt2.exe`.

**Spec:** `assets/zodiann-specification.md` DATA-7 (offline, no network permission), DATA-8 (no external services; dependencies checked for network use). Design: `design-reference/zodiann/MASTER.md` §3. Task: `docs/development/foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md`.

## Facts established while planning (2026-11-13)

- **Sources.** All five are OFL 1.1 official releases, the latest of each, downloaded and inspected in the scratchpad (and re-verified by the plan reviewer).

  | Family | Release | URL | Files used (path in zip) |
  |---|---|---|---|
  | IBM Plex Sans | `@ibm/plex-sans@1.1.0` (2024-11-13) | `https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-sans%401.1.0/ibm-plex-sans.zip` | `ibm-plex-sans/fonts/complete/ttf/IBMPlexSans-{Light,Regular,Medium,SemiBold}.ttf`, `ibm-plex-sans/LICENSE.txt` |
  | IBM Plex Sans Hebrew | `@ibm/plex-sans-hebrew@1.1.0` (2024-11-13) | `https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-sans-hebrew%401.1.0/ibm-plex-sans-hebrew.zip` | `ibm-plex-sans-hebrew/fonts/complete/ttf/IBMPlexSansHebrew-{Light,Regular,Medium,SemiBold}.ttf`, `ibm-plex-sans-hebrew/LICENSE.txt` |
  | Noto Sans Symbols | `NotoSansSymbols-v2.003` (2023-06-27) | `https://github.com/notofonts/symbols/releases/download/NotoSansSymbols-v2.003/NotoSansSymbols-v2.003.zip` | `NotoSansSymbols/unhinted/ttf/NotoSansSymbols-Regular.ttf`, `OFL.txt` |
  | Noto Sans Symbols 2 | `NotoSansSymbols2-v2.008` (2023-10-13) | `https://github.com/notofonts/symbols/releases/download/NotoSansSymbols2-v2.008/NotoSansSymbols2-v2.008.zip` | `NotoSansSymbols2/unhinted/ttf/NotoSansSymbols2-Regular.ttf`, `OFL.txt` |
  | Noto Sans | `NotoSans-v2.015` (2024-11-20) | `https://github.com/notofonts/latin-greek-cyrillic/releases/download/NotoSans-v2.015/NotoSans-v2.015.zip` | `NotoSans/unhinted/ttf/NotoSans-Regular.ttf`, `OFL.txt` |

  - The npm packages `@ibm/plex-sans*` contain only woff/woff2, so they're not used.
  - Noto uses `unhinted/ttf`, which is what Google Fonts ships. Plex ships one TTF build.
  - Total added: about 2.4 MB.
- **What the font files contain (verified):**
  - All 11 TTFs have sfnt version `0x00010000`.
  - OS/2 `usWeightClass` is 300/400/500/600 for Light/Regular/Medium/SemiBold, and 400 for the Noto files.
  - Family name: nameID 16 where present, else nameID 1. That equals the registered family for all 11 files.
  - cmap: Plex has 3/1 format 4. Noto has 3/1 format 4 and 3/10 format 12.
  - The four Plex weights have distinct advance sums for both test strings. At 40 px:
    - Plex Sans: 393.04 / 395.04 / 398.28 / 400.36.
    - Plex Hebrew: 339.96 / 341.24 / 344.80 / 347.36.
- **Glyph set.** MASTER §3's Glyphs row, cross-checked against every symbol in `design-reference/zodiann/_source/*.{html,js}`, is 29 code points:
  - **Signs:** U+2648–U+2653 (♈–♓).
  - **Bodies:** U+2609 ☉, U+263D ☽, U+263F ☿, U+2640 ♀, U+2642 ♂, U+2643 ♃, U+2644 ♄, U+2645 ♅, U+2646 ♆, U+2647 ♇, U+260A ☊.
  - **Retrograde:** U+211E ℞.
  - **Aspects:** U+260C ☌, U+26B9 ⚹, U+25A1 □, U+25B3 △, U+260D ☍.
- **Coverage of the 29 (exact):**
  - Noto Sans Symbols: all except {U+2609, U+211E, U+25A1, U+25B3}.
  - Noto Sans Symbols 2: {U+2609, U+25A1, U+25B3}.
  - Noto Sans: {U+211E}.
  - Every Plex file: none.
  - The chain covers 29/29. U+FE0E is in no font. That's expected: the shaper consumes it, and its emoji behaviour is UI-002's criterion 3.
- **IBM Plex Sans Hebrew** covers U+05D0–U+05EA, A–Z, a–z and 0–9. It lacks U+2032 ′ and U+2033 ″, which Plex Sans has. The mockup's Hebrew stack falls back to Plex Sans (`_source/kit.css:108`). That's a UI-002 handoff.
- **Product-owner decisions (2026-11-13):**
  1. Bundle Noto Sans Regular as a **third glyph fallback** after Symbols and Symbols 2, so ℞ comes from a bundled font. FND-007 criterion 2 reads as met with this addition. Record it in the FND-007, UI-002 and ABT-007 Notes. MASTER.md isn't edited.
  2. **Criterion 3 applies to the release manifest.** `src/debug` and `src/profile` keep Flutter's tooling-only `INTERNET`, which hot reload, DevTools and on-device `flutter test` need. Release is verified by a source test on `src/main` plus `aapt2 dump permissions` on the release APK.
  3. **The five `OFL.txt` files ship inside the app**, as `shared_ui` assets, so every build carries the licence text (OFL §2). ABT-007 later registers and shows them.
- **Manifests today:**
  - `src/main/AndroidManifest.xml` declares no permissions.
  - `src/debug` and `src/profile` declare `INTERNET`.
  - iOS has no `.entitlements` file and no ATS, Bonjour or local-network keys in `Info.plist`.
- **Dependencies:**
  - `pubspec.lock` has `http` and `web_socket*` only through dev tooling (melos, test). The guard therefore checks runtime closures.
  - `pub deps --json` lists 10 workspace members plus the root `zodiann_workspace`.
  - Every member's runtime closure is free of the network list below (the reviewer checked).
- **Emulator:** emulator-5554 runs Android 9. `adb shell cmd connectivity airplane-mode enable|disable` works, and `settings get global airplane_mode_on` confirms the state.

## Global Constraints

- No network at runtime (DATA-7). No dependency that opens a connection (DATA-8). New dependencies are `yaml` and `crypto` (dev, shared_ui) and `integration_test` (SDK, dev, app). All are dev-only.
- Font files are copied byte-for-byte from the releases above. Don't subset, rename internally or convert them. Each family folder carries its licence verbatim, as `OFL.txt`.
- Family names: `IBM Plex Sans`, `IBM Plex Sans Hebrew`, `Noto Sans Symbols`, `Noto Sans Symbols 2`, `Noto Sans`.
- Weights 300/400/500/600 for both Plex families. The glyph fonts are 400 only.
- No text styles, `TextTheme` or `fontFamily` on the theme. That's UI-002.
- Don't stage `.idea/` or `.qodo/`.
- Toolchain:
  - In Bash, first `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin:$LOCALAPPDATA/Android/Sdk/platform-tools"`.
  - Run Flutter and Dart through `cmd //c "…"`, which must contain no `^`.
  - On Windows, normalize `\` to `/` in paths.
- **Before every commit:** `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"` exits 0.

## Out of scope

- **ZOD-DAT-011:** the full dependency and runtime privacy audit, and the network-traffic capture. It may extend `no_network_test.dart`.
- **ZOD-NFR-016:** exact version pinning and the NFR-R3 dynamic-loading audit.
- **ZOD-UI-002:** text styles.
- **ZOD-ABT-007:** displaying attribution and licences.

FND-007's guard is a standing regression check for its own criterion 3 and for the task's "no runtime fetch of fonts" detail. It is not the DAT-011 audit.

## Review Focus

1. **A family name in `TextStyle` that doesn't match the registration** (for example, a missing `package: 'shared_ui'`) silently falls back to the system font. Covered by Task 4's on-device test, which goes through the real font manifest.
2. **A pubspec weight that disagrees with its file.** The registration is misleading, and it renders wrongly on web. On mobile the engine takes the weight from OS/2. Covered by Task 1's OS/2 weight test.
3. **Hebrew in a Latin-only family** shows boxes. Covered by Task 1's Hebrew cmap test and Task 2's Hebrew rendering test.
4. **Fonts or licences missing from the release APK.** Covered by Task 4's APK listing check.
5. **A plugin manifest merging `INTERNET` into release.** Covered by Task 4's `aapt2 dump permissions`.

---

### Task 1: Font assets, registration and file-level proofs

**Files:**
- Create: `packages/shared_ui/assets/fonts/{ibm-plex-sans,ibm-plex-sans-hebrew,noto-sans-symbols,noto-sans-symbols-2,noto-sans}/` holding the TTFs from Facts plus `OFL.txt` in each folder.
- Create: `packages/shared_ui/assets/fonts/SOURCES.md`. One row per TTF: file name, release, URL, path in the zip, byte size and SHA-256 (from `sha256sum`).
- Create: `packages/shared_ui/lib/src/theme/zodiann_fonts.dart`.
- Modify: `packages/shared_ui/lib/shared_ui.dart` (export it).
- Modify: `packages/shared_ui/pubspec.yaml`:
  - `flutter: fonts:`;
  - `flutter: assets:` listing the five `OFL.txt` files;
  - dev dependencies added with `cmd //c "cd packages\\shared_ui && fvm flutter pub add dev:yaml dev:crypto"`, giving yaml 3.1.4 and crypto 3.0.8, the latest versions.
- Create: `packages/shared_ui/test/support/sfnt.dart`, `packages/shared_ui/test/fonts/font_assets_test.dart`, `packages/shared_ui/test/fonts/glyph_coverage_test.dart`.

**Interfaces:**
- Produces:
  ```dart
  abstract final class ZodiannFonts {
    static const String package = 'shared_ui';
    static const String plexSans = 'IBM Plex Sans';
    static const String plexSansHebrew = 'IBM Plex Sans Hebrew';
    static const String notoSansSymbols = 'Noto Sans Symbols';
    static const String notoSansSymbols2 = 'Noto Sans Symbols 2';
    static const String notoSans = 'Noto Sans';
    /// MASTER §3 order, plus Noto Sans for ℞ (FND-007 decision).
    static const List<String> glyphFallback = [notoSansSymbols, notoSansSymbols2, notoSans];
  }
  ```
- Produces (test support): `final class Sfnt { Sfnt(Uint8List bytes); bool get isTrueType; Set<int> get codePoints; int get weightClass; String get familyName; }`
  - `isTrueType`: sfnt version `0x00010000`.
  - `codePoints`: code points that map to a **non-zero glyph id** in the platform 3 (or 0) subtables of format 4 or 12. Format 4 resolves `idRangeOffset`, and the `0xFFFF` sentinel is excluded.
  - `weightClass`: `OS/2.usWeightClass`.
  - `familyName`: `name` table, platform 3 encoding 1, nameID 16, else nameID 1, decoded as UTF-16BE.

- [ ] **Step 1: Write the failing tests.** In `font_assets_test.dart` (plain `test`, paths relative to the package root):
  - `the pubspec registers exactly these families, files and weights`: `loadYaml(pubspec)['flutter']['fonts']` mapped to `{family: {asset: weight}}` equals this table (assets under `assets/fonts/<folder>/`):
    - Plex Sans: Light 300, Regular 400, Medium 500, SemiBold 600.
    - Plex Sans Hebrew: the same four.
    - Each Noto file: 400, declared explicitly.

    The family keys equal the `ZodiannFonts` constants.
  - `every registered file is a TrueType font whose OS/2 weight matches its declaration`.
  - `every registered file names its own family`: `Sfnt.familyName == family`.
  - `every font folder carries its OFL licence, shipped as an asset`: each folder has `OFL.txt` containing `SIL OPEN FONT LICENSE Version 1.1`, and `flutter: assets:` lists exactly those five paths.
  - `every font file matches the SHA-256 recorded in SOURCES.md`: parse SOURCES.md rows (file name, 64-hex SHA-256). The set of files equals the 11 registered assets, and `sha256.convert(bytes).toString()` equals each recorded value.

  In `glyph_coverage_test.dart`:
  - `the glyph fallback chain covers all 29 MASTER glyphs`: for each code point, some font in `ZodiannFonts.glyphFallback` covers it. The reason lists the misses.
  - `each glyph font covers exactly the expected subset of the 29`: `codePoints ∩ glyphs29` equals the literal sets in Facts, for the three Noto files and for each of the 8 Plex files (empty). This guards against the parser over-reporting.
  - `℞ comes from Noto Sans`: U+211E is in neither Symbols font and is in Noto Sans.
  - `IBM Plex Sans Hebrew covers Hebrew letters, Latin and digits`: U+05D0–U+05EA, A–Z, a–z, 0–9.
  - `IBM Plex Sans covers Latin and digits`.

- [ ] **Step 2: Run them and see them fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/fonts"`. Expected: FAIL. First the cause is `ZodiannFonts` undefined; once only that is added, it's missing files and the missing pubspec `fonts` key.

- [ ] **Step 3: Add the files and the registration.** Download the five zips to the scratchpad and extract the files from Facts into the folders above, with each licence renamed to `OFL.txt`. Run `sha256sum` and write SOURCES.md. Add the `fonts:` and `assets:` blocks, the dev dependencies, `zodiann_fonts.dart` and the export.

- [ ] **Step 4: Run them and see them pass.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test"`. Expected: all pass (the 44 existing tests plus the new ones).

- [ ] **Step 5: Mutation proofs.** Apply each mutant, see the named test fail, then revert:
  - **F1:** swap the `weight:` of Plex Light and Regular in the pubspec. Fails the OS/2 weight test.
  - **F2:** drop `notoSans` from `glyphFallback`. Fails the chain coverage test (U+211E).
  - **F2b:** make the format-4 parser ignore `startCode` (count every code point from the previous segment's `endCode + 1` up to this segment's `endCode`). Fails the exact-subset test: every Plex file then reports all 29 glyphs.
  - **F3:** rename the pubspec family `Noto Sans Symbols 2` to `Noto Sans Symbols2`. Fails the registration test.
  - **F4:** delete `noto-sans/OFL.txt`. Fails the licence test.
  - **F4b:** change one hex digit of a SOURCES.md SHA-256. Fails the SHA-256 test.

- [ ] **Step 6: Gates, then commit.** Run the lint and test gates, then commit as `feat(ZOD-FND-007): bundle Plex, Plex Hebrew and Noto glyph fonts as shared_ui assets`. List F1–F4b in the commit body.

### Task 2: In-host rendering proof and specimen

**Files:**
- Create: `packages/shared_ui/test/fonts/font_rendering_test.dart`.

**Interfaces:**
- Consumes: `ZodiannFonts` and the asset folders from Task 1.

- [ ] **Step 1: Write the failing test.**
  - Call `TestWidgetsFlutterBinding.ensureInitialized()` at the top of `main()`.
  - In `setUpAll`, load each family with one `FontLoader('packages/shared_ui/<family>')`. Add all its files with `addFont(Future.value(ByteData.sublistView(File(asset).readAsBytesSync())))`, then `await loader.load()`.
  - Measure with `TextPainter` at `fontSize: 40`, `TextStyle(fontFamily: family, package: ZodiannFonts.package, fontWeight: w)`.
  - Tests:
    - `IBM Plex Sans renders four distinct weights`: widths of `'Zodiann 0123456789'` at w300/400/500/600 form a set of 4.
    - `IBM Plex Sans Hebrew renders four distinct weights`: the same with `'זודיאן 0123456789'`.
    - `the bundled families do not render as the test fallback font`: each family's sample renders at a width different from `fontFamily: 'zodiann-missing-family'`. The samples are:
      - `'Zodiann'` for Plex Sans;
      - the Hebrew string for Plex Hebrew;
      - `'♈☽☌'` for Symbols;
      - `'☉△□'` for Symbols 2;
      - `'℞'` for Noto Sans.
  - When `ZODIANN_FONT_DIR` is set, a `testWidgets` specimen writes `font_specimen.png` (via `RepaintBoundary.toImage` inside `tester.runAsync`, as in UI-001's harness).
    - It shows each family and weight line in English and Hebrew.
    - It shows the 29 glyphs through `fontFamilyFallback: ZodiannFonts.glyphFallback` and `package: ZodiannFonts.package`.
    - It's for visual review only.

- [ ] **Step 2: Run it and see it fail.** Comment out the `setUpAll` loading and run `cmd //c "cd packages\\shared_ui && fvm flutter test test/fonts/font_rendering_test.dart"`. Expected: FAIL, because everything renders as the fallback font. Then restore the loading. The files already exist, so the honest RED is "fonts not loaded".

- [ ] **Step 3: Run it and see it pass.** Same command. Expected: PASS. Run the specimen with `ZODIANN_FONT_DIR` set to the scratchpad and look at the PNG: four visibly different weights per family, Hebrew drawn, and all 29 glyphs drawn (no boxes).

- [ ] **Step 4: Mutation proof.** **F5:** load `IBMPlexSans-Regular.ttf` in place of `IBMPlexSans-Light.ttf` in the loader. Fails the four-weights test, because w300 resolves to Regular and gives three distinct widths.

- [ ] **Step 5: Gates, then commit.** Run the lint and test gates, then commit as `test(ZOD-FND-007): in-host rendering proof for the bundled fonts`.

### Task 3: No-network architecture guard

**Files:**
- Modify: `test/architecture/dependency_closure.dart`.
  - Add `bool includeDevDependencies = true` to `findForbiddenDependencies`. When false, the start node contributes `directDependencies` only.
  - The default keeps ARCH-2 unchanged.
  - Update the doc comment that states the closure rule.
- Modify: `test/architecture/dependency_closure_test.dart`. One case, reusing the real-output fixture `core_dev` (`⇢dev helper → uipkg → flutter`): `findForbiddenDependencies(deps, 'core_dev')` finds `flutter`, and with `includeDevDependencies: false` the result is empty. Also, `findForbiddenDependencies(deps, 'core_reg', includeDevDependencies: false)['flutter']` equals `['core_reg', 'mid', 'uipkg', 'flutter']`, so `false` still follows regular dependencies.
- Create: `test/architecture/no_network_test.dart`.

**Interfaces:**
- Produces: `findForbiddenDependencies(json, package, {Set<String> forbidden, bool includeDevDependencies = true})`.

- [ ] **Step 1: Write the failing tests.** In `no_network_test.dart` (run from the repo root, like `pure_dart_test.dart`):
  - `DATA-7: the release Android manifest declares no network permission`.
    - `src/main/AndroidManifest.xml` has no `uses-permission` naming `android.permission.INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` or `CHANGE_NETWORK_STATE`.
    - A comment cites PO decision 2: debug/profile keep tooling-only `INTERNET`, and release is checked by `aapt2`.
  - `DATA-7: iOS declares no network capability`: no `*.entitlements` file under `apps/astro_mobile/ios/`, and `Runner/Info.plist` has none of `NSAppTransportSecurity`, `NSAllowsArbitraryLoads`, `NSLocalNetworkUsageDescription`, `NSBonjourServices`.
  - `DATA-8: no workspace member depends on a network package at runtime`.
    - Members are the `pub deps --json` nodes with `kind == 'root'` and `name != json['root']`, with `expect(members, hasLength(10))`.
    - For each member, `findForbiddenDependencies(..., forbidden: networkPackages, includeDevDependencies: false)` is empty.
    - `networkPackages = {'http', 'dio', 'google_fonts', 'web_socket', 'web_socket_channel', 'http2', 'grpc', 'cronet_http', 'cupertino_http', 'firebase_core', 'sentry', 'sentry_flutter', 'cached_network_image', 'flutter_cache_manager'}`.
  - `DATA-8: no lib/ source opens a network connection or fetches fonts`.
    - Scan `apps/*/lib/**.dart` and `packages/*/lib/**.dart`, ignoring text after `//`.
    - The patterns are `\bHttpClient\b`, `\bHttpServer\b`, `\bWebSocket\b`, `\bRawDatagramSocket\b`, `\b\w*Socket\.(connect|startConnect|bind)\(`, `\bNetworkImage\(`, `\bImage\.network\(`, `\bNetworkAssetBundle\(`, and imports of `package:http/` or `package:google_fonts/`.
    - Expect none.

- [ ] **Step 2: Run them and see them fail.** Run `cmd //c "fvm dart test test/architecture"`. Expected: FAIL, compile error on `includeDevDependencies`. Then add the parameter. The code under test is already clean, so each new test is seen failing by mutant (Step 4).

- [ ] **Step 3: Run them and see them pass.** Same command. Expected: all pass (23 existing tests plus the new ones).

- [ ] **Step 4: Mutation proofs.** Revert each after it fails:
  - **N1:** add `<uses-permission android:name="android.permission.INTERNET"/>` to the main manifest. Fails the manifest test.
  - **N2:** add `http: ^1.6.0` to `shared_ui` `dependencies` and run `cmd //c "fvm flutter pub get"`. Fails the closure test with the path `shared_ui -> http`. Revert with `git checkout -- packages/shared_ui/pubspec.yaml pubspec.lock`, then `pub get`.
  - **N3:** add `import 'dart:io';` and `final _ = HttpClient();` to `zodiann_fonts.dart`. Fails the source scan.
  - **N4:** create `apps/astro_mobile/ios/Runner/Runner.entitlements`. Fails the iOS test.

- [ ] **Step 5: Gates, then commit.** Run the lint and test gates, then commit as `test(ZOD-FND-007): no-network guard for manifests, runtime dependencies and sources`.

### Task 4: On-device offline proof, release APK check, close-out

**Files:**
- Modify: `apps/astro_mobile/pubspec.yaml`: `dev_dependencies: integration_test: sdk: flutter`.
- Create: `apps/astro_mobile/integration_test/offline_fonts_test.dart`.
- Modify: the task files for FND-007, UI-002 and ABT-007 (Notes); `docs/development/TASKS.md`; `docs/PROGRESS.md`.

**Interfaces:**
- Consumes: `ZodiannFonts` via `package:shared_ui/shared_ui.dart`. The engine loads the fonts from the app's font manifest, with no `FontLoader`.

- [ ] **Step 1: Write the integration test.**
  - Call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
  - Measure width with `TextPainter`, `fontSize: 40`, `package: ZodiannFonts.package`.
  - Tests:
    - `IBM Plex Sans: four distinct weights, none the system font`. For each `w`, first assert (b) `width(family, w) != width('zodiann-missing-family', w)`. Then, after the loop, assert (a) `{width(family, w) : w ∈ 300, 400, 500, 600}` has 4 elements.
    - `IBM Plex Sans Hebrew: four distinct weights, none the system font`: the same with the Hebrew string.
    - `the device is offline`: `InternetAddress.lookup('example.com').timeout(const Duration(seconds: 5))` either throws `SocketException` or returns an empty list. A `TimeoutException` fails the test with the reason "DNS lookup hung; offline state not confirmed".

- [ ] **Step 2: Run it on emulator-5554, online then offline.**
  - **RED for the offline check:** with airplane mode disabled (`adb -s emulator-5554 shell settings get global airplane_mode_on` prints `0`), run `cmd //c "cd apps\\astro_mobile && fvm flutter test integration_test -d emulator-5554"`. Expected: `the device is offline` FAILS (the lookup returns addresses), and the font tests pass.
  - Run `adb -s emulator-5554 shell cmd connectivity airplane-mode enable`. Expected: the setting prints `1`.
  - Re-run. Expected: all pass. If the offline test still fails, also run `svc wifi disable` and `svc data disable`, re-run, and record which was needed.
  - Always restore afterwards, even if a run failed: `airplane-mode disable`, and re-enable wifi and data.
  - **Mutant F6:** change the measured family to `'IBM Plex Sans X'`. Expected: the test fails on assertion (b), because the width equals the fallback font's width. Revert.

- [ ] **Step 3: Release APK check.**
  - Run `cmd //c "cd apps\\astro_mobile && fvm flutter build apk --release"`.
  - Run `"/c/Users/user/AppData/Local/Android/Sdk/build-tools/36.0.0/aapt2.exe" dump permissions apps/astro_mobile/build/app/outputs/flutter-apk/app-release.apk`. Expected: no `android.permission.INTERNET` or other network permission. androidx's signature-level `com.zodiann.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` is acceptable.
  - Run `unzip -l apps/astro_mobile/build/app/outputs/flutter-apk/app-release.apk | grep -c 'assets/flutter_assets/packages/shared_ui/assets/fonts/.*\.ttf$'`. Expected: `11`.
  - The same count with `OFL\.txt$`. Expected: `5`.
  - Record the outputs in PROGRESS.

- [ ] **Step 4: Gates, then commit.** Run `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"` (exit 0). Then commit `apps/astro_mobile/pubspec.yaml`, `pubspec.lock` and `apps/astro_mobile/integration_test/offline_fonts_test.dart` as `test(ZOD-FND-007): on-device airplane-mode font proof and release APK check`. The commit body records the online-RED, offline-GREEN and F6 outcomes, plus the aapt2 and unzip outputs.

- [ ] **Step 5: Whole-branch code review** (opus, per the workflow). Fix Critical and Important findings test-first, and defer minors.

- [ ] **Step 6: Close out the docs.**
  - **FND-007 task file:** status Done, the three criteria ticked. Notes:
    - PO decision 1 (Noto Sans third fallback), with the coverage fact;
    - PO decision 2 (criterion 3 applies to the release manifest; debug/profile tooling `INTERNET`; `aapt2` evidence);
    - PO decision 3 (`OFL.txt` shipped as assets);
    - iOS verified by static check only (no Mac); the on-device check ran on Android 9 x86;
    - `integration_test` (dev) is the app's first plugin, so the outstanding iOS build will generate a Podfile or SwiftPM setup.
  - **UI-002 Notes:**
    - Use `ZodiannFonts.glyphFallback` as the glyph `fontFamilyFallback`, with `package: ZodiannFonts.package`.
    - In Hebrew mode, add `fontFamilyFallback: [ZodiannFonts.plexSans]`, as the mockup does, so ′ and ″ come from Plex Sans.
  - **ABT-007 Notes:** Noto Sans (OFL) is bundled as the third glyph fallback, so add it to the licences list. The `OFL.txt` assets are at `packages/shared_ui/assets/fonts/*/OFL.txt`.
  - **PROGRESS Technical Decisions:** the three PO decisions. Also:
    - fonts are `shared_ui` assets, named via `ZodiannFonts` with `package: ZodiannFonts.package`;
    - the no-network guard checks runtime closures (`includeDevDependencies: false`), because `test`/`melos` bring in `http`/`web_socket*` as dev-only dependencies.
  - **PROGRESS Architecture Conventions:** text styles name bundled fonts only through `ZodiannFonts` plus `package: ZodiannFonts.package`, and a new dependency must keep `test/architecture/no_network_test.dart` green.
  - **TASKS.md and PROGRESS:** FND-007 Done, UI-001 merged, next task ZOD-UI-002.
  - Commit as `docs(ZOD-FND-007): close out offline fonts`, then push, open the PR, and record the PR link.

## Plan review

### Round 1: Needs user decision (0 Critical, 7 Important, 12 Minor, 2 Needs user decision)

The reviewer re-derived every font fact in the plan (zip paths, sizes, OS/2 weights, name-table families, exact cmap coverage, SHA-256s) and confirmed them.

**Important (all applied):**
- **I1:** the APK commands used relative paths that fail. Now repo-relative, with `aapt2.exe` and exact `grep -c` counts.
- **I2:** parser over-reporting would make the coverage test pass vacuously. Added the exact-subset test and mutant F2b, and defined `codePoints` precisely.
- **I3:** the offline check was never seen failing. Added an online RED run, the wifi/data fallback, and an always-restore step.
- **I4:** "none the system font" was undefined, and F6's failure reason was wrong. Defined assertions (a) and (b); F6 now expects (b).
- **I5:** no Out-of-scope section, and the overlap with DAT-011, NFR-016 and ABT-007 was unstated. Added the section and the ABT-007 Note.
- **I6:** Tasks 1–3 committed without the lint gate. Added a gate before every commit.
- **I7:** PROGRESS only got status updates. Added Technical Decisions and Architecture Conventions entries.

**Minor (all applied):**
- **M1:** a Symbols sample glyph the font lacks. Changed to `♈☽☌`.
- **M2:** the specimen was missing `package`.
- **M3:** F5 wording, plus `ensureInitialized`.
- **M4:** SOURCES.md was checked for presence only. Now a real SHA-256 check with `crypto` 3.0.8 (latest); mutant F4b.
- **M5:** the socket patterns had gaps. Broadened them.
- **M6:** member enumeration undefined. Now defined, with a count of 10.
- **M7:** reuse the `core_dev` fixture; doc comment updated.
- **M8:** N2's revert procedure.
- **M9:** PATH setup and `cmd //c` usage.
- **M10:** the UI-002 handoff for ′ and ″ in Hebrew.
- **M11:** Review Focus 2 wording.
- **M12:** a Note about the first plugin.

**Needs user decision (resolved by the product owner, 2026-11-13):**
- **N1:** criterion 3 applies to the release manifest. Debug/profile keep tooling `INTERNET` (PO decision 2).
- **N2:** the `OFL.txt` files ship in the app as `shared_ui` assets (PO decision 3).

### Round 2: Approve after corrections (0 Critical, 2 Important, 3 Minor)

The reviewer confirmed that every round-1 correction and PO decision is applied. It re-ran the existing suites (23 architecture tests, 44 shared_ui tests) and the member count (10).

**Important (both applied):**
- **I1:** mutant F2b could not fail, because every code point in these fonts' format-4 segments maps to a glyph. It was replaced with the "ignore `startCode`" mutant, which makes every Plex file report all 29 glyphs (re-derived by the reviewer).
- **I2:** Task 4 never committed its code. Step 4 now commits the integration test and the dependency change, with the device and APK evidence in the commit body.

**Minor (all applied):**
- **M1:** F6 depended on assertion order. Now (b) per weight first, then (a).
- **M2:** the offline test's timeout behaviour was undefined. Now defined.
- **M3:** the closure-flag test now also proves that `false` still follows regular dependencies.

No open items remain after two rounds.
