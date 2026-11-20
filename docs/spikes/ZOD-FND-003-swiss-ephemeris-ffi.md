# ZOD-FND-003: Swiss Ephemeris FFI spike, findings

**Status: the Android half is verified. The iOS half is pending. ZOD-FND-003 is not complete and must not be reported as complete until a real iOS computation is verified (section 8).** Written 2026-11-20 for whoever picks up ZOD-EPH-002 and for ZOD-REL-002 and ZOD-REL-003. Plan: [`docs/plans/ZOD-FND-003-swiss-ephemeris-ffi-spike-android.md`](../plans/ZOD-FND-003-swiss-ephemeris-ffi-spike-android.md).

## 1. What was proved on Android

| Claim | Evidence (2026-11-20) |
|---|---|
| The unmodified Swiss Ephemeris source builds through the Flutter toolchain | `packages/ephemeris_swiss/hook/build.dart` (native assets, `native_toolchain_c`) compiles the nine library sources for arm64-v8a, armeabi-v7a and x86_64; `flutter build apk --debug` succeeded and the debug APK holds `lib/<abi>/libswisseph.so` for all three |
| One FFI call returns a correct longitude, and the data files are really used | `apps/astro_mobile/integration_test/swiss_ephemeris_spike_test.dart` on the `Pixel_9_Pro_API_35` emulator (x86_64, Android 15, **16 KB page size**, `getconf PAGE_SIZE` = 16384): Sun and Moon at three UT instants (1900-06-15 06:00, 2000-01-01 12:00, 2026-11-20 00:00) are within **0.03 to 0.24 arcseconds** of JPL Horizons (bound 1 arcsecond), every call returned flags 258 (`SEFLG_SWIEPH` + `SEFLG_SPEED`) and an empty warning |
| A correct number alone does not prove the files are read, so a control proves it | with an empty data directory the same Sun call returns the Moshier flag and a warning (`SwissEph file 'sepl_18.se1' not found in PATH ... using Moshier eph.`) |
| The data files are packaged and readable from the app sandbox | both `.se1` files are in the APK under `assets/flutter_assets/packages/ephemeris_swiss/assets/ephe/`; the test copies them to `getApplicationSupportDirectory()/ephe/` (`/data/user/0/com.zodiann.app/files/ephe/`), checks each copy's length, and Swiss Ephemeris reads them from there |
| The vendored source is unchanged | `native/swisseph/MANIFEST.json` plus `test/architecture/swisseph_vendored_test.dart` (git blob ids, SHA-256, licence files present); 27 of 27 staged blobs equal the upstream blobs; the check also passes in a fresh `git clone -c core.autocrlf=true` |

The reference values are in `packages/ephemeris_swiss/test/fixtures/reference_longitudes.json` (Horizons quantity 31, geocentric, apparent, UT). The Horizons manual does not say outright whether quantity 31 uses the mean or the true equinox of date; the results agree with Swiss Ephemeris's apparent true-of-date longitude to under 0.25 arcsecond, whereas a mean-equinox reference would differ by the nutation in longitude (about 14 arcseconds in 2000), so quantity 31 is the true-of-date longitude. That conclusion is from this comparison, not from Horizons documentation.

## 2. Build setup

- Pinned toolchain: Flutter 3.50.0 (`.fvmrc`; its Dart is 3.14.0), Android NDK **28.2.13676358** (Flutter 3.50's default `ndkVersion`, and the one installed), CMake not needed. The shell's own `dart` on this machine is 3.6.0: put `/c/Users/user/fvm/versions/3.50.0/bin` first on `PATH`.
- Packages: `hooks ^2.2.0`, `code_assets ^2.0.0`, `native_toolchain_c ^0.19.4`, `logging ^1.3.0`, `ffi ^2.1.4` (the versions the pinned SDK's own `package_ffi` template names), dev `ffigen ^23.0.0` (see section 3).
- The hook returns without building unless the target OS is Android (plan decision D3). Host tests (`dart test`, `flutter test`) therefore need no C toolchain; this machine has no MSVC. The iOS target is added by the iOS half.
- Native assets are enabled by default in Flutter 3.50 (`features.dart`); no flag is needed.
- Run on a device: `ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk`, then from `apps/astro_mobile`: `flutter test integration_test/swiss_ephemeris_spike_test.dart -d <device id>`.
- Bindings: `dart run tool/ffigen.dart` from `packages/ephemeris_swiss` regenerates `lib/src/ffi/swisseph_bindings.g.dart` (deterministic, formatted, passes `--fatal-infos`). It needs libclang (LLVM was installed with `winget install LLVM.LLVM` on 2026-11-20 with the owner's approval; free).

## 3. Gotchas found

1. **ffigen 20 conflicts with Melos 8.10.1** (`cli_util ^0.4.2` against `>=0.5.0`); ffigen 22.1 and later accept both. Used `ffigen ^23.0.0` (published 2026-10-06).
2. **ffigen 23 deprecates the YAML config**; the repository uses the programmatic `FfiGenerator` in `tool/ffigen.dart`.
3. **The header takes the `_WIN32` branch on a Windows host** (`sweodef.h` includes `wtypes.h`). The generator parses as `--target=aarch64-linux-android24` with the NDK sysroot and clang's builtin include directory. The bound functions use only `int`, `double` and `char*`, so the target does not change the Dart output.
4. **A named `Logger` cannot change its level** unless `hierarchicalLoggingEnabled` is set: the hook must use the root `Logger('')` (the first device run failed on this).
5. **Flutter bundles a package's assets only for regular dependencies.** As a dev dependency the hook still ran and the library was built, but the `.se1` assets were not bundled and the load failed. Hook-emitted data assets need the experimental `dartDataAssets` feature, which is off. Owner decision D5 (2026-11-20): `ephemeris_swiss` is a regular dependency of `astro_mobile`.
6. **Horizons returns rows in chronological order whatever the time-list order.** The fixture script sorts the instants and checks every row's printed date; a first run had attached values to the wrong dates.
7. **`LICENSE.TXT` upstream is a symlink to `LICENSE`** (git mode 120000, 7 bytes); `swedll.h` is CRLF upstream. Both are vendored byte for byte; the scoped `.gitattributes` (`-text`) is what keeps them unchanged on a Windows checkout.
8. **Release APKs do not contain `libswisseph.so`** (`NativeAssetsManifest.json` is 45 bytes) unless app code reaches the `@Native` bindings; the cause is inferred (the AOT build drops unreferenced native assets), not isolated. The first use in ZOD-EPH-002 will bring it in.

## 4. Measurements (for ZOD-REL-002 and ZOD-REL-003)

| Item | Value |
|---|---|
| `libswisseph.so` size (hook output, as in the debug APK) | arm64-v8a 557,904 B; armeabi-v7a 572,556 B; x86_64 644,768 B |
| `LOAD` segment alignment (`llvm-readelf -lW`, NDK 28.2) | `0x4000` (16 KB) on **all three ABIs**, including armeabi-v7a |
| Hook build time | about 5 to 9 s per ABI (four hook runs in one 65.9 s debug build of three ABIs, which includes Gradle and the app) |
| Release APK, `--split-per-abi`, without the dependency edge (dev dependency only) | arm64-v8a 18,537,162 B; armeabi-v7a 16,157,122 B; x86_64 19,788,968 B; contains neither the library nor the data |
| Release APK with the regular dependency | arm64-v8a 20,200,286 B; armeabi-v7a 17,820,246 B; x86_64 21,452,092 B (+1,663,124 B each: the data files only, because the release build does not include the library, see gotcha 8) |
| Data files (spike subset, 1800 to 2400) | `sepl_18.se1` 484,061 B and `semo_18.se1` 1,304,771 B raw; 432,691 B and 1,229,963 B stored in the APK (deflate saves about 7%) |
| Upstream data set for scale | `sepl_*.se1` about 0.48 to 0.60 MB per 600-year file; `semo_*.se1` about 1.3 to 1.4 MB per file (the range decision is ZOD-FND-011) |

## 5. Decisions

- **Data packaging (decided for Android, to be confirmed on iOS):** flat `.se1` files as Flutter package assets of `ephemeris_swiss`, copied once to the application support directory and read by Swiss Ephemeris from there. Reason: the library needs a real file path and an APK asset is inside a zip; the files are already compressed, so a compressed bundle gains about 7%, not worth a custom unpacker. The `_18` pair is a spike subset; **ZOD-FND-011 owns the coverage range.** A production loader must copy only when a file is missing or its size differs (the spike copies every run).
- **Native assets versus CMake/Xcode: PROVISIONAL.** Native assets were chosen for Android because one build hook compiled all three ABIs through the Flutter toolchain with no Gradle or CMake files and no Xcode edits. This is **not final** because iOS is untested. It is reversed if the hook cannot build `libswisseph` for iOS under Xcode or the result cannot be loaded there; the fallback is CMake on Android and an Xcode target on iOS (ARCH-6 allows either).
- **The release app carries the data files** (+1.66 MB per ABI) because the regular dependency is the only way Flutter bundles them; revert that one line in `apps/astro_mobile/pubspec.yaml` if needed before FND-011 settles the range.

## 6. What ZOD-EPH-002 must know

1. **Always check `SwissCalcResult.usedSwissEphemerisFiles`.** A missing or out-of-range file is not an error to the library: it falls back to Moshier, sets `SEFLG_MOSEPH` and writes a warning. At 1799-12-31 with only `sepl_18` present the call returned flags 260 and `SwissEph file 'sepl_12.se1' not found ... using Moshier eph.` The adapter must turn that into `OutOfCoveredRange` (R-2), never an approximate longitude.
2. **Swiss Ephemeris keeps global state** (the ephemeris path, open file handles). Calls from several isolates or threads must not interleave. **This was not tested in the spike**; the plan's own tests set the path per test and run sequentially. The crossing solver runs in an isolate (ARCH-1), so EPH-002 must decide and test how calls are serialized.
3. `calcUt` takes UT, as `swe_calc_ut` does; the wrapper rejects non-UTC `DateTime` values with `ArgumentError`, like `EphemerisPort`.
4. The speed (`xx[3]`) comes straight from the library with `SEFLG_SPEED`, as CRS-A1 requires.
5. Only `swe_set_ephe_path`, `swe_close`, `swe_version` and `swe_calc_ut` are bound; extend `tool/ffigen.dart` for more.

## 7. Licensing facts for ZOD-REL-003

- The Moshier fallback is part of the same library and shares its dual license (the AGPL path was chosen, ZOD-FND-010; applied in ZOD-FND-015). No build containing Swiss Ephemeris was given to anyone; the source-availability policy's tag rule has not been triggered.
- Still open: the data files' license (Astrodienst question Q2) and which AGPL version the vendor means (Q5).
- `ffigen`'s own license adds that code it generates is owned by the owner of the input file; the generated `swisseph_bindings.g.dart` is derived from the AGPL-licensed `swephexp.h`, and the project is AGPL-3.0-only.
- New packages: 19 lock entries, read and recorded in `docs/licensing/third-party-inventory.md`.

## 8. The iOS half: still to do (owner constraint 2026-11-20: no spending of any kind)

**macOS access is not available, and spending on it is not allowed, so this half is pending for that reason only.** Closing ZOD-FND-003 needs all of these, each with the evidence named:

1. The hook builds `libswisseph` for iOS under Xcode: add `OS.iOS` (and the iOS architectures and SDKs) to `hook/build.dart`; `flutter build ios` succeeds. *Evidence: the build log and the linked binary.*
2. The data files are copied into the app and readable from the iOS sandbox. *Evidence: the test's length check passes on iOS.*
3. The same `swiss_ephemeris_spike_test.dart` passes on an iOS simulator or a device, with the same flag and negative-control assertions. *Evidence: the run output.*
4. The native-assets-versus-Xcode decision is confirmed or reversed (section 5). *Evidence: a note here and in PROGRESS Technical Decisions.*
5. The iOS binary size and build time are recorded in section 4.
6. The unrelated iOS items already queued in `docs/PROGRESS.md` Blockers can be run in the same session.

Also still open on Android: **arm64-v8a was built and its alignment checked, but never executed** (only the x86_64 emulator ran). The Galaxy S22 Ultra can run the same test over adb if the owner authorizes it.

**Options for the owner, none used or decided here:**

- A Mac the owner already has access to at no cost.
- GitHub's standard macOS runners: per GitHub's billing documentation read on 2026-11-20 they are free in public repositories (this repository is public), limited to five concurrent macOS jobs, and larger runners are always charged ([About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions), [How use of GitHub Actions is measured](https://docs.github.com/en/billing/concepts/product-billing/github-actions)). ZOD-FND-004's task file excluded a macOS runner, so using one would be a new owner decision, and the terms must be re-read before relying on them.

## 9. Reproduce

```
export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH
export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0
export ANDROID_HOME='C:\Users\user\AppData\Local\Android\Sdk'
flutter pub get && git checkout -- packages/shared_ui/lib/l10n
dart test test/architecture/swisseph_vendored_test.dart          # source unchanged
cd apps/astro_mobile
flutter test integration_test/swiss_ephemeris_spike_test.dart -d emulator-5554   # the device run
flutter build apk --debug && unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep -E "swisseph|se1"
```
