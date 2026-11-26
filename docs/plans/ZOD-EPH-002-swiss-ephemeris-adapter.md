# ZOD-EPH-002: Swiss Ephemeris Adapter (data-file mode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Swiss Ephemeris the app's position source on Android: ten bodies through `EphemerisPort`, the approved time conversion, serialized native calls, data files installed on the device, and the automatic backup.

**Architecture:** The time conversion is pure data and pure functions in `astro_core`. `ephemeris_swiss` gains a project-authored C lock over one shared library state and a pure-Dart adapter over an injected calculation source. `astro_mobile` installs the data files, probes the libraries and binds one wrapped source at startup.

**Tech Stack:** Dart 3.14 / Flutter 3.50.0, Riverpod 3, Dart FFI with native assets (`hooks`, `native_toolchain_c`), ffigen 23, C (pthread), `path_provider`.

**Spec:** [`docs/superpowers/specs/2026-11-25-zod-eph-002-swiss-adapter-design.md`](../superpowers/specs/2026-11-25-zod-eph-002-swiss-adapter-design.md) (approved by the owner 2026-11-26), with [`docs/decisions/ZOD-EPH-002-time-scale.md`](../decisions/ZOD-EPH-002-time-scale.md). Task file: [`ZOD-EPH-002`](../development/computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md).

## Global Constraints

* Branch `task/ZOD-EPH-002-swiss-ephemeris-adapter`. Commits are `<type>(ZOD-EPH-002): <summary>` with the session's attribution lines. Stage explicit paths only; leave `grep.exe.stackdump` alone.
* Files under `native/swisseph/upstream` stay byte-identical (guarded). `packages/ephemeris_astronomy` code and fixtures are not modified.
* Computation settings: geocentric, apparent, true ecliptic of date. The flag word sent to the library is exactly `seflgSwieph | seflgSpeed` (258). No precession, sidereal or J2000 flag.
* Longitude speed comes from the library (`xx[3]`), never from two positions.
* Time: before `1972-01-01T00:00:00Z` the UTC input goes to `swe_calc_ut`; from then `TT = UTC + (TAI − UTC) + 32.184 s` goes to `swe_calc`; from `2027-06-28T00:00:00Z` the 37 s offset is held and labelled "assumes continuous UTC".
* ΔT data status: observed before 2024-01-01, estimated before 2029-01-01, then forecast. No year literal in classification code. No accuracy warning threshold.
* A Moshier fallback, missing file, library warning or negative return is `OutOfCoveredRange`, never a success.
* No `EphemerisPort` contract change. No network use in app code.
* The production binding is one expression, `ephemerisPortProvider.overrideWithValue(SupportedRangeEphemeris(...))`, with both adapters created inside it.
* Host tests never run native code or the real file installer.
* Before **every** commit, from the root: `dart run melos run lint` and `dart run melos run test` exit 0, one process at a time (`dart` is the pinned SDK on `PATH`, equivalent to `fvm dart`).
* Acceptance gate (owner, 2026-11-26): on the **x86_64 Android emulator**, **all ten bodies within 1″** of JPL Horizons by UTC input at the 53 reference instants **and** at matched TT. A miss fails the task: stop and report; never widen a tolerance or drop an instant.

### Environment (every task)

```bash
export PATH=/c/Users/user/fvm/versions/3.50.0/bin:/c/TDM-GCC-64/bin:$PATH
export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0
export ANDROID_HOME='C:\Users\user\AppData\Local\Android\Sdk'
ADB=/c/Users/user/AppData/Local/Android/Sdk/platform-tools/adb
# Emulator (run in the background; device id from `$ADB devices`, usually emulator-5554):
/c/Users/user/AppData/Local/Android/Sdk/emulator/emulator -avd Pixel_9_Pro_API_35
```

After any `flutter pub get`: `git checkout -- packages/shared_ui/lib/l10n`. Device tests run from `apps/astro_mobile`: `flutter test integration_test/<file> -d emulator-5554`. Host tests: `dart test` in a pure package, `flutter test` in `apps/astro_mobile`, `dart test test/architecture` at the root.

## Review Focus

Most likely to bite a person first. Each has a test in the owning task.

1. The support directory is unavailable or the disk is full: the app still opens in the right language and positions are unavailable (Tasks 6, 7).
2. A copy killed midway leaves a short file or a stray temp file: the next launch repairs it (Task 6).
3. An app update ships new data of the same size: it is recopied (Task 6).
4. A damaged data file or a nonsense library result: unavailable, not a crash (Tasks 3, 5).
5. The first and last supported instants (1900-01-01T00:00Z, 2100-12-31T23:59:59.999999Z) succeed for all ten bodies (Task 5).
6. A release build ends with source `none`, or lacks the backup library, with no visible error (Task 8).

## Plan decisions (builder's calls)

* **P1** The offset is a `Duration` (exact microseconds), and TT's Julian day is `julianDayUt(utc.add(offset))`.
* **P2** The published leap list is transcribed into the test with its provenance; the IERS file is not committed, because its redistribution terms are unverified (spike section 5.2). A second guard reads the vendored `swedate.c` list.
* **P3** The calculation source receives the flag word, so a host test can see it.
* **P4** The lock file fails to compile without `-DTLSOFF`.
* **P5** Probes may throw; the one place that catches is the wiring.
* **P6** The matched-TT fixture is pinned to the device by behaviour (Moon longitude through the adapter equals the library at the fixture's TT within 0.0005″, about 1 ms), so no test-only native function is added.
* **P7** Measured coverage rule: `start` is the first 00:00 UTC at least 24 h after the latest failing instant at the lower edge; `end` is the last 00:00 UTC at least 24 h before the earliest failing instant at the upper edge.

---

### Task 1: Time scale in `astro_core`

**Files:**
- Create: `packages/astro_core/lib/src/time/leap_second_table.dart`, `ephemeris_time.dart`, `delta_t_status.dart` (same folder)
- Modify: `packages/astro_core/lib/astro_core.dart` (export the three)
- Test: `packages/astro_core/test/time/leap_second_table_test.dart`, `ephemeris_time_test.dart`, `delta_t_status_test.dart`; `packages/ephemeris_swiss/test/vendored_time_data_test.dart`
- Modify: `packages/ephemeris_swiss/pubspec.yaml` (add `astro_core: {path: ../astro_core}`)

**Interfaces — Produces:**

```dart
final class LeapSecondStep {
  const LeapSecondStep({required this.from, required this.taiMinusUtcSeconds});
  final DateTime from; final int taiMinusUtcSeconds;
}
final class LeapSecondTable {
  LeapSecondTable({required Iterable<LeapSecondStep> steps, required this.validUntil,
    required this.source, required this.bulletin});
  static final LeapSecondTable bundled;
  final List<LeapSecondStep> steps;      // unmodifiable
  final DateTime validUntil;             // bundled: DateTime.utc(2027, 6, 28)
  final String source, bulletin;         // 'IERS Leap_Second.dat', 'Bulletin C 72 (July 2026)'
  int? taiMinusUtcSecondsAt(DateTime utc); // null before steps.first.from
}
enum TtBasis { publishedLeapSeconds, assumedContinuousUtc }
sealed class EphemerisTime { const EphemerisTime(); }
final class UniversalTime extends EphemerisTime { const UniversalTime(); }
final class TerrestrialTime extends EphemerisTime {
  const TerrestrialTime({required this.ttMinusUtc, required this.basis});
  final Duration ttMinusUtc; final TtBasis basis;
}
EphemerisTime ephemerisTimeFor(DateTime utc, {LeapSecondTable? table});
enum DeltaTStatus { observed, estimated, forecast }
final class DeltaTDataset {
  DeltaTDataset({required this.observedBefore, required this.estimatedBefore, required this.source});
  static final DeltaTDataset bundled;    // utc(2024), utc(2029)
  final DateTime observedBefore, estimatedBefore; final String source;
}
DeltaTStatus deltaTStatusAt(DateTime utc, {DeltaTDataset? dataset});
```

Every method taking a `DateTime` throws `ArgumentError` for non-UTC. The constructors throw `ArgumentError` for: no steps, non-UTC values, steps not strictly ascending, `validUntil` not after the last step, `estimatedBefore` before `observedBefore`.

- [ ] **Step 1: Write the failing tests.** Table test: `bundled.steps` equals this list (transcribed from IERS `Leap_Second.dat`, retrieved 2026-11-25, "Updated through IERS Bulletin 72 issued in July 2026", "File expires on 28 June 2027"), as `(year, month, TAI−UTC)`, each on day 1 at 00:00 UTC:

```
1972-01 10  1972-07 11  1973-01 12  1974-01 13  1975-01 14  1976-01 15  1977-01 16
1978-01 17  1979-01 18  1980-01 19  1981-07 20  1982-07 21  1983-07 22  1985-07 23
1988-01 24  1990-01 25  1991-01 26  1992-07 27  1993-07 28  1994-07 29  1996-01 30
1997-07 31  1999-01 32  2006-01 33  2009-01 34  2012-07 35  2015-07 36  2017-01 37
```

plus `validUntil`, the two provenance strings, the list rejecting `add`, and one case per constructor error. Conversion test, over every `bundled` step `s`, with `us = Duration(microseconds: 1)` and `offset(n) = Duration(microseconds: 32184000 + n * 1000000)`:

```dart
expect(at(s.from), TT(offset(s.taiMinusUtcSeconds), publishedLeapSeconds));
expect(at(s.from.add(us)), same as at(s.from));
// previous instant: UniversalTime for the first step, else the previous offset
expect(at(s.from.subtract(us)), previous);
expect(at(table.validUntil.subtract(us)), TT(offset(37), publishedLeapSeconds));
expect(at(table.validUntil), TT(offset(37), assumedContinuousUtc));
expect(at(DateTime.utc(2100, 12, 31)), TT(offset(37), assumedContinuousUtc));
expect(at(DateTime.utc(1900)), isA<UniversalTime>());
expect(() => ephemerisTimeFor(DateTime(2000)), throwsArgumentError);
```

(Compare `ttMinusUtc` and `basis` fields.) A custom table changes the answers (replaceable data). Status test: `utc(2024) - us` observed, `utc(2024)` estimated, `utc(2029) - us` estimated, `utc(2029)` forecast, `utc(1900)` observed; a custom dataset moves both boundaries; non-UTC throws. Vendored test (reads `../../native/swisseph/upstream/`): (a) the `YYYYMMDD` entries of `leap_seconds[...]` in `swedate.c`, **each plus one day** (the list names the day before the step), equal `bundled.steps.skip(1)` dates, 27 of them, offsets 11 to 37 in order; (b) `#define TABEND <n>` in `swephlib.c` gives `DeltaTDataset.bundled.estimatedBefore == DateTime.utc(n + 1)`.
- [ ] **Step 2: Run** `dart test` in `packages/astro_core` and `dart test test/vendored_time_data_test.dart` in `packages/ephemeris_swiss`. Expected: FAIL, names undefined.
- [ ] **Step 3: Implement** the interfaces above. `taiMinusUtcSecondsAt` is the last step with `from <= utc`.
- [ ] **Step 4: Run** both again, then `dart test test/architecture` at the root. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-002): add the leap-second time conversion and delta T status`.

### Task 2: One locked native library state

**Files:**
- Create: `native/swisseph/zodiann_swiss_lock.h`, `zodiann_swiss_lock.c`
- Modify: `packages/ephemeris_swiss/hook/build.dart`, `tool/ffigen.dart`, `lib/src/swiss_ephemeris_binding.dart`; regenerate `lib/src/ffi/swisseph_bindings.g.dart`
- Test: `packages/ephemeris_swiss/test/native_lock_guard_test.dart`, `apps/astro_mobile/integration_test/swiss_ephemeris_concurrency_test.dart`

**Interfaces — Produces** (C; the header includes no system header):

```c
void zodiann_swiss_version(char *out);              /* at least 256 bytes */
void zodiann_swiss_set_ephe_path(const char *path);
void zodiann_swiss_close(void);
int zodiann_swiss_calc_ut(double tjd_ut, int ipl, int iflag, double *xx, char *serr);
int zodiann_swiss_calc_tt(double tjd_tt, int ipl, int iflag, double *xx, char *serr);
```

`SwissEphemerisBinding`'s public methods and signatures are unchanged.

- [ ] **Step 1: Write the failing device test.** `setUpAll` copies the two assets into `<support>/ephe` (as the spike test does) and calls `setEphePath` once, in the main isolate. A top-level worker builds its own `SwissEphemerisBinding`, **never calls `setEphePath`**, and returns longitude, speed and `usedSwissEphemerisFiles` for a grid of bodies 0 to 9 at `1900-06-15T06:00Z`, `1971-12-31T00:00Z` (both `calcUt`), `2000-01-01T12:00Z`, `2050-01-01T00:00Z`, `2100-12-31T00:00Z` (both `calcTt(julianDayUt(utc) + 69.184 / 86400)`).
  * `'an isolate that never set the path reads the data files'`: `await Isolate.run(worker)`; every row used the files and equals the main isolate's result exactly.
  * `'concurrent isolates match sequential results'`: 4 isolates at once, each repeating the grid 50 times in a different rotation order; every row used the files and equals the sequential baseline exactly (`==` on both doubles).
- [ ] **Step 2: Run** it on the emulator against the unchanged library. Expected: the first test FAILS (per-thread state: the worker falls back to Moshier). If it passes, stop and find out why before continuing.
- [ ] **Step 3: Write the guard test** (host, text scan):
  * the generated bindings declare exactly the five `zodiann_swiss_*` externals and no `swe_*` one;
  * no `.dart` file under `apps/` or `packages/` (this guard excluded, build output excluded) has an `external` declaration named `swe_\w+`, or a string literal that is entirely a symbol (`['"]swe_\w+['"]`; error messages that merely mention a function do not count);
  * the C file: each of the five function bodies contains, in this order, one `pthread_mutex_lock(&zodiann_swiss_mutex)`, one upstream `swe_` call, one `pthread_mutex_unlock(&zodiann_swiss_mutex)`, and **no call to another `zodiann_swiss_` function** (the mutex is not recursive);
  * the C file has `#error` under `#ifndef TLSOFF`;
  * the hook lists `zodiann_swiss_lock.c` and defines `TLSOFF`.
  Run it: FAIL.
- [ ] **Step 4: Implement.** C: `static pthread_mutex_t zodiann_swiss_mutex = PTHREAD_MUTEX_INITIALIZER;`, include `swephexp.h`, store the return value, unlock, return it. SPDX `AGPL-3.0-only` header. State in a comment that `swe_set_ephe_path` calls upstream `swe_calc` internally, which is safe only because that inner call is the unlocked upstream symbol. Hook: add the source, `'../../native/swisseph'` to `includes`, `defines: {'TLSOFF': null}`, and the `.c` and `.h` to `output.dependencies`; correct the stale `ffigen.yaml` comments in `hook/build.dart` and the package `pubspec.yaml`. ffigen: entry point is the project header, the five names, drop the NDK sysroot options (no system header), keep the output path and asset id; run `dart run tool/ffigen.dart` from the package. Binding: call the new functions; replace the "does nothing to serialize" doc comment with the shared-state rule (path set once, applies to every isolate; `close()` likewise affects every isolate).
- [ ] **Step 5: Run** the guard (PASS), then on the emulator `swiss_ephemeris_concurrency_test.dart`, `swiss_ephemeris_spike_test.dart` and `astronomy_speed_vs_swiss_test.dart`. Expected: all PASS.
- [ ] **Step 6: Mutation check (not committed):** comment out the lock and unlock lines, run the concurrency test three times, record the result, restore, and confirm `git diff` is clean for the C file. A pass without the lock is recorded as "race not reproduced", not as proof.
- [ ] **Step 7: Commit** `feat(ZOD-EPH-002): serialize one shared Swiss Ephemeris state`.

### Task 3: Calculation source and adapter

**Files:**
- Create: `packages/ephemeris_swiss/lib/src/swiss_calculation_source.dart`, `lib/src/swiss_ephemeris.dart`, `lib/src/native_swiss_calculation_source.dart`
- Modify: `lib/ephemeris_swiss.dart` (export the first two), `lib/ephemeris_swiss_native.dart` (export the third), `test/data_files_test.dart` (use `SupportedDateRange`), `test/architecture/node_bypass.dart` (allowlist)
- Test: `packages/ephemeris_swiss/test/swiss_ephemeris_test.dart`

**Interfaces — Consumes:** Task 1. **Produces:**

```dart
const int swissAdapterFlags = seflgSwieph | seflgSpeed;
const Map<Body, int> swissBodyIds;   // sun 0, moon 1, mercury 2 … neptune 8, pluto 9; no node
abstract interface class SwissCalculationSource {
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags});
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags});
}
final class UnavailableSwissCalculationSource implements SwissCalculationSource {
  const UnavailableSwissCalculationSource();          // both return null
}
/// No range check: used by the adapter and by the edge measurement.
SwissCalcResult? calculateSwissBody(SwissCalculationSource source, Body body, DateTime utc,
    {LeapSecondTable? leapSeconds});
final class SwissEphemeris with MeanAscendingNodeFormula implements EphemerisPort {
  SwissEphemeris({required this._source, this._leapSeconds});
  static final UtcRange fileCoverage;  // provisional utc(1800, 1, 2) to utc(2399, 12, 31); Task 4 measures it
}
final class NativeSwissCalculationSource implements SwissCalculationSource {
  NativeSwissCalculationSource(SwissEphemerisBinding binding); // StateError from the binding -> null
}
```

The constructor does no native call. `coveredRange` returns `fileCoverage`. `calculateSwissBody` lives in `swiss_calculation_source.dart` and throws `ArgumentError` for `Body.node`. The two sources neither implement `EphemerisPort` nor mix in the node formula. The adapter's doc states that before 1972 the UTC input is treated as Universal Time (it may differ from UT1 by the DUT1 of the day).

- [ ] **Step 1: Write the failing tests** with a recording fake source:
  * `swissBodyIds` is exactly the ten physical bodies with the values above.
  * For each body at `utc(1971, 12, 31, 23, 59, 59, 999, 999)`: one `calcUt` with that instant, the body id and flags `258`; no `calcTt`.
  * At `utc(1972)` and `utc(2026, 11, 26)`: one `calcTt` with `julianDayUt(utc.add(Duration(microseconds: 32184000 + n * 1000000)))` (n = 10 and 37), flags `258`; no `calcUt`.
  * A custom leap table changes the TT passed.
  * Success: longitude normalized (`-1e-15` gives `0.0`, `370` gives `10`), speed equal to the result's speed, one call only.
  * Each of: `null`; Moshier flag; warning text; return flags `-5` with an empty error (the Swiss bit set and the Moshier bit clear, so only the sign check rejects it); NaN or infinite longitude; NaN speed → `OutOfCoveredRange(requested: utc, covered: port.coveredRange)`.
  * `calculateSwissBody` with `Body.node` throws `ArgumentError`.
  * Over `UnavailableSwissCalculationSource`: all ten bodies give `OutOfCoveredRange`; the node still succeeds.
  * One microsecond before `coveredRange.start` and after `.end`: `OutOfCoveredRange`, no source call; both ends themselves call the source.
  * Node: `EphemerisSuccess(meanAscendingNodeAt(utc))` also outside coverage, no source call.
  * Non-UTC throws `ArgumentError` for a body and for the node.
  * `coveredRange` contains `SupportedDateRange.start` and `.end`.
- [ ] **Step 2: Run** `dart test` in the package: FAIL.
- [ ] **Step 3: Implement.** `position` order: UTC check, node, range, `calculateSwissBody`, then reject unless `usedSwissEphemerisFiles`, `returnFlags >= 0` and both numbers finite. Add the allowlist entry `'packages/ephemeris_swiss/lib/src/swiss_ephemeris.dart': 'A source adapter: its own position() node branch uses the shared formula (ZOD-EPH-002).'`. Library doc comments describe the new exports.
- [ ] **Step 4: Run** the package tests, `dart test test/architecture`, and `dart analyze --fatal-infos packages/ephemeris_swiss`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-002): add the Swiss Ephemeris adapter over an injected source`.

### Task 4: Measure the file coverage on the device

**Files:**
- Create: `apps/astro_mobile/integration_test/support/swiss_data.dart` (copies assets to a directory; used by Tasks 4, 5), `integration_test/swiss_file_edges_test.dart`
- Modify: `packages/ephemeris_swiss/lib/src/swiss_ephemeris.dart` (`fileCoverage`); `packages/ephemeris_swiss/test/data_files_test.dart` comment

**Interfaces — Produces:** `Future<Directory> installTestSwissData()`; the measured `SwissEphemeris.fileCoverage`.

- [ ] **Step 1: Write the test.** "Fails at t" means `calculateSwissBody(nativeSource, body, t)` is null or not `usedSwissEphemerisFiles` (the production conversion, both paths). For each body bisect to one minute: lower edge between `utc(1790)` (must fail) and `utc(1801)` (must succeed); upper between `utc(2398)` (succeed) and `utc(2410)` (fail); assert those four preconditions. Take the latest lower and earliest upper failure over the ten bodies, apply P7, print per body and the result, and assert `SwissEphemeris.fileCoverage` equals it. Second test: every body succeeds hourly over the first and last 40 days of `fileCoverage`. Third: 40 days outside each end at least one body fails.
- [ ] **Step 2: Run** on the emulator. Expected: the first test FAILS against the provisional constant and prints the measured range (a pass means the provisional values were right).
- [ ] **Step 3: Set** `fileCoverage` to the printed range, with a comment naming the test, device and date.
- [ ] **Step 4: Run** the device test and the package's host tests. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ZOD-EPH-002): set the measured Swiss data coverage`.

### Task 5: Accuracy gates on the device

**Files:**
- Create: `packages/ephemeris_swiss/tool/tt_grid.c`, `tool/fetch_horizons_tt_reference.dart`, `test/fixtures/reference_longitudes_tt.json`, `test/reference_tt_fixture_test.dart`
- Create: `apps/astro_mobile/integration_test/swiss_reference_longitudes_tt.dart`, `test/swiss_reference_longitudes_tt_match_test.dart`, `integration_test/swiss_ephemeris_accuracy_test.dart`

**Interfaces — Consumes:** `ephemerisTimeFor`, `julianDayUt`, `SwissEphemeris`, `NativeSwissCalculationSource`, `installTestSwissData`, and the existing UT copy `integration_test/astronomy_reference_longitudes.dart` (530 rows). **Produces:** `swissTtReferenceLongitudes`, records `({String body, String utc, String jdTt, double ttMinusUtSeconds, double longitudeDegrees})`, and `swissTtToleranceArcseconds = 1`.

- [ ] **Step 1: Write the failing host fixture test** (model: `ephemeris_astronomy/test/reference_tt_fixture_test.dart`): Horizons source and retrieval date; `CENTER 500@399`, `QUANTITIES 31`, `TIME_TYPE TT`; tolerance 1; ten bodies × every instant of `reference_dates.json` (53), no duplicates; `jdTt` has nine decimals; for instants from 1972, `jdTt == julianDayUt(utc.add(offset)).toStringAsFixed(9)` with the offset from `ephemerisTimeFor`; before 1972, `jdTt` equals `julianDayUt(utc) + ttMinusUtSeconds / 86400` within 2e-9. Run: FAIL (no fixture).
- [ ] **Step 2: Write the tool**, following `ephemeris_astronomy/tool/fetch_horizons_tt_reference.dart` (same request parameters, date-echo check, one second between bodies). TT per instant: from 1972 from `ephemerisTimeFor`; before 1972 `tt_grid.c` (arguments: data directory, then UT Julian days) calls `swe_set_ephe_path`, then `swe_deltat_ex(jd, SEFLG_SWIEPH, serr)` and prints seconds with 12 decimals, exiting non-zero on a warning; the tool compiles it with gcc `-O1 -std=gnu99` against the nine upstream sources and `-lm` in a temporary directory. It writes the fixture and the app copy.
- [ ] **Step 3: Run** `dart run tool/fetch_horizons_tt_reference.dart` from the package (network: Horizons only, dates and body ids only), then the fixture test, then add the match test (every field equal, as the astronomy match test does) and run it. Expected: PASS.
- [ ] **Step 4: Write the device test.** Port under test is the **bare** `SwissEphemeris` over the native source (the first reference instant is 1899-12-31T12:00Z, which the wrapper rejects). Tests:
  * the comparison itself: 1.01″ off fails the bound, 0.99″ passes, wrap at 360;
  * `'UTC input: all ten bodies, 53 instants, within 1 arcsecond'`: 530 successes, each ≤ 1.0″; print each body's maximum;
  * `'matched TT: all ten bodies within 1 arcsecond'`: `binding.calcTt(double.parse(jdTt), id)` used the files, ≤ 1.0″, 530 rows; print maxima;
  * `'the fixture TT is the TT the adapter uses'`: for the 53 Moon rows, adapter longitude vs that `calcTt` longitude ≤ 0.0005″;
  * `'speed is the library speed'`: adapter speed equals `xx[3]` from the matching direct call for all ten bodies at `2026-11-26` and `1950-01-01`;
  * `'supported and covered edges'`: all ten bodies succeed at `SupportedDateRange.start`, `.end`, `fileCoverage.start`, `.end`; one microsecond outside coverage gives `OutOfCoveredRange`;
  * `'empty directory'`: path set to an empty temporary directory, all ten give `OutOfCoveredRange`;
  * `'damaged files'`, at `2000-01-01T12:00Z`, in two temporary directories, the process surviving both: both files overwritten with 4,096 zero bytes → all ten `OutOfCoveredRange`; both truncated to half → each body is either `OutOfCoveredRange` or within 1″ of the intact result. A crash or a wrong success is a stop-and-report finding.
  Restore the good path after the control tests.
- [ ] **Step 5: Run** on the emulator and keep the printed maxima for the docs. Expected: PASS. A longitude miss: stop and report.
- [ ] **Step 6: Mutation check (not committed):** add `1.0 / 24` to the adapter's TT Julian day; the UTC gate must fail. Restore.
- [ ] **Step 7: Commit** `test(ZOD-EPH-002): gate Swiss accuracy by UTC input and at matched TT`.

### Task 6: Data-file installer and `path_provider` at run time

**Files:**
- Create: `apps/astro_mobile/lib/src/ephemeris/swiss_data_installer.dart`
- Test: `apps/astro_mobile/test/ephemeris/swiss_data_installer_test.dart`
- Modify: `apps/astro_mobile/pubspec.yaml`, `pubspec.lock` if it changes, `docs/licensing/third-party-inventory.md`, `THIRD_PARTY_NOTICES.md`

**Interfaces — Produces:**

```dart
const String swissDataAssetDirectory = 'packages/ephemeris_swiss/assets/ephe';
const List<String> swissDataFileNames = ['sepl_18.se1', 'semo_18.se1'];
/// True only when both files in [directory] hold exactly the bundled bytes. Never throws.
Future<bool> installSwissData({
  required Future<Uint8List> Function(String fileName) loadBundled,
  required Directory directory,
});
```

- [ ] **Step 1: Write the failing tests** (temporary directories, small fake bytes):
  * the names equal the files in `../../packages/ephemeris_swiss/assets/ephe`;
  * fresh install creates the directory, writes both, returns true, leaves no `.tmp`;
  * a second run leaves an old `lastModified` (set in the test) unchanged;
  * same-size different bytes are replaced; a shorter target is replaced;
  * a stale `<name>.tmp` with junk beside an **already correct** target is gone afterwards;
  * the directory path occupied by a file → false, no throw;
  * a directory where `sepl_18.se1` should be → false, and `semo_18.se1` is still installed;
  * `loadBundled` throwing for one name → false, the other installed, and an existing older copy of the failed name still reports false.
- [ ] **Step 2: Run** `flutter test test/ephemeris/swiss_data_installer_test.dart`: FAIL.
- [ ] **Step 3: Implement:** per file, in its own `try`: delete any existing `<name>.tmp`; load; if the target's bytes differ or it is missing, write `<name>.tmp` with `flush: true`, rename over the target; success is a read-back equal to the bundled bytes.
- [ ] **Step 4: Run:** PASS.
- [ ] **Step 5: Promote `path_provider`.** Save `dart pub deps --json` to the scratchpad; move `path_provider: ^2.1.6` to `dependencies` with a comment; `flutter pub get`; save the output again. Compute `astro_mobile`'s regular-dependency closure from both (the walk in `test/architecture/dependency_closure.dart`). Check **every** inventory row against the full after-closure, not only the difference. Expected to enter newly: `jni_flutter`, `path_provider`, `path_provider_android`, `path_provider_foundation`. Expected to be in the closure already since ZOD-L10-002 yet labelled `dev/test/tool only` (correct them and say it is a correction): `args`, `convert`, `jni`, `jni_util`, `objective_c`, `package_config`, `path_provider_linux`, `path_provider_platform_interface`, `path_provider_windows`, `plugin_platform_interface`, `typed_data`, `web`, `xdg_directories`. The command output is the authority. Change those rows to the inventory's runtime wording, rewrite section 4's native-plugins row (`jni`'s native code already ships, `jni_flutter` newly ships, both unread), and change the matching `(tool)` labels in `THIRD_PARTY_NOTICES.md` to `(runtime)`. Re-read each of these packages' LICENSE in the pub cache. Any license other than those already recorded: stop and ask.
- [ ] **Step 6: Run** `dart test test/architecture`. Expected: PASS.
- [ ] **Step 7: Commit** `feat(ZOD-EPH-002): install the Swiss data files on the device`.

### Task 7: Startup wiring and source selection

**Files:**
- Create: `apps/astro_mobile/lib/src/di/ephemeris_wiring.dart`, `lib/src/ephemeris/ephemeris_status.dart`
- Create: `apps/astro_mobile/test/di/ephemeris_wiring_test.dart`, `test/di/support/fake_ephemeris_dependencies.dart`, `test/ephemeris/ephemeris_status_test.dart`, `integration_test/swiss_startup_test.dart`
- Modify: `lib/main.dart`, `lib/src/bootstrap.dart`, `lib/src/di/ephemeris_providers.dart`, `lib/src/di/app_overrides.dart` (doc comment)
- Modify: `test/app_shell_test.dart`, `test/localization/first_launch_test.dart`, `test/di/ephemeris_providers_test.dart`, `test/di/astronomy_swap_test.dart`; comments in `test/architecture/port_binding_test.dart`, `packages/ephemeris_swiss/hook/build.dart` and the two packages' `*_native.dart`

**Interfaces — Consumes:** Tasks 1, 3, 6; `AstronomyEphemeris`, `BodyStateSource`, `NativeBodyStateSource`. **Produces:**

```dart
// ephemeris_status.dart
enum ActiveEphemerisSource { primary, backup, none }
enum ReportedTimeBasis { historicalDeltaT, publishedLeapSeconds, assumedContinuousUtc, backupOwnDeltaT }
final class EphemerisStatus {
  const EphemerisStatus(this.source);
  final ActiveEphemerisSource source;
  ReportedTimeBasis? timeBasisAt(DateTime utc);   // none: null; backup: backupOwnDeltaT
  DeltaTStatus? dataStatusAt(DateTime utc);       // primary only, else null
}
// ephemeris_providers.dart: ephemerisStatusProvider (Provider<EphemerisStatus>, throws StateError unbound)
// ephemeris_wiring.dart
final class EphemerisDependencies {
  const EphemerisDependencies({required this.swissLoads, required this.prepareSwissData,
    required this.openSwissSource, required this.backupLoads, required this.openBackupSource});
  final bool Function() swissLoads;
  final Future<String?> Function() prepareSwissData;   // data directory, or null: not installed
  final SwissCalculationSource Function(String directory) openSwissSource; // sets the path once
  final bool Function() backupLoads;
  final BodyStateSource Function() openBackupSource;
}
EphemerisDependencies productionEphemerisDependencies();
Future<List<Override>> ephemerisOverrides(EphemerisDependencies dependencies); // never throws
// bootstrap.dart: adds `required EphemerisDependencies ephemeris`
// main.dart: Future<void> main() => startZodiann(ephemeris: productionEphemerisDependencies());
//            Future<void> startZodiann({required EphemerisDependencies ephemeris});
```

Non-UTC input to either status method throws `ArgumentError` for every source.

| Swiss loads | data | backup loads | active | source inside the wrapper |
|---|---|---|---|---|
| yes | directory | not probed | primary | Swiss over the opened source |
| yes | null, or `prepare` or `open` throws | not probed | none | Swiss over unavailable |
| no or probe throws | not prepared | yes | backup | astronomy over the opened source |
| no or probe throws | not prepared | no, or probe or open throws | none | Swiss over unavailable |

- [ ] **Step 1: Write the failing status test:** primary at `utc(1971, 12, 31)` → `historicalDeltaT`/`observed`; `utc(2000)` → `publishedLeapSeconds`/`observed`; `utc(2027, 6, 28)` → `assumedContinuousUtc`/`estimated`; `utc(2030)` → `assumedContinuousUtc`/`forecast`; backup → `backupOwnDeltaT`/`null`; none → `null`/`null`; non-UTC throws.
- [ ] **Step 2: Write the failing wiring test** with fake dependencies that count calls (never a port). Per table row (including every "throws" variant): the status source; the bound port `isA<SupportedRangeEphemeris>()`; Sun at `utc(2000)` (success from the fake for primary and backup, with distinguishable longitudes; `OutOfCoveredRange` for none); the call counts ("not probed", "not prepared", `openSwissSource` once with the prepared directory). `utc(1899, 6, 1)` → `OutsideSupportedRange` for every row. The "throws" fakes throw an `Error` (`ArgumentError`), as a failed native resolution does. The default fake factory has both probes false. Production on the host (no native library is built for it): take `p = productionEphemerisDependencies()`; `expect(p.swissLoads, throwsA(anything))` and the same for `p.backupLoads`; then `ephemerisOverrides` over `p`'s four other members and a counting `prepareSwissData` gives status `none` with count 0. Startup: `bootstrapOverrides` with dependencies that all throw still returns the saved language override.
- [ ] **Step 3: Run:** FAIL.
- [ ] **Step 4: Implement.** The binding, computed sources first, then:

```dart
ephemerisPortProvider.overrideWithValue(
  SupportedRangeEphemeris(
    backup == null
        ? SwissEphemeris(source: swiss)
        : AstronomyEphemeris(source: backup),
  ),
)
```

After selection, `ephemerisOverrides` writes one line with `debugPrint`: `zodiann ephemeris source: <primary|backup|none>`. Production dependencies: `swissLoads` calls `SwissEphemerisBinding().version()` and returns true; `backupLoads` computes the Sun at `utc(2000)` through `const NativeBodyStateSource()`; `prepareSwissData` uses `getApplicationSupportDirectory()` + `/ephe`, `rootBundle.load`, `installSwissData`, returning the path or null; `openSwissSource` builds one binding, `setEphePath(directory)`, `NativeSwissCalculationSource`. `bootstrapOverrides` returns `[...appOverrides, ...await ephemerisOverrides(ephemeris), appLocaleProvider.overrideWithValue(locale)]`. The unbound port's error message and doc comment name `bootstrapOverrides`.
- [ ] **Step 5: Update existing tests, keeping each one's intent:**
  * `app_shell_test`: run `startZodiann(ephemeris: fake)` instead of `app.main`; expect `appOverrides.length + 3` overrides; assert the mounted container's port is a `SupportedRangeEphemeris`.
  * `first_launch_test`: pass the fake to `bootstrapOverrides`; the text check also requires `startZodiann(ephemeris: productionEphemerisDependencies())`.
  * `ephemeris_providers_test`: message contains `bootstrapOverrides`; the `appOverrides` test says the port is bound at bootstrap, not there.
  * `astronomy_swap_test`: the import scan exempts exactly `lib/src/di/ephemeris_wiring.dart` (assert it exists and does import the package); rename the "not wired" test and its header comment.
  * Reword the "never import native bindings from host tests" comments: host code may compile these imports (the wiring does) but must not rely on a native call succeeding.
- [ ] **Step 6: Run** `flutter test` in `apps/astro_mobile` and `dart test test/architecture`. Expected: PASS, including `port_binding_test` and `node_bypass_test` unchanged in rules. If a guard rejects the code, change the code, not the guard.
- [ ] **Step 7: Write and run the device startup test.** First test: delete `<support>/ephe`; `bootstrapOverrides` with `productionEphemerisDependencies()` → status `primary`; the bound port gives success for all ten bodies and the node at `2026-11-26T00:00Z`; a second bootstrap leaves the installed files' modification times unchanged. Second test: the production dependencies with only `swissLoads: () => false` and a counting `prepareSwissData` → status `backup`, count 0, success for all ten bodies at the same instant.
- [ ] **Step 8: Commit** `feat(ZOD-EPH-002): bind the ephemeris source at startup with the backup fallback`.

### Task 8: Release build, full verification and records

**Files:**
- Modify, correcting every statement this task makes stale: `native/swisseph/README.md` (the project files beside `upstream/`, `TLSOFF`, "spike subset"), `native/swisseph/VENDORED.md`, `THIRD_PARTY_NOTICES.md` (what the generated bindings derive from), `docs/licensing/third-party-inventory.md` section 4 (when each native library is in a release APK), `docs/decisions/ZOD-EPH-002-time-scale.md` (status: implemented; device results), `docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md` section 3 (measured edges), the design doc (measured coverage), `apps/astro_mobile/pubspec.yaml` (comments on APK contents and the spike subset), `docs/PROGRESS.md` (hand-offs of Step 5)

- [ ] **Step 1: Release APKs:** from `apps/astro_mobile`, `flutter build apk --release --split-per-abi`; for `armeabi-v7a`, `arm64-v8a`, `x86_64`: `unzip -l build/app/outputs/flutter-apk/app-<abi>-release.apk | grep -E "libswisseph|libastronomy|libdartjni|\.se1"`. Required in all three: `libswisseph.so`, `libastronomy.so` and both `.se1` assets. Record APK sizes and each library's size against the FND-003 baseline (section 4), and check with NDK 28.2 `llvm-readelf -lW` that the rebuilt `libswisseph.so` keeps `0x4000` `LOAD` alignment on all three.
- [ ] **Step 2: Release smoke test:** `$ADB uninstall com.zodiann.app` (a fresh data-file install), `$ADB install` the x86_64 APK, `$ADB logcat -c`, launch with `$ADB shell monkey -p com.zodiann.app -c android.intent.category.LAUNCHER 1`. Required: `$ADB logcat -d -s flutter` contains `zodiann ephemeris source: primary`; `$ADB logcat -d` shows no fatal exception or native crash; `$ADB shell pidof com.zodiann.app` returns a pid.
- [ ] **Step 3: All device tests.** First `$ADB uninstall com.zodiann.app` (the split release APK has a higher version code). Run every `integration_test/*_test.dart` one file at a time. For `offline_fonts_test.dart` run `$ADB shell cmd connectivity airplane-mode enable` before and `... disable` after. For `storage_persistence_test.dart` use the two-launch procedure in its header, or record that only phase 1 (`STORAGE_PHASE_1_WRITTEN`) ran. Expected: PASS; record each result.
- [ ] **Step 4: Full host verification** from the root: `dart run melos run lint`, `dart run melos run test`, `git status --short`. Expected: PASS; only `grep.exe.stackdump` untracked besides this task's edits.
- [ ] **Step 5: Records** listed under Files, with ARM devices and iOS stated as unverified. Record these hand-offs in `PROGRESS.md` (other task files are not edited): (a) ZOD-TST-001: T-EPH-1 here uses the EPH-004 UT copy and the new Swiss TT fixture; adding instants means refetching both and updating the 53 and 530 counts; TST-001 repoints T-EPH-1 to its fixture. (b) ZOD-EPH-006 or the crossing tasks: the backup's unsynchronised state is not serialized (recommended addition). (c) ZOD-CRS-001/002: the TT steps. (d) ZOD-CRS-001 and ZOD-EPH-005: Swiss speed glitches near solar conjunction. (e) ZOD-IOS-001: the iOS hook must compile `zodiann_swiss_lock.c` with `-DTLSOFF`, and the concurrency and startup tests need an iOS run. (f) ZOD-NFR-017: the time basis and ΔT status come from `ephemerisStatusProvider` (app layer). The task status, `TASKS.md` and the completion entry in `PROGRESS.md` are written only after the independent whole-branch review and its fixes (zodiann-development workflow).
- [ ] **Step 6: Commit** `docs(ZOD-EPH-002): record the release and device verification`.

## Coverage of the acceptance criteria

| Criterion | Where proved |
|---|---|
| T-EPH-1: Sun and Moon within 1″ on 10+ dates (owner: all ten bodies, 53 instants, UTC and TT) | Task 5 |
| Out-of-range date returns the typed error | Tasks 3, 5, 7 |
| No extra precession | Task 3 (flags exactly 258), Task 5 gates |
| Speed read from the ephemeris | Tasks 3, 5 |

## Risks

* An accuracy miss on the device (measured only on this PC): the task stops for an owner decision.
* The native library may crash on a damaged file (Task 5 finds out). The installer restores bundled bytes at each launch, which limits exposure.
* ARM devices and iOS are unverified.
* Until ZOD-EPH-006 the backup uses its own ΔT (Moon up to 78.6″ at 2100).
* The backup library's unsynchronised state is not serialized here: concurrent isolates using the backup could get a wrong Pluto (hand-off in Task 8).

## Execution

Sequential in one session: each task consumes the previous one's interfaces, so no parallel work is justified. A fresh reviewer checks the whole branch afterwards.

## Plan review

### Round 1 (2026-11-26, `plan-reviewer`, comprehensive, on commit `5ba55a0`)

Verdict: **approve after corrections.** No product decision needed.

| ID | Severity | Finding | Action |
|---|---|---|---|
| C1 | Critical | The named emulator `Pixel_9_Pro_API_35` no longer exists (confirmed with `emulator -list-avds`) | Applied: `Pixel_9_Pro_API_36` (x86_64), AVD and API recorded with results, logcat fallback |
| I1 | Important | Release checks would pass with the source silently `none` or without the backup library | Applied: startup log line, both libraries and data files required, fresh install, Review Focus 6 |
| I2 | Important | Startup tests allowed an always-true Swiss probe and never ran the production backup on a device | Applied: probe assertions, counting preparation, fresh install and backup device test |
| I3 | Important | "All device tests pass" was false for the airplane-mode and two-launch tests | Applied: documented procedures and uninstall first |
| I4 | Important | Wrong expected package list; rows already wrong would stay wrong | Applied: full-closure check with both lists, notices updated |
| I5 | Important | Lint and tests were required only at the end | Applied: global constraint before every commit |
| I6 | Important | Hand-offs and the ZOD-TST-001 overlap were not recorded | Applied: Task 8 Step 5 and Risks |
| M1 | Minor | Symbol guard would trip on error messages | Applied |
| M2 | Minor | Contradictory damaged-file assertions | Applied |
| M3 | Minor | Negative-flag case did not test the sign check | Applied |
| M4 | Minor | `coveredRange`, helper location and node behaviour unstated | Applied |
| M5 | Minor | Stale temp file could survive | Applied |
| M6 | Minor | Stale statements elsewhere; alignment not re-checked | Applied |
| M7 | Minor | Include path, stale comments, `close()` and pre-1972 notes | Applied |

Reviewer's own host checks (not device evidence): the leap list matches `swedate.c`; UT-input maxima 0.56″ (all bodies); measured file edges about 1800-01-03 to 2400-01-06 under P7; truncated and zeroed files returned errors without a crash.
