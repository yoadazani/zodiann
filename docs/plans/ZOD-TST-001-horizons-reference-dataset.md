# ZOD-TST-001: JPL Horizons Reference Dataset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, **sequentially in one session** (the tasks share files and interfaces). Steps use checkbox (`- [ ]`) syntax for tracking. **Do not start before the owner approves this plan.**

**Goal:** One versioned Horizons reference dataset, compared at matching TT instants, that T-EPH-1 and ACC-1 consume, plus a separate mean-node validation against Swiss Ephemeris.

**Architecture:** The shared instants stay in `astro_core/test/fixtures` (version 2). A host tool in `ephemeris_swiss/tool` asks Horizons in TT at the TT the app assigns, checks every answer, and writes the dataset beside them; a generated const copy feeds the device test. The node reference comes from the vendored Swiss source compiled on the host.

**Tech Stack:** Dart 3.14.0 / Flutter 3.50.0 (FVM), `package:test`, `integration_test`, gcc (host C tools), JPL Horizons API.

**Spec:** [`docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md`](../superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md) ("the design"). Task file: [`ZOD-TST-001`](../development/testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md).

**Branch:** `task/ZOD-TST-001-jpl-horizons-reference-dataset` (from `main` @ `c7df9c6`).

## Global Constraints

* **No file under any `lib/` changes.** No `EphemerisPort`, adapter, backup implementation, backup range, formula or specification change. `native/*/upstream/` stays byte-identical.
* Tolerances, never loosened, no body or instant dropped to pass: **1″** for each of the ten bodies against Horizons; node **0.01°**; Horizons TT-against-UT agreement **0.002″**; device TT pin **0.0005″**; echoed time **1 ms**; row protection **0.001″**. A failing gate means stop and report.
* Every primary comparison is at the same TT (design section 6). Before 1972 no UT-asked Horizons value is gated.
* Horizons requests only with the parameters and dates of design sections 5 and 8, sequential, at least 1 s apart. A new date or parameter needs the owner. Requests carry dates and body numbers only. Raw responses go to a scratch directory outside the repository.
* `reference_dates.json` is add-only: `version` 1 → 2, no instant dropped or changed.
* Commands run in PowerShell from the repository root with `fvm …` (a bare `melos` or global `dart` fails). Do not run a root `fvm flutter pub get` without restoring `packages/shared_ui/lib/l10n` with `git checkout -- packages/shared_ui/lib/l10n`.
* Commits: `<type>(ZOD-TST-001): <summary>` with the session's attribution trailers; explicit staging only; never stage `grep.exe.stackdump`. No push, PR or merge without the owner's approval.

## Review Focus

1. Horizons reads the time list as UT although TT was meant: the parser's scale check (Task 3) and the time-scale control (Tasks 5 and 6) must fail.
2. Rows reordered, dropped or shifted in an answer: every echoed time is compared with the requested one, in order (Task 3).
3. A refetch silently changes or loses a reference row: `changedRows` reports both (Task 1) and the tool writes nothing.
4. Longitudes across 0°/360° in differences and retrograde checks (Task 1).
5. A date added to the shared set without refetching: version and instant-set tests fail (Task 6).

## Acceptance mapping

| Criterion (task file) | Evidence |
|---|---|
| ≥50 dates 1900 to 2100, ten bodies, a retrograde instant per body (owner decision: Mercury to Pluto), one near a year boundary | `horizons_reference_test.dart` (63 instants inside the range; 640 rows; retrograde evidence; year boundary); Task 4 confirmation |
| T-EPH-1 and ACC-1 consume this exact fixture | `swiss_ephemeris_accuracy_test.dart` imports only the shared copy; `horizons_reference_match_test.dart`; the old Swiss fixture removed (Task 6); device run (Task 8) |
| Node validated against Swiss separately, documented | Task 7 host and device tests; design section 7 |

## File structure

| File | Responsibility |
|---|---|
| `packages/ephemeris_swiss/tool/horizons/horizons.dart` | pure: query, parser, angle, retrograde and row checks |
| `packages/ephemeris_swiss/tool/horizons/swiss_host.dart` | compile and run a host C tool against the vendored Swiss source |
| `packages/ephemeris_swiss/tool/fetch_horizons_reference.dart` | the only network code: modes `pilot`, `confirm-retrograde`, `dataset` |
| `packages/ephemeris_swiss/tool/gen_horizons_copy.dart` | offline: dataset JSON → device const copy |
| `packages/ephemeris_swiss/tool/node_grid.c`, `gen_swiss_mean_node.dart` | node reference fixture |
| `packages/astro_core/test/fixtures/{reference_dates,horizons_reference,swiss_mean_node}.json` | shared data |
| `apps/astro_mobile/integration_test/horizons_reference.dart` | generated device copy |

---

### Task 0: Baseline

- [ ] **Step 1:** Run `fvm dart run melos run lint`, then `fvm dart run melos run test`. Expected: both exit 0. Record counts. If either fails, stop and report.

### Task 1: Pure query and check functions

**Files:** Create `packages/ephemeris_swiss/tool/horizons/horizons.dart`; Test `packages/ephemeris_swiss/test/horizons_tool_test.dart` (imports `'../tool/horizons/horizons.dart'`).

**Interfaces (produces):**

```dart
enum HorizonsTimeType { tt, ut }
const Map<String, String> horizonsCommands; // sun '10' … pluto '999'
typedef LongitudeRow = ({String body, String utc, double longitudeDegrees});
Map<String, String> horizonsQuery({required String command,
    required List<String> julianDays, required HorizonsTimeType timeType,
    String quantities = '31'});
double signedDegrees(double from, double to); // shortest angle to - from, [-180, 180)
bool isRetrograde({required double before, required double at, required double after});
List<String> changedRows(Iterable<LongitudeRow> baseline,
    Iterable<LongitudeRow> next, {double toleranceArcseconds = 0.001});
```

- [ ] **Step 1: Write the failing tests**

  * `the query is exactly the approved parameters`: `horizonsQuery(command: '301', julianDays: ['2451545.000000000', '2451546.000000000'], timeType: HorizonsTimeType.tt)` equals the map of design section 8 value for value (`TLIST` = `"'2451545.000000000 2451546.000000000'"`, `TIME_DIGITS` `"'FRACSEC'"`, `CAL_FORMAT` `"'BOTH'"`, `APPARENT` `"'AIRLESS'"`, `format` `'text'`); `ut` gives `TIME_TYPE` `"'UT'"`; `quantities: '30,31'` gives `"'30,31'"`.
  * `julian days must be ascending with nine decimals`: `ArgumentError` for `['2.000000000', '1.000000000']`, for `['2451545.0']` and for an empty list.
  * `signedDegrees wraps`: `(359.9, 0.1)` ≈ 0.2; `(0.1, 359.9)` ≈ −0.2; `(10, 190)` = −180.
  * `isRetrograde`: `(0.2, 0.0, 359.8)` true; `(359.8, 0.0, 0.2)` false; `(10, 9, 9.5)` false; `(10, 10, 9)` false.
  * `changedRows`: equal rows → empty; a difference of 0.0009″ → empty; 0.0011″ → one line naming body and utc; a baseline row missing from `next` → one line containing `missing`; an extra row in `next` → empty; `359.9999999` against `0.0000001` (0.00072″ apart across 0°) → empty at the default tolerance, one line at `toleranceArcseconds: 0.0001`.

- [ ] **Step 2:** `Set-Location packages/ephemeris_swiss; fvm dart test test/horizons_tool_test.dart`. Expected: compile failure, `horizons.dart` not found.
- [ ] **Step 3:** Implement. `horizonsCommands` as in the existing tools.
- [ ] **Step 4:** Rerun. Expected: all pass.
- [ ] **Step 5:** Commit `feat(ZOD-TST-001): add the Horizons query and reference checks`.

### Task 2: Pilot requests (first download)

**Files:** Create `packages/ephemeris_swiss/tool/fetch_horizons_reference.dart`; Create `packages/ephemeris_swiss/test/fixtures/horizons_sample_tt.txt`, `horizons_sample_ut.txt`.

**Interfaces:** `fvm dart run tool/fetch_horizons_reference.dart pilot --out <absolute dir outside the repo>` sends exactly two requests with `horizonsQuery`, command `'301'`, saves each raw answer in `<dir>`, and does nothing else:

| Request | Time type | Quantities | Julian days |
|---|---|---|---|
| 1 | TT | `31` | `2415020.000000000`, `2451545.000000000`, `2488434.000000000` |
| 2 | UT | `30,31` | the same |

- [ ] **Step 1:** Implement the `pilot` mode (HTTP GET as in the old tool: non-200 throws; 1 s between requests). Any other or missing mode prints usage and exits 64.
- [ ] **Step 2:** Run it. Expected: two files, each containing `$$SOE` and `$$EOE`.
- [ ] **Step 3: Inspect and record** in the design section 8: the exact time-scale header text for TT and UT, the Julian-day and fraction-of-second precision, the `ObsEcLon` and quantity 30 column labels, the API version line, the target `{source: …}` line, the centre line. **Stop and ask the owner** if the answer does not declare TT, or neither the printed Julian day nor the calendar time resolves 1 ms.
- [ ] **Step 4:** Copy the two answers unchanged to the sample files. Commit `test(ZOD-TST-001): capture the Horizons output format`.

### Task 3: Answer parser

**Files:** Modify `tool/horizons/horizons.dart`; Modify `test/horizons_tool_test.dart`.

**Interfaces (produces):**

```dart
typedef HorizonsRow = ({String julianDay, double longitudeDegrees, double? tdbMinusUtSeconds});
typedef HorizonsAnswer = ({String apiVersion, String targetLine, List<HorizonsRow> rows});
/// Throws FormatException unless every check passes. Rows are in request order;
/// `julianDay` is the requested string.
HorizonsAnswer parseHorizonsAnswer(String text, {required String command,
    required HorizonsTimeType timeType, required List<String> julianDays,
    bool expectTdbMinusUt = false});
```

Checks: both markers; a CSV header row, columns located **by name** (never by fixed index); the declared time scale equals `timeType`; the target line names `command`; the centre is the geocentre (500, body 399); as many rows as requested; each row's echoed time within 1 ms of its requested Julian day, in order; longitude in [0, 360); quantity 30 present when expected.

- [ ] **Step 1: Write the failing tests** against the samples: `parses the TT sample` (three rows, longitudes equal the literals read from the file, `apiVersion` and `targetLine` non-empty); `parses the UT sample with TDB-UT` (three non-null values); then one test per failure, each editing the sample text in memory and expecting `FormatException`: `a TT answer is refused for a UT request` and the reverse; `a missing row`; `two rows swapped`; `an echoed time 2 ms off`; `no ObsEcLon column`; `no $$EOE`; `another target` (parse with `command: '10'`); `a non-geocentric centre`; `longitude 360`; `quantity 30 expected but absent`.
- [ ] **Step 2:** Run. Expected: compile failure, `parseHorizonsAnswer` undefined.
- [ ] **Step 3:** Implement from the recorded format.
- [ ] **Step 4:** Run. Expected: all pass.
- [ ] **Step 5:** Commit `feat(ZOD-TST-001): parse Horizons answers and refuse mismatches`.

### Task 4: Confirm the retrograde dates with Horizons

**Files:** Create `tool/horizons/swiss_host.dart`; Modify `tool/fetch_horizons_reference.dart`; Modify `test/horizons_tool_test.dart`.

**Interfaces:**

```dart
// swiss_host.dart: moved from the old tool, same gcc flags and library sources.
List<String> runSwissHostTool(Uri packageRoot, String cFileName, List<String> arguments); // stdout lines; non-zero exit throws
// horizons.dart
typedef Declaration = ({String body, String utc});
const List<Declaration> retrogradeDeclarations; // design 5.1 primaries, 9 pairs
const Map<String, String> retrogradeBackups;     // body -> backup utc, 8 entries
/// The Julian day string sent as TT for [utc] (design section 6).
String ttJulianDay(DateTime utc, {double? historicalDeltaTSeconds});
```

`retrogradeDeclarations`: mercury 1953-11-18 and 2049-05-11; venus 2012-06-12; mars 1956-09-10; jupiter 2023-10-15; saturn 2023-08-01; uranus 2023-10-15; neptune 2023-08-01; pluto 2023-08-01 (all `T00:00:00Z`). Backups: mercury 2016-05-13; venus 2004-06-14; mars 2003-08-28; jupiter and uranus 2024-10-20; saturn, neptune and pluto 2024-08-01.

- [ ] **Step 1: Failing tests:** `ttJulianDay from 1972 uses leap seconds` (`2012-06-12T00:00:00Z` → `julianDayUt + 66.184/86400` (TAI − UTC was 34 s until 2012-07-01), nine decimals; `2023-08-01` → +69.184); `before 1972 it adds the given delta T` (`1953-11-18`, 30.0 → +30/86400); `before 1972 without delta T throws ArgumentError`; `declarations cover mercury to pluto and never sun or moon`; `every declared body has a backup`.
- [ ] **Step 2:** Run. Expected: compile failure.
- [ ] **Step 3:** Implement, and the mode `confirm-retrograde --out <dir>`: for each body Mercury to Pluto, one TT request holding JD(t) − 3, JD(t), JD(t) + 3 for each of its primary and backup instants (ascending), where JD(t) = `ttJulianDay`; delta T from `runSwissHostTool(…, 'tt_grid.c', …)`. Print one line per pair: body, instant, three longitudes, both signed steps, `PASS` or `FAIL`. Exit 1 if any body has a declared instant failing and its backup failing.
- [ ] **Step 4:** Run tests (pass), then the mode (8 requests). Expected: exit 0.
- [ ] **Step 5: Apply the rule** of design 5.1. If a declared pair failed and the backup passed, edit `retrogradeDeclarations`, update the design's coverage table and the counts in Task 6, and report it. Record all results in the design.
- [ ] **Step 6:** Commit `feat(ZOD-TST-001): confirm the retrograde instants with Horizons`.

### Task 5: Dataset mode and device-copy generator

**Files:** Modify `tool/fetch_horizons_reference.dart`, `tool/horizons/horizons.dart`; Create `tool/gen_horizons_copy.dart`; Modify the tool test.

**Interfaces (produces):**

```dart
// horizons.dart
double timeScaleDisagreementArcseconds(double longitudeAtUt, double longitudeAtTt);
String horizonsCopySource(Map<String, Object?> dataset); // the whole Dart file
```

Dataset JSON keys: `version` (1), `referenceDatesVersion`, `source`, `retrievedOn`, `apiVersion`, `targetSources` (body → line), `quantity`, `timeScale`, `queryParameters`, `toleranceArcseconds` (1), `entries` {`body`,`utc`,`jdTt`,`ttMinusUtSeconds`,`longitudeDegrees`}, `utcCrossCheck` {`body`,`utc`,`longitudeDegrees`} (instants ≥ 1972-01-01), `timeScaleControl` {`utc`,`jdUt`,`tdbMinusUtSeconds`,`jdTtDerived`,`longitudeAtUt`,`longitudeAtTt`} (Moon, instants < 1972), `retrogradeEvidence` {`body`,`utc`,`longitudeBefore`,`longitudeAfter`} (3 days).

Generated copy declares: `horizonsDatasetVersion`, `horizonsToleranceArcseconds`, `typedef HorizonsReference = ({String body, String utc, String jdTt, double ttMinusUtSeconds, double longitudeDegrees})`, `typedef HorizonsUtReference = ({String body, String utc, double longitudeDegrees})`, `const horizonsReference`, `const horizonsUtCrossCheck`, with a generated-file header.

`dataset --baseline <json> --out <dir>` (requests of design 8.1) fails closed, writing nothing, when: a parser check fails; `changedRows(baseline, entries)` is non-empty; any UT cross-check row differs from its TT row by more than 0.002″; any time-scale control row differs by more than 0.002″ (the control asks UT with `30,31`, sets `jdTtDerived = jdUt + tdbMinusUtSeconds/86400` to nine decimals, and asks TT there); no control row has |TDB − UT| > 10 s; a declared pair is not retrograde.

- [ ] **Step 1: Failing tests:** `time scale disagreement` (`(10, 10 + 0.003/3600)` ≈ 0.003; wraps at 360); `the copy holds every entry and cross-check row` (two-row synthetic dataset: output contains both typedefs, `const int horizonsDatasetVersion = 1;`, each row's body, utc, `jdTt` string and longitude, and no `timeScaleControl`).
- [ ] **Step 2:** Run: compile failure. **Step 3:** Implement both functions, the `dataset` mode and the generator (`gen_horizons_copy.dart` reads `../astro_core/test/fixtures/horizons_reference.json`, writes `../../apps/astro_mobile/integration_test/horizons_reference.dart`). **Do not run `dataset` yet.**
- [ ] **Step 4:** Run tool tests (pass) and `fvm dart analyze --fatal-infos packages/ephemeris_swiss` (no issues). **Step 5:** Commit `feat(ZOD-TST-001): build the dataset and its device copy`.

### Task 6: Date set version 2, the dataset and every consumer (one commit)

One commit, because the date set, the data and its consumers each fail without the others.

**Files:**
* Modify: `packages/astro_core/test/fixtures/reference_dates.json`, `test/accuracy/reference_dates_test.dart`
* Create: `packages/astro_core/test/fixtures/horizons_reference.json`, `test/accuracy/horizons_reference_test.dart`
* Create: `packages/ephemeris_swiss/test/horizons_reference_time_test.dart`
* Create: `apps/astro_mobile/integration_test/horizons_reference.dart` (generated), `test/horizons_reference_match_test.dart`
* Modify: `apps/astro_mobile/integration_test/swiss_ephemeris_accuracy_test.dart`, `packages/ephemeris_swiss/tool/tt_grid.c` (comment names the new tool)
* Delete: `packages/ephemeris_swiss/test/fixtures/reference_longitudes_tt.json`, `test/reference_tt_fixture_test.dart`, `tool/fetch_horizons_tt_reference.dart`, `apps/astro_mobile/integration_test/swiss_reference_longitudes_tt.dart`, `test/swiss_reference_longitudes_tt_match_test.dart`
* Backup (option A, design section 10): `packages/ephemeris_astronomy/test/reference_fixture_test.dart`, `reference_tt_fixture_test.dart`, both `test/fixtures/*.json`, both `tool/fetch_horizons*_reference.dart`, both generated `apps/astro_mobile/integration_test/astronomy_reference_longitudes*.dart`, `astronomy_accuracy_test.dart`, `astronomy_speed_vs_swiss_test.dart`

The 11 version-2 instants (all `Z`): `1953-11-18T00:00:00`, `1956-09-10T00:00:00`, `1971-12-31T23:59:59`, `1972-01-01T00:00:00`, `2012-06-12T00:00:00`, `2023-08-01T00:00:00`, `2023-10-15T00:00:00`, `2049-05-11T00:00:00`, `2100-07-01T00:00:00`, `2100-12-31T00:00:00`, `2100-12-31T23:59:59`.

- [ ] **Step 1: Failing tests, date set.** In `reference_dates_test.dart`: add `_v2Instants` (the 11) and `version 2 holds every version-2 instant` (`version == 2`, `_v1Instants.length + _v2Instants.length == dates.length == 64`, all contained). Rename the window test to `stays between T = −1 and the end of the supported range` with end `SupportedDateRange.end`.
- [ ] **Step 2: Failing tests, dataset** (`horizons_reference_test.dart`):
  * `provenance`: `version == 1`; `referenceDatesVersion` equals the date file's `version`; `source` contains `Horizons`; `retrievedOn`, `apiVersion` non-empty; `targetSources` has the ten bodies; `queryParameters` `CENTER` `500@399`, `EPHEM_TYPE` `OBSERVER`, `QUANTITIES` `31`, `TIME_TYPE` `TT`, `TLIST_TYPE` `JD`, `APPARENT` `AIRLESS`; tolerance 1.
  * `every body at every shared instant, once` (640 keys equal dates × bodies); longitudes in [0, 360); `jdTt` matches `^\d+\.\d{9}$`.
  * `at least 50 instants from 1900 to 2100` (63); `includes 2100-12-31T23:59:59Z and 1999-12-31T23:59:59Z`.
  * `a retrograde instant for each body from mercury to pluto, none for sun or moon`: the (body, utc) set equals the nine declared pairs written as literals; every utc is a shared instant; for each, the shortest signed steps before→at and at→after are both negative.
  * `the UT cross-check holds every body from 1972, and nothing earlier` (420).
  * `Horizons TIME_TYPE=TT is the same scale as its UT`: 22 control rows equal to the shared instants before 1972; `|atTt − atUt| ≤ 0.002″`; `jdTtDerived` within 2e-9 of `jdUt + tdbMinusUtSeconds/86400`; some `|tdbMinusUtSeconds| > 10`.
- [ ] **Step 3: Failing tests, consumers.** `horizons_reference_time_test.dart` repoints the old test's three conversion tests to the shared dataset, asserting exactly 420, 220 and 420 checked rows (the third compares `entries` with `utcCrossCheck`, 0.002″, with `DateTime.utc(1972)` as a literal). `horizons_reference_match_test.dart` requires the copy's version, tolerance, both lengths and every field of every row to equal the JSON.
- [ ] **Step 4:** Run `reference_dates_test.dart` and `horizons_reference_test.dart` in `packages/astro_core`. Expected: FAIL (`version` is 1; dataset file missing).
- [ ] **Step 5:** Edit `reference_dates.json`: `version` 2, the 11 instants in chronological order, description extended with `Version 2 (ZOD-TST-001): retrograde instants, the 1972 boundary and 2100 through 31 December.`
- [ ] **Step 6:** Download, from `packages/ephemeris_swiss` (also for Step 7): `fvm dart run tool/fetch_horizons_reference.dart dataset --baseline test/fixtures/reference_longitudes_tt.json --out <scratch dir>` (30 requests). Expected: exit 0, `640 entries`, 530 baseline rows unchanged. A refusal: stop and report.
- [ ] **Step 7:** `fvm dart run tool/gen_horizons_copy.dart`; `fvm dart format ../../apps/astro_mobile/integration_test/horizons_reference.dart`.
- [ ] **Step 8: Repoint the device test** to `horizons_reference.dart` only (remove both old imports; `gate` takes the expected row count):

  | Test name | Compares | Rows |
  |---|---|---|
  | `T-EPH-1 / ACC-1: the adapter at each instant within 1 arcsecond of Horizons at the matching TT` | `port.position(body, utc)` with `horizonsReference` | 640 |
  | `matched TT: all ten bodies within 1 arcsecond` | `calcTt(jdTt)` | 640 |
  | `conversion cross-check from 1972: UTC input against Horizons asked at UTC` | adapter with `horizonsUtCrossCheck`; also asserts no row before 1972 | 420 |
  | `the dataset TT is the TT the adapter uses` | Moon, ≤ 0.0005″ | 64 |

  The header comment says that this is T-EPH-1 and ACC-1, that the tests are mandatory (ACC-5), and why no pre-1972 UT value is gated. Other tests in the file are unchanged.
- [ ] **Step 9:** Delete the five old files. Run `git grep -nE "swiss_reference_longitudes_tt|fetch_horizons_tt_reference|reference_tt_fixture_test" -- apps packages test tool`. Expected: only `packages/ephemeris_astronomy` and `astronomy_*` hits (the backup's own files of those names).
- [ ] **Step 10: Backup tests (option A).** In both fixture tests, require rows for every shared instant in [1899-12-31T12:00Z, 2100-01-01T12:00Z], and add `only instants after the covered range are left out`: the excluded set equals `{2100-07-01T00:00:00Z, 2100-12-31T00:00:00Z, 2100-12-31T23:59:59Z}`, and the included set contains `1899-12-31T12:00:00Z` and `2100-01-01T12:00:00Z`. Existing boundary tests stay. Run them. Expected: FAIL naming the eight new in-range instants.
- [ ] **Step 11:** In both backup tools, filter the instants to that same range before building `dateStrings` and the time list (queries otherwise unchanged); update "53" comments. Run both from `packages/ephemeris_astronomy` (20 requests). Expected: `wrote 610 entries` each.
- [ ] **Step 12: Old backup rows unchanged.** A scratch script outside the repository loads each fixture from `git show HEAD:<path>` and from the working tree and requires every old (body, utc) row to be present with identical `longitudeDegrees` (and `utDays`, `ttDays`, `deltaTSeconds`, `jdTt` for the TT fixture). Expected: 530 identical, 0 differences, each. Any difference: stop and report. Format the two generated copies.
- [ ] **Step 13:** `astronomy_accuracy_test.dart`: `hasLength(53)` → `hasLength(61)`, "53 instants" → "61 instants"; tolerance unchanged. `astronomy_speed_vs_swiss_test.dart`: a const set `_addedInDateSetVersion2` (the eight in-range instants), excluded from `referenceInstants`, then `expect(referenceInstants, hasLength(53))`; bounds unchanged.
- [ ] **Step 14:** `fvm dart run melos run lint`; `fvm dart run melos run test`. Expected: exit 0. `git diff --stat main -- ":(glob)**/lib/**"` prints nothing.
- [ ] **Step 15:** Commit `test(ZOD-TST-001): add the shared Horizons dataset and move its consumers to it`.

**If the owner chooses option B instead:** Step 10 makes both tests require the 53 version-1 instants (listed literally) and keeps the same boundary assertions; Steps 11 to 13 are skipped; no backup fixture, tool or device test changes.

### Task 7: Mean node against Swiss Ephemeris

**Files:** Create `packages/ephemeris_swiss/tool/node_grid.c`, `tool/gen_swiss_mean_node.dart`, `packages/astro_core/test/fixtures/swiss_mean_node.json`, `test/accuracy/mean_node_vs_swiss_test.dart`, `apps/astro_mobile/integration_test/swiss_mean_node_test.dart`.

**Interfaces:** `node_grid <data dir> <jd tt>…` prints per Julian day: mean-node longitude and returned flags for `SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_NONUT`, the J2000 variant's longitude (`… | SEFLG_J2000`), and the true node's (`SE_TRUE_NODE`, default flags); exits non-zero on any error or warning. The generator takes the instants and `jdTt` from `horizons_reference.json` and writes `version` 1, `referenceDatesVersion`, `source` (library version, host build), `requestedFlags` 322, `entries` {`utc`,`jdTt`,`meanNodeDegrees`,`returnedFlags`,`j2000Degrees`,`trueNodeDegrees`}.

- [ ] **Step 1: Failing host test** (imports only `astro_core` and `package:test`): `covers every shared instant once` (64); `the reference is the mean node on the mean equinox of date` (every `returnedFlags`: `& 64 != 0`, `& 32 == 0`, `& 65536 == 0`); `the formula is within 0.01 degrees of Swiss at every shared instant` (`meanAscendingNodeAt(utc).longitude`, shortest angle ≤ 0.01); `controls: J2000 and the true node differ by more than 0.01 degrees` (maximum over the set > 0.01 for each).
- [ ] **Step 2:** Run. Expected: FAIL, fixture missing.
- [ ] **Step 3:** Implement the C tool and generator; run it. **Step 4:** Run the test (pass) and note the printed maximum (planning measured at most 0.00216° over a daily sweep).
- [ ] **Step 5: Device test:** with `SwissEphemerisBinding` and the packaged data: at the 64 instants (`jdTt` from `horizonsReference`) and monthly from 1900-01-01 to 2100-12-01 (2,412 instants, TT by the production rule: `calcUt` before 1972, else `calcTt(julianDayUt(utc + ttMinusUtc))`), `port.position(Body.node, utc)` is within 0.01° of body 10 with flags `seflgSwieph | seflgSpeed | 64`; every returned flag word has 64 set and 32 clear; J2000 (`| 32`) and body 11 exceed 0.01° somewhere. Print the maxima. Constants for 10, 11, 32 and 64 are declared in the test.
- [ ] **Step 6:** Lint and tests exit 0. Commit `test(ZOD-TST-001): validate the mean node against Swiss Ephemeris`.

### Task 8: Device verification and mutation proofs

Emulator `Pixel_9_Pro_API_36` (x86_64; start with `-memory 3072`, saved configuration unchanged). From `apps/astro_mobile`, one file at a time: `fvm flutter test integration_test/<file> -d emulator-5554`.

- [ ] **Step 1:** `swiss_ephemeris_accuracy_test.dart`, `swiss_mean_node_test.dart`; under option A also `astronomy_accuracy_test.dart`, `astronomy_speed_vs_swiss_test.dart`. Expected: all pass. Record every per-body maximum, in particular at the 2100 instants and the retrograde instants. A result over its bound: stop and report.
- [ ] **Step 2: Mutation proofs** (temporary, each observed failing, then restored with `git status` clean): one copied longitude +2″ → the T-EPH-1 / ACC-1 gate fails; one Moon `jdTt` +1 s in the copy → the TT pin fails; `meanNodeEpochLongitude` +0.02 → the host node test fails; the device node test's flags without 64 → its flag assertion fails.
- [ ] **Step 3:** Record device, head commit, counts and maxima in the design (a results section). A dropped or disconnected run is void and repeated.

### Task 9: Review, documentation, completion

- [ ] **Step 1:** `superpowers:requesting-code-review`: one fresh reviewer over the whole branch. Fix important findings test-first.
- [ ] **Step 2:** `superpowers:verification-before-completion`: lint, full tests, `git diff --stat main -- ":(glob)**/lib/**"` empty, `git status --short`; rerun device files touched by review fixes.
- [ ] **Step 3:** Documentation: task file (criteria ticked with evidence, status, Notes with hand-offs; criteria wording unchanged); `TASKS.md` status; `docs/PROGRESS.md` (completed task, verification with head commit, blockers: backup item still open for ZOD-TST-005, decisions); one line in `docs/decisions/ZOD-EPH-002-time-scale.md` section 9 pointing from the removed test path to `horizons_reference_time_test.dart`. Hand-offs recorded: ZOD-TST-004 (build on the repointed gate), ZOD-TST-005 (shared TT is the primary's; the backup's two fixtures and speed-test exclusion; time-model discrepancy), ZOD-EPH-006.
- [ ] **Step 4:** Commit `docs(ZOD-TST-001): record verification and completion`. **Stop: push and PR need the owner's approval.**

## Plan review

Pending.
