# ZOD-EPH-004 astronomy-engine `EphemerisPort` adapter (backup and oracle), Android and host: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). Nothing here is independent enough for subagents: each task consumes the previous task's output (vendored source, then the pure math, then the binding, then the adapter, then the device runs).

**Goal:** Deliver an `EphemerisPort` over the astronomy-engine C library (FFI, Android and host-testable logic) for the ten bodies, within 1 arcminute of JPL Horizons (ACC-2), with the longitude speed derived **analytically** from the library's own position and velocity vectors, and prove how good that speed is against Swiss Ephemeris, including at planetary stations.

**Architecture:** astronomy-engine's two files (`astronomy.c`, `astronomy.h`) are vendored byte-for-byte under `native/astronomy_c/upstream/`. A small project-authored C shim (`native/astronomy_c/zodiann_astronomy_shim.c`) calls the library and returns flat doubles (apparent longitude, geocentric position and velocity in the true ecliptic of date), so the FFI surface has no struct-by-value. A build hook (native assets, Android only, as in ZOD-FND-003) compiles both. All arithmetic that is not a library call (the longitude rate, normalization, range check, node, result mapping) is pure Dart in `ephemeris_astronomy` and is tested on the host with literal vectors; the native source is injected behind an interface. Accuracy is proved on the Android emulator by integration tests in `apps/astro_mobile`.

**Tech Stack:** Dart 3.14 / Flutter 3.50.0 (`.fvmrc`), `hooks ^2.2.0`, `code_assets ^2.0.0`, `native_toolchain_c ^0.19.4`, `logging ^1.3.0`, `ffi ^2.1.4`, dev `ffigen ^23.0.0` (the versions ZOD-FND-003 proved; libclang already installed), Android NDK 28.2.13676358, `integration_test`, astronomy-engine C (MIT).

**Spec:** `assets/zodiann-specification.md`: "Data sources, in order of priority" (line 350, astronomy-engine row), ACC-2 (line 382), ARCH-4 (line 552), CRS-A1 (line 373), R-2, NFR-A1 (apparent, true equinox of date). Task file: `docs/development/computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md`. Dependencies: ZOD-FND-002 and ZOD-EPH-001 (both done). Build pattern and findings to reuse: `docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`, `docs/plans/ZOD-FND-003-swiss-ephemeris-ffi-spike-android.md`.

## Global Constraints

- **CRS-A1 (spec line 373):** "The longitude speed (degrees per day) comes directly from the ephemeris, and retrograde is a negative speed." **Owner decision, 2026-11-21: no finite differences, and no finite-difference exception.** The speed is derived analytically from the state vectors the library provides (D1). The adapter and every document call it that, and none claims it equals the derivative of the fully apparent longitude: the derivatives of the light-time and aberration corrections are omitted (D1 lists what else).
- **Do not modify the existing contract** (`EphemerisPort` and its documentation, `astro_core`) without first documenting the exact proposed change and its implications (Task 8 writes it up; nothing is edited in `astro_core`).
- **ACC-2 and the speed comparison are separate acceptance criteria** (D6, D7). The Horizons longitude bound is 1 arcminute for every body; Pluto's accuracy is also measured and reported on its own.
- **Stop-and-report rule (owner):** if the speed comparison against Swiss Ephemeris is insufficient by the thresholds in D7, **stop and report the findings**. Do not switch to finite differences and do not weaken CRS-A1.
- **Scope: Android and host only.** iOS stays deferred (no macOS access, no spending, owner constraint 2026-11-20). The task file does not mention iOS, but R-7 and ARCH-6 require it for the FFI binding of the primary source; this task records the iOS checklist for astronomy-engine in the findings and does not claim it verified.
- **Contract (`EphemerisPort`, read 2026-11-21):** UTC-only (`ArgumentError` otherwise); physical bodies geocentric, apparent, longitude on the true ecliptic and equinox of date, no extra precession correction; `Body.node` answered by `meanAscendingNode` for any instant, **before** the covered-range check, via `with MeanAscendingNodeFormula` (no re-implementation, and the `125.04452` and `1934.136261` literals stay out of this package); out of range gives `OutOfCoveredRange`, never an approximate position (R-2); results normalized with `normalizeDegrees`; every `EphemerisSuccess` holds an `EclipticPosition(longitude, speed)`.
- **Upstream unchanged:** the astronomy-engine files are copied byte-for-byte with exact version and origin recorded; its MIT notice is kept (`LICENSE`). The project-authored shim is AGPL-3.0-only like the rest.
- **Pinned toolchain (NFR-R3):** `export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH`, `export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0`, `export ANDROID_HOME='C:\Users\user\AppData\Local\Android\Sdk'` before every command. After `flutter pub get`, run `git checkout -- packages/shared_ui/lib/l10n` (ZOD-FND-003 findings, section 9).
- **No network at run time** (`test/architecture/no_network_test.dart`). Reference values are fetched once at execution time by a tool script; the committed fixture carries the results.
- **Existing guards stay green:** `pure_dart_test` (ARCH-2), `dependency_closure_test`, `no_network_test`, Lint (`--fatal-infos`, `format:check`), the whole `Full suite` budget (240 s).

## Review Focus

1. **A longitude that is right says nothing about the speed.** Expected: speed is tested by itself, against Swiss Ephemeris, not inferred from the Horizons longitude pass (Tasks 2 and 6).
2. **Stations.** At a station the true speed is about zero and the sign flips; a small speed error moves the sign flip by hours or days. Expected: the retrograde sign agrees with Swiss wherever `|Swiss speed|` is larger than the measured error; the offset of the zero crossing is measured per station and reported (Task 6).
3. **Pluto.** Astronomy Engine models Pluto with its own gravity simulation and states no Pluto accuracy. Expected: Pluto's longitude error and speed error are reported on their own line, and Pluto is never hidden inside a "worst of all bodies" figure (Tasks 5 and 6).
4. **The Moon and the Sun are not planets in the library.** Different functions apply (`Astronomy_EclipticGeoMoon`, `Astronomy_SunPosition`, `Astronomy_GeoMoonState`). Expected: each of the ten bodies is exercised by its own device assertion; a wrong frame (J2000 instead of date) would shift every planet by a few tenths of a degree, which the ACC-2 test catches (Task 5).
5. **`360.0` after normalization.** A tiny negative longitude must not become exactly `360.0` (`EclipticPosition` rejects it). Expected: a unit test feeds `-1e-15` through the adapter (Task 4).
6. **The out-of-range edge.** Expected: the instants at the exact start and end of `coveredRange` succeed, one microsecond outside returns `OutOfCoveredRange`, and the node still succeeds outside (Task 4).
7. **Release builds drop unreferenced native assets** (ZOD-FND-003 gotcha 8). Expected: the findings say the first use by app code brings the library in; this task adds no production wiring that would hide that (Task 7).

## Decisions

Owner decisions already made (2026-11-21): speed analytic, option (b); no finite differences; ACC-2 separate; Pluto independent; stop and report if insufficient; scope Android and host. The rest are this plan's calls, for approval with the plan; items marked **NEEDS OWNER** are not decided.

- **D1 (speed derivation, owner decision; the formulation is this plan's call).** For each physical body the shim returns the **apparent geocentric position** `r` (the library's light-time-corrected, aberrated vector) and the **geocentric velocity** `v` (the library's velocity of the body minus the Earth's, both from `Astronomy_BaryState`; the Moon from `Astronomy_GeoMoonState`), both rotated into the true ecliptic of date with `Astronomy_Rotation_EQJ_ECT` and `Astronomy_RotateVector`. **For the Sun and every planet the longitude returned by the shim is `atan2(y, x)` of that same rotated `r`**, so longitude, position and velocity share one frame by construction (plan review I1); `Astronomy_Ecliptic` is not called. **Moon, two points the Task 1 reading must settle before any code (plan review I2):** (i) if `Astronomy_GeoMoonState`'s velocity is itself a numerical derivative inside the library, that conflicts with the owner's "no finite differences" decision: **stop and take it to the owner** (options: accept it for the Moon only, disclosed; or a new Moon formulation); (ii) if the library's Moon position carries no aberration (up to about 20.5 arcseconds), D1 and the findings say so, and the Moon's maximum longitude error is reported on its own line. The speed is `λ' = (x·vy − y·vx) / (x² + y²)` converted from radians to degrees per day, in Dart. **What it omits, and the docs must say so:** the time derivative of the light-time correction, the time derivative of the aberration correction, and the rotation rate of the ecliptic-of-date frame (precession about 3.8e-5 degrees per day, nutation smaller); `v` is the instantaneous velocity at `t`, not at the light-time-retarded instant. **This is therefore not the derivative of the fully apparent longitude.** Whether it is good enough is decided by D7, not asserted. If D7 fails, the plan stops; a refinement (velocity at the retarded instant) is an option to put to the owner in the report, not to apply silently.
- **D2 (flat C shim, project-authored).** `int zodiann_body_state(int body, double ut_days, double* out)` with `out[0]` apparent longitude (degrees, true ecliptic of date), `out[1..3]` `r` (AU), `out[4..6]` `v` (AU per day); returns `0` or the library's `astro_status_t` code; `body` is the shim id (`sun` 0 … `pluto` 9) mapped to `astro_body_t` inside the shim; Dart passes it through an explicit `Body`-to-id table (not `Body.index`), pinned by a host test (plan review M2); `ut_days` is days since J2000 UT (`Astronomy_TimeFromDays`). Reason: avoids struct-by-value across FFI (a spike risk) and keeps upstream untouched. Trade-off: about 80 lines of our own C, tested only on a device.
- **D3 (Android-only hook, as ZOD-FND-003 D3).** `hook/build.dart` builds only for `OS.android`; the host loads no native code. Host tests inject a fake source. Consequence stated up front: **ACC-2 and the speed comparison cannot run in `Core` or `Full suite` CI**; they are device runs recorded in the findings. Wiring a release-blocking run is ZOD-TST-017's job. (A host build with the local `gcc` or CI's compiler is possible later and is not done here.)
- **D4 (covered range).** `UtcRange(1899-12-31T12:00:00Z, 2100-01-01T12:00:00Z)`, the T = ±1 window of `packages/astro_core/test/fixtures/reference_dates.json`, the only span ACC-2 is proved over. The library claims millennia; the adapter does not claim what it did not verify. **NEEDS OWNER:** a wider range later is a one-line change after more verification.
- **D5 (fallback wiring is not in this task) — NEEDS OWNER.** The task text says "wire as the automatic fallback when the Swiss Ephemeris FFI binding is unavailable". The Swiss adapter (ZOD-EPH-002) does not exist yet and is blocked on the iOS half of ZOD-FND-003, so there is nothing to fall back from. Neither the EPH-002 nor the EPH-003 task file mentions astronomy-engine today, so the owner also says **which task owns the automatic selection** (EPH-003 is the "fallback" task, EPH-002 the primary adapter; recommended: EPH-002, because it defines "binding unavailable"). Recommended: this task delivers the DI-swappable adapter (acceptance criterion 2, proved by a test) and writes the carry-over as a Notes line **in the owning task's file** (and in PROGRESS), not in PROGRESS alone. Alternative: a generic `FallbackEphemerisPort` in `astro_core`, which changes the contract package and is not recommended before EPH-002 defines "unavailable".
- **D6 (ACC-2 fixture and ownership) — NEEDS OWNER (plan review I5, Needs-decision 1).** The task criterion says "same reference-date set as T-EPH-1", but T-EPH-1 (ZOD-TST-001) is not built and is blocked, and ZOD-TST-005 ("Author the astronomy-engine backup comparison suite (ACC-2)", depends on EPH-004 and TST-001) owns the T-EPH-1 run against this adapter. Recommended (option A): this task proves ACC-2's bound with its own Horizons fixture over **all 53 instants of `reference_dates.json`** (add-only file, not edited; it names itself the shared T-EPH-1 set) for the ten physical bodies, fetched by `tool/fetch_horizons_reference.dart` with the ZOD-FND-003 query settings (quantity 31, `CENTER=500@399`, UT; one batch per body), and the criterion text is amended in the task file to "proved on this task's own device test over the 53 `reference_dates.json` instants; the T-EPH-1 suite run is tracked by ZOD-TST-005" (the pattern used for earlier tasks), with a Notes line added to ZOD-TST-005. Option B (a 10-instant fixture, no amendment) is not recommended: it weakens the criterion silently and duplicates TST-005. Bound: 60 arcseconds, asserted per body, with each body's maximum printed on its own line (Moon and Pluto included).
- **D7 (speed acceptance, PROPOSED thresholds, fixed before Task 6 runs — NEEDS OWNER confirmation).** Reference: Swiss Ephemeris `swe_calc_ut` speed with the data files (`SEFLG_SWIEPH | SEFLG_SPEED`), on the emulator, same process. The expected omitted-term error is about 1e-4 °/day (aberration derivative about 9.8e-5, precession about 3.8e-5), so the bounds are set near that scale, not loosely. Sufficient means all of: (a) `|astronomy speed − Swiss speed|` ≤ **3e-4 °/day** for the Sun, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune and Pluto, and ≤ **0.005 °/day** for the Moon, at every sampled instant (the Moon figure is provisional: measure, then the owner fixes it before the pass/fail run); (b) the sign of the speed (retrograde) equals Swiss's at every sampled instant where `|Swiss speed|` exceeds the **fixed bound of (a)** for that body (not the measured maximum, which would widen its own exemption); (c) at each station the zero-crossing instant of the astronomy speed is within **1 day** of Swiss's, and the offset is reported. Expectation stated in advance: the offset is about 0.1 to 0.5 day for Uranus, Neptune and Pluto (speed slope near a station is about 2.7e-4 °/day² for Neptune), under an hour for Mercury; an outer-planet offset above 1 day is a stop-and-report signal. If any criterion fails: stop and report (Global Constraints).
- **D8 (stations and sample set).** Sample instants: the 53 of D6 plus, for each of Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune and Pluto, every station between 1900 and 2100 found by scanning Swiss speed daily and bisecting to a minute, each sampled at the station and at ±1, ±5 and ±20 days. The Moon and the Sun add 20 instants spread over 2026. **Scale:** the eight planets have roughly 2,000 stations in 1900 to 2100 (Mercury alone about 1,260), so about 14,000 station samples plus the daily Swiss scan; Task 6 states the expected count, sets an explicit test timeout, and may thin Mercury and Venus to every fifth station if the timeout is exceeded (recorded in the findings, not silent).
- **D9 (body ids, Horizons commands).** Swiss ids: sun 0, moon 1, mercury 2, venus 3, mars 4, jupiter 5, saturn 6, uranus 7, neptune 8, pluto 9 (`swephexp.h`). Horizons: 10, 301, 199, 299, 499, 599, 699, 799, 899, 999 (planet centers; Pluto is 999).

## Out of scope

iOS build or run; the automatic fallback selection (D5); production wiring of a source in `app_overrides.dart`; changing `EphemerisPort`; the Swiss adapter (EPH-002); retrograde formatting (EPH-005); wiring ACC-2 into CI (TST-017); a host native build; any finite-difference path.

## File Structure

- Create `native/astronomy_c/upstream/{astronomy.c,astronomy.h,LICENSE}` (vendored, unchanged); `native/astronomy_c/{MANIFEST.json,VENDORED.md}`; `native/astronomy_c/zodiann_astronomy_shim.{c,h}` (project-authored); modify `native/astronomy_c/README.md`.
- Modify `.gitattributes`: add `native/astronomy_c/upstream/** -text`.
- Create `test/architecture/astronomy_vendored_test.dart` (mirror of `swisseph_vendored_test.dart`).
- `packages/ephemeris_astronomy`: modify `pubspec.yaml`, `lib/ephemeris_astronomy.dart`; create `lib/src/longitude_rate.dart` (pure), `lib/src/body_state.dart` (the `BodyState` value and the `BodyStateSource` interface), `lib/src/astronomy_ephemeris.dart` (the port), `lib/ephemeris_astronomy_native.dart` and `lib/src/native_body_state_source.dart` (device only), `lib/src/ffi/astronomy_bindings.g.dart` (generated), `hook/build.dart`, `tool/ffigen.dart`, `tool/fetch_horizons_reference.dart`, `test/fixtures/reference_longitudes.json`, tests `test/longitude_rate_test.dart`, `test/astronomy_ephemeris_test.dart`, `test/reference_fixture_test.dart`.
- `apps/astro_mobile`: modify `pubspec.yaml` (add `ephemeris_astronomy` as a regular dependency, the same reason as D5 in ZOD-FND-003); create `integration_test/astronomy_accuracy_test.dart` (ACC-2), `integration_test/astronomy_reference_longitudes.dart` (const copy of the fixture), `integration_test/astronomy_speed_vs_swiss_test.dart` (D7), `test/astronomy_reference_longitudes_match_test.dart` and `test/di/astronomy_swap_test.dart` (host).
- Task and project records: add a Notes line to `ZOD-TST-005` (the T-EPH-1 run against this adapter stays with it; criterion amended per D6) and to the task that owns the automatic fallback (D5).
- Docs: `docs/spikes/ZOD-EPH-004-astronomy-engine-adapter.md` (findings, limitations, the proposed contract change), `docs/licensing/third-party-inventory.md`, `THIRD_PARTY_NOTICES.md`, task file, `docs/development/TASKS.md`, `docs/PROGRESS.md`.

## Tasks

### Task 1: Vendor astronomy-engine unchanged, with a guard

**Files:** the `native/astronomy_c/` and `.gitattributes` items above; `test/architecture/astronomy_vendored_test.dart`.

**Interfaces:** Produces `native/astronomy_c/upstream/astronomy.{c,h}` and `MANIFEST.json` (`upstreamTag`, `upstreamCommit`, per file `path`, `blobSha1`, `sha256`).

- [ ] **Step 1: Resolve the exact upstream release.** `gh api repos/cosinekitty/astronomy/releases/latest` and `.../git/ref/tags/<tag>`; record the tag (the research read v2.1.19; **unverified**, confirm), the commit, the retrieval date. Read the tree at that commit and confirm `source/c/astronomy.c`, `astronomy.h` and the repository's MIT `LICENSE` exist. Read `astronomy.h` and `astronomy.c` and record in `VENDORED.md` (nothing below is verified yet; the research read documentation only): (1) whether `Astronomy_BaryState` accepts `BODY_EARTH`; if not, name the fallback now from what the source offers (for example the library's heliocentric Earth state) and revise D1 before any code; (2) that `Astronomy_Rotation_EQJ_ECT`, `Astronomy_RotateVector`, `Astronomy_TimeFromDays`, `Astronomy_SunPosition`, `Astronomy_EclipticGeoMoon`, `Astronomy_GeoMoonState` and `Astronomy_GeoVector` exist; (3) the **frame (EQJ, ECL or ECT)** of the output of `Astronomy_Ecliptic`, `Astronomy_SunPosition` and `Astronomy_EclipticGeoMoon`, and whether each includes aberration and light time; (4) what `Astronomy_GeoVector(…, ABERRATION)` returns for the Sun; (5) **how `Astronomy_GeoMoonState` obtains its velocity** (analytic, or a numerical derivative of the Moon position) and whether the Moon's position is corrected for aberration (D1, the Moon points). **Gate:** a numerical-derivative Moon velocity stops the plan and goes to the owner.
- [ ] **Step 2: Write the failing guard test** `astronomy_vendored_test.dart` (copy the structure of `swisseph_vendored_test.dart`): every manifest file exists, its git blob SHA-1 and SHA-256 recomputed from the bytes equal the manifest, the MIT `LICENSE` is present, no file exists under `upstream/` that the manifest does not list. Run `dart test test/architecture/astronomy_vendored_test.dart`; expect FAIL (no manifest).
- [ ] **Step 3: Add the `.gitattributes` line first**, then fetch the three files by blob id (`gh api repos/cosinekitty/astronomy/git/blobs/<sha>`, decode base64, write bytes unchanged), write `MANIFEST.json`, `VENDORED.md` (origin, tag, commit, date, what is vendored and not, how "unchanged" was proved), update `native/astronomy_c/README.md`.
- [ ] **Step 4:** `git add`, then for each file compare `git rev-parse :<path>` with the upstream blob id (all equal); run the guard test (PASS); in a fresh `git clone -c core.autocrlf=true` of the branch run the guard again (PASS).
- [ ] **Step 5: Licensing records.** Add the astronomy-engine row to `docs/licensing/third-party-inventory.md` (replace the "reserved row") and an entry in `THIRD_PARTY_NOTICES.md`: MIT, copyright holder as printed in the header, upstream URL, and that the MIT text ships with the source. Note AGPL-compatibility of MIT as a fact checked against the license texts, not legal advice.
- [ ] **Step 6: Commit** `build(ZOD-EPH-004): vendor astronomy-engine C unchanged`.

### Task 2: The longitude rate, pure Dart

**Files:** `packages/ephemeris_astronomy/{pubspec.yaml,lib/src/longitude_rate.dart,lib/ephemeris_astronomy.dart,test/longitude_rate_test.dart}`.

**Interfaces:** Produces `double eclipticLongitudeRateDegreesPerDay({required double x, required double y, required double vx, required double vy})` where `x, y` are the geocentric ecliptic-of-date position (any consistent length unit) and `vx, vy` the velocity in that unit per day. Throws `ArgumentError` when `x*x + y*y == 0`. Add `astro_core: path: ../astro_core` to `dependencies` and `resolution: workspace` stays.

- [ ] **Step 1: Write the failing tests** (literal expected values, independent of the implementation): `(x:1, y:0, vx:0, vy:π/180)` → `1.0` within 1e-12 (ω = vy/x radians per day, so `vy = π/180` gives exactly one degree per day); a prograde case at `(0, 2)` with `vx = -(π/180)*2` → `1.0` (rotation about the origin); a retrograde case (`vy` negative) → `-1.0`; `x` and `y` scaled by 7 with `v` scaled by 7 gives the same rate (scale invariance); radial motion (`v` parallel to `r`) → `0.0`; a z-component is not an input (the function ignores latitude by design: a test documents that the rate is the rate of `atan2(y, x)`); `x = y = 0` throws `ArgumentError`, and so does any non-finite input (NaN or infinity).
- [ ] **Step 2:** `cd packages/ephemeris_astronomy && dart test test/longitude_rate_test.dart`; expect FAIL (undefined).
- [ ] **Step 3: Implement** with the formula in D1; document in the doc comment that this is the rate of the longitude of the *given* vectors, and what the callers' vectors omit (copy the D1 list). Export it.
- [ ] **Step 4:** run it; expect PASS. Run `dart analyze --fatal-infos` and `dart format --set-exit-if-changed .`.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-004): add the analytic ecliptic longitude rate`.

### Task 3: The native source: shim, hook, bindings, wrapper

**Files:** `native/astronomy_c/zodiann_astronomy_shim.{c,h}`, `packages/ephemeris_astronomy/{hook/build.dart,tool/ffigen.dart,pubspec.yaml,lib/src/body_state.dart,lib/src/native_body_state_source.dart,lib/ephemeris_astronomy_native.dart,lib/src/ffi/astronomy_bindings.g.dart}`.

**Interfaces:**
- Produces `final class BodyState { const BodyState({required double longitude, required double x, required double y, required double z, required double vx, required double vy, required double vz}); }` (degrees, AU, AU per day, ecliptic of date) and `abstract interface class BodyStateSource { BodyState bodyState(Body body, DateTime utc); }` in `body_state.dart` (pure; imports `astro_core`).
- Produces `final class NativeBodyStateSource implements BodyStateSource` (device only; throws `StateError('astronomy-engine status <code>')` for a non-zero return; throws `ArgumentError` for non-UTC; `Body.node` throws `ArgumentError`, the node is not a native body).
- C: `int zodiann_body_state(int body, double ut_days, double* out);` (D2). Consumes: the upstream functions confirmed in Task 1.

- [ ] **Step 1: Write the shim** per D2: Sun and planets (Pluto included): `r` from `Astronomy_GeoVector(body, t, ABERRATION)`, and `out[0]` is `atan2(y, x)` of the rotated `r` in degrees (not `Astronomy_Ecliptic`; D1); Moon: the longitude from `Astronomy_EclipticGeoMoon` and `r` and `v` from `Astronomy_GeoMoonState` (subject to the Task 1 gate); `v` for the Sun and planets is `Astronomy_BaryState(body, t).v − Astronomy_BaryState(BODY_EARTH, t).v`; rotate `r` and `v` with `Astronomy_Rotation_EQJ_ECT(t)` and `Astronomy_RotateVector`. Return the first non-success `astro_status_t` unchanged. No dynamic allocation.
- [ ] **Step 2: Hook and bindings.** `hook/build.dart` as in ZOD-FND-003 (Android only; sources `upstream/astronomy.c` and the shim; `assetName: 'src/ffi/astronomy_bindings.g.dart'`; root `Logger('')`). `tool/ffigen.dart` generates bindings from the shim header only (the header declares plain `int` and `double*`, so the target does not change the output; use the same Android target options as `ephemeris_swiss/tool/ffigen.dart`). Run `dart run tool/ffigen.dart`; commit the output.
- [ ] **Step 3: Write `NativeBodyStateSource`** (calloc `out` of 7 doubles; free in `finally`; `utc` to days since J2000: `julianDayUt(utc) - 2451545.0` is not importable from `ephemeris_swiss`, so compute `(utc.microsecondsSinceEpoch - 946728000000000) / 86400000000`, subtracting the integer microseconds of J2000 (2000-01-01T12:00Z) before the double division, and test it on the host in Task 4). Add the explicit `Body`-to-shim-id table in `native_body_state_source.dart`'s pure part (a top-level `const Map<Body, int>` in `body_state.dart`, so a host test in Task 4 can pin all ten entries and the absence of `Body.node`).
- [ ] **Step 4: Verify the build only.** `flutter pub get`, then host: `dart test` in the package still passes (the hook adds nothing on the host); from `apps/astro_mobile`: `flutter build apk --debug` and `unzip -l …app-debug.apk | grep astronomy`, expecting `libastronomy.so` for arm64-v8a, armeabi-v7a and x86_64; record sizes and the `LOAD` alignment (16 KB) for the findings with `"$ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe" -lW <lib>`. This needs Task 7's app dependency edge first: do that one-line pubspec edit here.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-004): bind astronomy-engine through a flat C shim`.

### Task 4: `AstronomyEphemeris`, the port (host TDD)

**Files:** `packages/ephemeris_astronomy/{lib/src/astronomy_ephemeris.dart,lib/ephemeris_astronomy.dart,test/astronomy_ephemeris_test.dart}`.

**Interfaces:** Produces `final class AstronomyEphemeris with MeanAscendingNodeFormula implements EphemerisPort { AstronomyEphemeris({required BodyStateSource source}); }`, `coveredRange` per D4. Consumes `BodyStateSource`, `eclipticLongitudeRateDegreesPerDay`, `normalizeDegrees`, `EclipticPosition`, `EphemerisSuccess`, `OutOfCoveredRange`.

- [ ] **Step 1: Write the failing tests** with a fake `BodyStateSource` returning literal states:
  - `coveredRange` equals `UtcRange(DateTime.utc(1899,12,31,12), DateTime.utc(2100,1,1,12))`.
  - a physical body in range returns `EphemerisSuccess(EclipticPosition(longitude: <fake lon>, speed: <rate from the fake vectors>))`, with the speed equal to the literal expected for the fake `(x,y,vx,vy)`.
  - the speed is **not** computed from two calls: the fake counts calls and the test asserts exactly one `bodyState` call per `position` (no differencing).
  - `Body.node` returns `EphemerisSuccess(meanAscendingNode(utc))`, never calls the source, and also succeeds at `DateTime.utc(1500)` and `DateTime.utc(2500)` (outside the range).
  - the first and last instants of `coveredRange` succeed; the instant one microsecond before the start and after the end return `OutOfCoveredRange(requested:…, covered: coveredRange)` with the source not called.
  - a non-UTC `DateTime` throws `ArgumentError` for every body including `node`.
  - a fake longitude of `-1e-15` and one of `360.0` come back inside `[0, 360)` (Review Focus 5).
  - a source that throws `StateError` propagates (the adapter does not invent a position).
  - the epoch constant: `DateTime.utc(2000,1,1,12)` is `0.0` days from J2000 by the formula Task 3 uses, and `DateTime.utc(2000,1,2,12)` is `1.0` (extract the conversion into a small pure function `daysSinceJ2000(DateTime)` in `body_state.dart` and test it here).
  - the `Body`-to-shim-id table holds exactly sun 0, moon 1, mercury 2, venus 3, mars 4, jupiter 5, saturn 6, uranus 7, neptune 8, pluto 9 and no `Body.node` (plan review M2).
- [ ] **Step 2:** `dart test test/astronomy_ephemeris_test.dart`; expect FAIL (undefined).
- [ ] **Step 3: Implement**, with the node branch before the range check as `mean_node.dart` documents. The class documentation states the contract interpretation (D1): the source has no speed output; the speed is derived analytically from library vectors; it is not the derivative of the fully apparent longitude; what is omitted; and that finite differences are not used.
- [ ] **Step 4:** run the test; PASS; analyze and format.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-004): add the astronomy-engine EphemerisPort adapter`.

### Task 5: ACC-2 on the emulator (longitude against Horizons)

**Files:** `packages/ephemeris_astronomy/{tool/fetch_horizons_reference.dart,test/fixtures/reference_longitudes.json,test/reference_fixture_test.dart}`, `apps/astro_mobile/{integration_test/astronomy_accuracy_test.dart,integration_test/astronomy_reference_longitudes.dart,test/astronomy_reference_longitudes_match_test.dart}`.

**Interfaces:** Consumes `AstronomyEphemeris`, `NativeBodyStateSource`. Produces the fixture (`entries[{body, utc, longitudeDegrees}]`, `toleranceArcseconds: 60`, source and query recorded as in the ZOD-FND-003 fixture) and a Dart const copy of it for the device test (files under `test/` are not bundled into the APK; this is the ZOD-FND-003 precedent, `integration_test/reference_longitudes.dart` plus a host match test).

- [ ] **Step 1: Fetch the reference.** Write the tool (sorts the instants, checks each returned row's printed date against the request, because Horizons returns rows chronologically whatever the list order: ZOD-FND-003 gotcha 6); run it; commit the fixture. Instants: **all 53 of `reference_dates.json`** (D6), one Horizons batch per body (10 batches), ten bodies.
- [ ] **Step 2: Host fixture tests (failing first, then passing):** records source and query settings; tolerance 60; all ten bodies present on all 53 instants; every longitude in `[0, 360)`; every instant is UTC and inside D4's range; and `astronomy_reference_longitudes_match_test.dart` keeps the const copy equal to the JSON. Run: expect FAIL before the fixture and the const exist, PASS after.
- [ ] **Step 3: Write the device test.** For every entry: `AstronomyEphemeris(source: NativeBodyStateSource()).position(body, utc)` is `EphemerisSuccess`; the angular difference to the fixture longitude (taken modulo 360, shortest way) is within 60 arcseconds; print one line per body with the maximum difference and its instant (Moon and Pluto each on their own line, never folded into one figure). **Frame-consistency check (plan review I1; ACC-2's 60 arcseconds cannot catch a mean-versus-true-equinox slip, because nutation is at most about 17 arcseconds):** for the Sun and every planet, `atan2(y, x)` of the source's `r` equals the returned longitude within 1 arcsecond, and for the Moon within the margin Task 1 recorded. A deliberate control: the same call at `DateTime.utc(1899,12,30)` returns `OutOfCoveredRange`.
- [ ] **Step 4: Run on the emulator:** `cd apps/astro_mobile && flutter test integration_test/astronomy_accuracy_test.dart -d emulator-5554`. Expect all ten bodies pass; record the per-body maxima. If any body fails 60 arcseconds: stop and report (Pluto included; excluding or relaxing a body is the owner's decision).
- [ ] **Step 5: Commit** `test(ZOD-EPH-004): prove ACC-2 against JPL Horizons on Android`.

### Task 6: Speed against Swiss Ephemeris, stations included (D7, D8)

**Files:** `apps/astro_mobile/integration_test/astronomy_speed_vs_swiss_test.dart`.

**Interfaces:** Consumes `SwissEphemerisBinding` (ZOD-FND-003, with the spike's data-file copy to the application support directory, as `swiss_ephemeris_spike_test.dart` does), `AstronomyEphemeris`. **Assert the thresholds of D7 as named constants at the top of the test, set before the first run.**

- [ ] **Step 1: Write the harness** (reuse the data-file copy and the `usedSwissEphemerisFiles` check from the spike test; every Swiss sample must pass it, otherwise the reference is Moshier and the test fails). Find stations per D8; sample per D8. State the expected sample count in the test's output header and give the test an explicit timeout (`timeout: Timeout(Duration(minutes: …))`) sized from a first measured run; the Swiss and astronomy calls are synchronous, so run them in the test isolate.
- [ ] **Step 2: Assertions and report.** For each body: maximum `|Δ speed|` and its instant; retrograde-sign agreement count outside the `|Swiss speed|` window; for each station the offset in minutes between the zero crossing of Swiss's speed and of the astronomy speed (bisection on the adapter's own speed; this bisection is a search for a sign change, not a derivative). Print a Markdown table (per body, Pluto on its own row) for the findings. Assertions: D7 (a), (b), (c).
- [ ] **Step 3: Run on the emulator** and save the printed table to the scratchpad. **If any D7 criterion fails: stop here, write the findings, and report to the owner with the numbers; do not proceed to Task 7 and do not change the derivation.**
- [ ] **Step 4: Commit** `test(ZOD-EPH-004): compare analytic speed with Swiss Ephemeris`.

### Task 7: Prove the swap is one DI override

**Files:** `apps/astro_mobile/test/di/astronomy_swap_test.dart`; `apps/astro_mobile/pubspec.yaml` (done in Task 3).

- [ ] **Step 1: Write the test (host).** A `ProviderContainer` with `ephemerisPortProvider.overrideWithValue(AstronomyEphemeris(source: fakeSource))`; a function written only against `EphemerisPort` (no import of `ephemeris_astronomy` in its library) returns the expected position; a second container overrides with the existing `_FakePort`-style fake and the same function runs unchanged. Add an assertion over `lib/` that no file under `apps/astro_mobile/lib` and `packages/feature_*` imports `ephemeris_astronomy` (feature code untouched).
- [ ] **Step 2:** run it (PASS; there is no production wiring to write, which is the point). Run the full host suite for `apps/astro_mobile` to confirm the new regular dependency did not slow or break it (the hook is a no-op on the host).
- [ ] **Step 3: Commit** `test(ZOD-EPH-004): prove the astronomy backup swaps in by one override`.

### Task 8: Findings, the proposed contract note, and project records

**Files:** `docs/spikes/ZOD-EPH-004-astronomy-engine-adapter.md`, task file, `docs/development/TASKS.md`, `docs/PROGRESS.md`.

- [ ] **Step 1: Findings document:** what was built; ACC-2 per-body maxima with Pluto on its own; the speed table and the maximum observed errors per body; stations; every limitation (the omitted terms, instantaneous `v`, range D4, the Android-only device runs, no CI run, iOS not verified, the dropped-release-asset behavior); build sizes and 16 KB alignment; **the iOS checklist for astronomy-engine** (hook builds for iOS, the same two integration tests on a simulator or device, size and time).
- [ ] **Step 2: Proposed contract change, written but not applied:** the exact sentence that would be added to `EphemerisPort.position`'s speed paragraph ("A source with no speed output may derive it analytically from its own position and velocity vectors; finite differences remain forbidden"), what it changes for CRS-A1's wording in the specification, which consumers it affects (crossing solver, retrograde detection), and the alternative (leave the contract and keep the interpretation inside this adapter). The owner decides.
- [ ] **Step 3: Verify (verification-before-completion):** run in full and record exit codes and counts: `dart test` in `ephemeris_astronomy`; the root `melos run test` (Full suite) with its timed duration against the 240 s budget; Lint (`dart analyze --fatal-infos`, `format:check`); `flutter build apk --debug`; the two emulator runs. Record the commands and the head commit.
- [ ] **Step 4: Statuses.** Only if every acceptance criterion is verified: the task file `Completed` with notes (D5's carry-over to EPH-002, the proposed contract note, iOS pending), `TASKS.md`, PROGRESS (Completed Tasks, Current Task, Next Recommended Task, Technical Decisions D1 to D9, Git State). If D7 failed: `In Progress (blocked on the speed decision)` with the report.
- [ ] **Step 5: Commit** `docs(ZOD-EPH-004): record the findings and the verified state`; push; open the PR with `gh pr create`; add the PR link in a follow-up commit.

## Acceptance criteria mapping

| Task-file criterion | Proved by |
|---|---|
| ACC-2: within 1 arcminute of JPL Horizons | Task 5, ten bodies over the 53 `reference_dates.json` instants, device run, per-body maxima in the findings (criterion text amended per D6, owner decision pending; the T-EPH-1 suite run stays with ZOD-TST-005) |
| Swap is only a DI override | Task 7 |
| Node uses the ZOD-EPH-001 formula | Task 4 (`with MeanAscendingNodeFormula`, source never called for the node, no coefficient literals in the package) |
| Owner conditions: speed vs Swiss, stations, documented limits, Pluto alone | Task 6, Task 5, Task 8 |

## Self-review (writing-plans checklist)

- **Spec coverage:** ACC-2, ARCH-4 (DI part), CRS-A1 (interpretation), R-2, NFR-A1, node rule: covered above. The task bullet "automatic fallback" is deliberately not implemented (D5, NEEDS OWNER).
- **Type consistency:** `BodyState`, `BodyStateSource`, `NativeBodyStateSource`, `AstronomyEphemeris`, `eclipticLongitudeRateDegreesPerDay`, `daysSinceJ2000` are named once in Interfaces and used identically.
- **Unverified items the plan makes explicit:** the upstream tag, `Astronomy_BaryState(BODY_EARTH)`, the exact frames of each library function (Task 1, Step 1); the D7 thresholds (owner); D4 range.
- **Proportion:** the plan holds signatures, assertions and decisions; bodies of code are left to the implementer.

## Plan review

### Round 1 (verdict: needs user decision)

Reviewer could not read the C source (not vendored), so every astronomy-engine API claim is unverified and is gated by Task 1.

| ID | Severity | What was done |
|---|---|---|
| I1 planet longitude frame from `Astronomy_Ecliptic` | Important | Applied. D1 and Task 3: Sun and planet longitude is `atan2(y, x)` of the rotated `r`; Task 1 records each function's frame; Task 5 adds a per-body consistency assertion within 1 arcsecond. |
| I2 Moon velocity may be a numerical derivative; Moon aberration | Important | Applied. D1 (two Moon points), Task 1 reading item 5 and a gate: a numerical-derivative Moon velocity stops the plan for the owner; missing aberration is documented and the Moon reported on its own line. |
| I3 device test cannot read the fixture | Important | Applied. Task 5 adds the const copy and a host match test (ZOD-FND-003 precedent). |
| I4 D7 thresholds loose and circular | Important | Applied. D7 now has fixed per-body bounds (3e-4 °/day planets and Sun, 0.005 Moon provisional), the sign band uses the fixed bound, and the station expectation for the outer planets is stated. Numbers still need the owner's confirmation. |
| I5 ACC-2 set smaller than the criterion | Important | Applied in part. Task 5 uses all 53 `reference_dates.json` instants; the criterion wording and TST-005 ownership are a user decision (D6). |
| M1 Task 2 wording and non-finite inputs | Minor | Applied. |
| M2 `Body.index` across FFI | Minor | Applied. Explicit table, pinned by a host test. |
| M3 name the `BaryState(Earth)` fallback | Minor | Applied. Task 1 names it from the source before any code. |
| M4 integer microseconds for days since J2000 | Minor | Applied. |
| M5 `llvm-readelf` path | Minor | Applied. |
| M6 Task 6 scale and timeout | Minor | Applied (D8 and Task 6). |

**Needs user decision (not resolved by the plan):** (1) D6: amend the ACC-2 criterion and leave the T-EPH-1 run to ZOD-TST-005 (recommended) or keep a 10-instant fixture unamended; (2) D7: confirm the per-body numbers before Task 6; (3) the Moon velocity, only if Task 1 finds a numerical derivative (recommended: stop and report); (4) D5: approve deferring the automatic fallback, and name the owning task (recommended: ZOD-EPH-002); (5) D4: the covered range.

Round 2 (focused on this revision): pending.
