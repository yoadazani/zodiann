# ZOD-TST-001: JPL Horizons Reference Dataset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, **sequentially in one session** (the tasks share files and interfaces). Steps use checkbox (`- [ ]`) syntax for tracking. **Approval is by stage (see Global Constraints): stop after Task 4A.**

**Goal:** One versioned Horizons reference dataset, compared at matching TT instants, that T-EPH-1 and ACC-1 consume, plus a separate mean-node validation against Swiss Ephemeris.

**Architecture:** The shared instants stay in `astro_core/test/fixtures` (version 2). A host tool in `ephemeris_swiss/tool` asks Horizons in TT at the TT the app assigns, checks every answer, and writes the dataset beside them; a generated const copy feeds the device test. The node reference comes from the vendored Swiss source compiled on the host.

**Tech Stack:** Dart 3.14.0 / Flutter 3.50.0 (FVM), `package:test`, `integration_test`, gcc (host C tools), JPL Horizons API.

**Spec:** [`docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md`](../superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md) ("the design"). Task file: [`ZOD-TST-001`](../development/testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md).

**Branch:** `task/ZOD-TST-001-jpl-horizons-reference-dataset` (from `main` @ `c7df9c6`).

## Global Constraints

* **Stages (owner, 2026-11-26):** the 11-request pilot is done, accepted, and **not repeated**. **Tasks 0 to 3 are done and accepted. Task 4A (offline code only) is approved**: it sends no network request, downloads nothing, runs no emulator and touches no dataset or backup data; after it, stop and report. Task 4B (the 8 retrograde requests), Tasks 5 to 9, and every Horizons request, download and emulator run wait for a further explicit approval. No push, PR or merge. Existing scratch data and local work notes are not deleted.
* The pilot's observations do not replace the time-scale control at the 22 pre-1972 instants (design section 6 link 4; Tasks 5 and 6).
* **No file under any `lib/` changes.** No `EphemerisPort`, adapter, backup implementation, backup range, formula or specification change. `native/*/upstream/` stays byte-identical.
* Tolerances, never loosened, no body or instant dropped to pass: **1″** for each of the ten bodies against Horizons; node **0.01°**; Horizons TT-against-UT agreement **0.002″**; device TT pin **0.0005″**; echoed time **1 ms**; row protection **0.001″**. A failing gate means stop and report.
* Every primary comparison is at the same TT (design section 6). Before 1972 nothing of ours is compared with a UT-asked Horizons value (the time-scale control compares Horizons only with itself).
* Horizons requests only with the parameters and dates of design sections 5 and 8 (control times included; the pilot requests are done and are not sent again), sequential, at least 1 s apart. A new date or parameter needs the owner. Requests carry dates and body numbers only. Raw responses go to a scratch directory outside the repository; the only exception is the two pilot answers committed as parser samples (Task 2).
* `reference_dates.json` is add-only: `version` 1 → 2, no instant dropped or changed.
* Commands run in PowerShell with `fvm …` (a bare `melos` or global `dart` fails), from the repository root unless a step names a directory; write those as `Push-Location <dir>; fvm …; Pop-Location`. Before every commit that touches Dart: `fvm dart format <touched files>` and `fvm dart analyze --fatal-infos <touched packages>` are clean. Do not run a root `fvm flutter pub get` without restoring `packages/shared_ui/lib/l10n` with `git checkout -- packages/shared_ui/lib/l10n`.
* Commits: `<type>(ZOD-TST-001): <summary>` with the session's attribution trailers; explicit staging only; never stage `grep.exe.stackdump`. No push, PR or merge without the owner's approval.

## Review Focus

1. Horizons reads the time list as UT although TT was meant: the parser's scale check (Task 3) and the time-scale control (Tasks 5 and 6) must fail.
2. Rows reordered, dropped or shifted in an answer: every echoed time is compared with the requested one, in order (Task 3).
3. A refetch silently changes or loses a reference row: `changedRows` reports both (Task 1) and the tool writes nothing.
4. Longitudes across 0°/360° in differences and retrograde checks (Task 1).
5. A date added to the shared set without refetching: version and instant-set tests fail (Task 6).
6. The UT cross-check asked in TT by mistake would pass every numeric gate: the recorded query and Julian days are asserted (Tasks 5, 6).

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
| `packages/ephemeris_swiss/tool/fetch_horizons_reference.dart` | the only network code: modes `confirm-retrograde`, `dataset` (created in Task 4) |
| `packages/ephemeris_swiss/tool/gen_horizons_copy.dart` | offline: dataset JSON → device const copy |
| `packages/ephemeris_swiss/tool/node_grid.c`, `gen_swiss_mean_node.dart` | node reference fixture |
| `packages/astro_core/test/fixtures/{reference_dates,horizons_reference,swiss_mean_node}.json` | shared data |
| `apps/astro_mobile/integration_test/horizons_reference.dart` | generated device copy |

---

### Task 0: Baseline

- [x] **Step 1:** Run `fvm dart run melos run lint`, then `fvm dart run melos run test`. Expected: both exit 0. Record counts. If either fails, stop and report.

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

- [x] **Step 1: Write the failing tests**

  * `the query is exactly the approved parameters`: `horizonsQuery(command: '301', julianDays: ['2451545.000000000', '2451546.000000000'], timeType: HorizonsTimeType.tt)` equals the map of design section 8 value for value (`TLIST` = `"'2451545.000000000 2451546.000000000'"`, `TIME_DIGITS` `"'FRACSEC'"`, `CAL_FORMAT` `"'BOTH'"`, `APPARENT` `"'AIRLESS'"`, `format` `'text'`); `ut` gives `TIME_TYPE` `"'UT'"`; `quantities: '30,31'` gives `"'30,31'"`.
  * `the query reproduces the two pilot requests`: for the two requests behind the samples (design 8.5), `Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', horizonsQuery(…)).toString()` equals the URL recorded there, written as a literal in the test.
  * `julian days must be ascending with nine decimals`: `ArgumentError` for `['2.000000000', '1.000000000']`, for `['2451545.0']` and for an empty list.
  * `signedDegrees wraps`: `(359.9, 0.1)` ≈ 0.2; `(0.1, 359.9)` ≈ −0.2; `(10, 190)` = −180.
  * `isRetrograde`: `(0.2, 0.0, 359.8)` true; `(359.8, 0.0, 0.2)` false; `(10, 9, 9.5)` false; `(10, 10, 9)` false.
  * `changedRows`: equal rows → empty; a difference of 0.0009″ → empty; 0.0011″ → one line naming body and utc; a baseline row missing from `next` → one line containing `missing`; an extra row in `next` → empty; `359.9999999` against `0.0000001` (0.00072″ apart across 0°) → empty at the default tolerance, one line at `toleranceArcseconds: 0.0001`.

- [x] **Step 2:** `Push-Location packages/ephemeris_swiss; fvm dart test test/horizons_tool_test.dart; Pop-Location`. Expected: compile failure, `horizons.dart` not found.
- [x] **Step 3:** Implement. `horizonsCommands` as in the existing tools.
- [x] **Step 4:** Rerun the Step 2 command (also the "tool tests" command of Tasks 3 to 5). Expected: all pass.
- [x] **Step 5:** Commit `feat(ZOD-TST-001): add the Horizons query and reference checks`.

### Task 2: Pilot answers as parser samples (done)

The 11 pilot requests (design section 8) were sent on 2026-11-26 by a throwaway script outside the repository. The owner accepted those answers as the completed pilot: **they are not repeated, and the repository tool has no pilot mode.** The raw answers stay in the scratch directory; their SHA-256 and the verified format are in design sections 8.1 to 8.5.

**Files:** Create `packages/ephemeris_swiss/test/fixtures/horizons_sample_tt.txt`, `horizons_sample_ut.txt`; Modify `.gitattributes`.

**Interfaces (produces):** the TT sample is pilot request 1 (Moon, TT, quantity 31, four rows); the UT sample is request 2 (Moon, UT, quantities 30 and 31, four rows).

- [x] **Step 1:** All 11 raw answers match the SHA-256 of design 8.5.
- [x] **Step 2:** Every pilot stop condition passed (design 8.4), including data for all ten bodies at the last instant and the 1972 boundary.
- [x] **Step 3:** Answers 1 and 2 copied unchanged to the sample files, with `packages/ephemeris_swiss/test/fixtures/horizons_sample_*.txt -text` in `.gitattributes`; commit `a0210c9`; the committed blobs match the two hashes.
- [x] **Step 4:** Format, headers, column-name requirements and precision recorded in design section 8.

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

`apiVersion` is the number after `API VERSION:` (any value); `targetLine` is the whole `Target body name:` line, trimmed.

Checks against the format of design 8.1 to 8.3, **in this order**. Each throws `FormatException` whose message **starts with the quoted word followed by a colon** (`time: …`, `time scale: …`), so a test can tell which check refused:

1. `markers`: one `$$SOE` line, then one `$$EOE` line.
2. `API version`: the line is present.
3. `time scale`: the `Start time` and `Stop  time` lines, trailing whitespace removed (`trimRight`), both end in ` TT` or ` UT` equal to `timeType`.
4. `target`: the target line contains `(<command>)`.
5. `centre`: the `Center body name:` line contains `Earth (399)`, and the text after `Center-site name:`, trimmed, equals `GEOCENTRIC`.
6. `column`: the header is the last line before `$$SOE` containing `Date__(`; split at commas and trimmed; it holds, **by name** (never by index), the two date columns of the requested scale, `ObsEcLon`, and `TDB-UT` when `expectTdbMinusUt`.
7. `rows`: as many rows as requested.
8. For each row, in order: `fields` (as many as the header); `number` (the Julian day, longitude and, when expected, quantity 30 match `^-?\d+\.\d+$`; the calendar time matches `yyyy-Mon-dd HH:mm:ss.fff`); `time` (**both** the printed Julian day and the calendar time are within 1 ms of the requested Julian day; instants are derived from Julian day strings in integer microseconds, whole and fraction parsed separately); `precision` (longitude at least 7 decimals, quantity 30 at least 3); `longitude` (in [0, 360)).

`tdbMinusUtSeconds` is null unless expected.

- [x] **Step 1: Write the failing tests** against the samples.
  * `parses the TT sample`: four rows; `julianDay` equals the four requested strings; longitudes `265.2972999`, `101.6302965`, `223.3148557`, `293.9451964`; every `tdbMinusUtSeconds` null; `apiVersion` `'1.2'`; `targetLine` contains `Moon (301)` and `DE441`.
  * `parses the UT sample with TDB-UT`: longitudes `265.2969812`, `101.6302965`, `223.3237860`, `293.9567420`; `tdbMinusUtSeconds` `-1.946024`, `42.183919`, `64.183903`, `69.183904`.
  * `a CRLF variant parses to the same rows` (the samples are LF).
  * `the UT sample read without TDB-UT gives the same longitudes` (`expectTdbMinusUt: false`; every `tdbMinusUtSeconds` null).
  * `a requested time about 0.5 ms (0.518 ms) from the echo passes and the row carries the requested string` (TT sample, first requested day `'2415020.000000006'`; `rows.first.julianDay` equals it).
  * One test per refusal, each editing the sample text in memory (assert the edit changed the text) or, where only arguments are named, changing the arguments. Row edits target the row text, for example `1899-Dec-31 12:00:00.000,`, because the header lines contain the same times. Each expects a `FormatException` whose message starts with the check's word and a colon (`startsWith('<word>:')`): `a TT answer is refused for a UT request` and the reverse, `a stop time naming another scale` (`00:01:08.1840 TT` to `UT`) and `a start time naming another scale` (`12:00:00.0000 TT` to `UT`) (`time scale`); `a column header naming another scale`, `no ObsEcLon column`, `quantity 30 expected but absent` (`column`); `a missing row`, `an extra row` (`rows`); `a row missing a field` (`fields`); `two rows swapped`, `an echoed Julian day 2 ms off`, `an echoed calendar time 2 ms off` (`time`); `a value that is not a number` (`n.a.`, `number`); `longitude printed to six decimals`, `quantity 30 printed to two decimals` (`precision`); `longitude 360` (`360.0000000`), `a negative longitude` (`-0.0000001`) (`longitude`); `no $$SOE`, `no $$EOE` (`markers`); `no API version line` (`API version`); `another target` (`command: '10'`, `target`); `a non-geocentric centre body` and `a non-geocentric site` (`centre`).
- [x] **Step 2:** Run. Expected: compile failure, `parseHorizonsAnswer` undefined.
- [x] **Step 3:** Implement from the recorded format.
- [x] **Step 4:** Run. Expected: all pass.
- [x] **Step 5:** Commit `feat(ZOD-TST-001): parse Horizons answers and refuse mismatches`. **Stop here: report, and wait for the owner's approval of Task 4.**

### Task 4: Confirm the retrograde dates with Horizons

**Split by owner decision (2026-11-26): 4A is offline code (Steps 1 to 3C), then a stop; 4B (Steps 4 to 6) sends the 8 requests and waits for a separate explicit approval.**

**Files:** Create `tool/horizons/swiss_host.dart`, `tool/fetch_horizons_reference.dart`, `test/horizons_fetch_test.dart`; Modify `tool/horizons/horizons.dart`, `test/horizons_tool_test.dart`. The old tool and `tt_grid.c` are not touched (Task 6).

**Interfaces:**

```dart
// horizons.dart (still pure: no network, no file access)
typedef Declaration = ({String body, String utc});
const List<Declaration> retrogradeDeclarations; // design 5.1 primaries, 9 pairs
const Map<String, String> retrogradeBackups;     // body -> backup utc, 8 entries
/// The Julian day string sent as TT for [utc] (design section 6). The 1972
/// boundary is ephemerisTimeFor's. Exactly the old tool's arithmetic:
/// from 1972 julianDayUt(utc.add(ttMinusUtc)), before it julianDayUt(utc) +
/// deltaT / 86400; nine decimals. ArgumentError before 1972 without a finite
/// delta T.
String ttJulianDay(DateTime utc, {double? historicalDeltaTSeconds});
/// Whole days only, on the string: the fraction digits are unchanged.
String shiftJulianDay(String julianDay, int days);
/// One instant under test with its three Julian days: t - 3, t, t + 3.
typedef RetrogradeCandidate = ({String body, String utc, bool isBackup, List<String> julianDays});
/// The candidate instants before the leap-second table, ascending.
List<String> retrogradeHistoricalInstants();
/// One list per request, Mercury to Pluto; within a request ascending by instant.
/// [historicalDeltaTSeconds] is keyed by those instants; ArgumentError if one is missing.
List<List<RetrogradeCandidate>> retrogradeRequests(Map<String, double> historicalDeltaTSeconds);
typedef RetrogradeResult = ({String body, String utc, bool isBackup, double before, double at, double after});
/// Three rows per candidate, in request order; ArgumentError if the counts differ.
List<RetrogradeResult> retrogradeResults(List<RetrogradeCandidate> candidates, List<HorizonsRow> rows);
/// body, instant, primary or backup, the three longitudes, both signed steps, PASS or FAIL.
String retrogradeResultLine(RetrogradeResult result);
/// Bodies with more failing declared instants than passing backups.
List<String> retrogradeUnresolved(Iterable<RetrogradeResult> results);

// swiss_host.dart: the old tool's gcc flags and library sources, unchanged.
typedef ProcessRunner = ProcessResult Function(String executable, List<String> arguments);
/// Compiles tool/[cFileName] against the vendored source and runs it; the
/// non-empty stdout lines. StateError if compiling or running exits non-zero.
List<String> runSwissHostTool(Uri packageRoot, String cFileName, List<String> arguments, {ProcessRunner run = Process.runSync});
/// tt_grid.c with the packaged data directory (assets/ephe) as first argument
/// and julianDayUt of each instant; StateError unless one line per instant.
List<double> libraryDeltaTSeconds(Uri packageRoot, List<DateTime> instants, {ProcessRunner run = Process.runSync});

// fetch_horizons_reference.dart, the only network code of the new tool.
typedef HorizonsResponse = ({int statusCode, List<int> bytes});
/// The exit code. Only main connects a real HTTP GET, gcc and a real delay.
Future<int> runHorizonsTool(List<String> arguments, {
    required Uri packageRoot,
    required Future<HorizonsResponse> Function(Uri uri) get,
    required List<double> Function(List<DateTime> instants) deltaT,
    required Future<void> Function(Duration duration) pause,
    required StringSink out, required StringSink err});
```

**Tool behaviour**, run from the package root as `fvm dart run tool/fetch_horizons_reference.dart confirm-retrograde --out <dir>`:

* Exactly those three arguments; otherwise, or if `<dir>` is inside the repository, or exists and is not empty, print usage with the reason to `err` and return 64, **before** any delta T computation or request. A `<dir>` that does not exist is created.
* The delta T and all 8 queries (`horizonsQuery`, TT, quantity 31) are built before the first request.
* One request at a time, a pause of 1 s between requests. URI: `Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', query)`.
* Each answer's bytes are saved unchanged in `<dir>` **before** anything reads them: `NN_<command>_TT.txt` (`NN` = 01 to 08), or for a non-200 status `NN_<command>_TT.http<status>.txt`, followed by an `HttpException`. A parser refusal propagates. Either way no further request is sent.
* Prints one `retrogradeResultLine` per candidate. After the 8th answer: return 1, naming the bodies, if `retrogradeUnresolved` is not empty; else 0.

`retrogradeDeclarations`: mercury 1953-11-18 and 2049-05-11; venus 2012-06-12; mars 1956-09-10; jupiter 2023-10-15; saturn 2023-08-01; uranus 2023-10-15; neptune 2023-08-01; pluto 2023-08-01 (all `T00:00:00Z`). Backups: mercury 2016-05-13; venus 2004-06-14; mars 2003-08-28; jupiter and uranus 2024-10-20; saturn, neptune and pluto 2024-08-01.

**No test or step of 4A opens a connection, and no test compiles or runs a C tool** (CI runs this package's tests; the host helper is tested through its `ProcessRunner`). Never run the command-line tool with valid arguments in 4A. Fetch-tool tests run inside `HttpOverrides.runZoned` with a client factory that throws.

- [ ] **Step 1: Failing tests, pure functions** (`horizons_tool_test.dart`):
  * `ttJulianDay from 1972 uses leap seconds` (`2012-06-12T00:00:00Z` → `julianDayUt + 66.184/86400` (TAI − UTC was 34 s until 2012-07-01), nine decimals; `2023-08-01` → +69.184); `before 1972 it adds the given delta T` (`1953-11-18`, 30.0 → +30/86400); `before 1972 without a finite delta T throws ArgumentError` (null, NaN); `1971-12-31T23:59:59Z uses the given delta T`; `1972-01-01T00:00:00Z is +42.184 s even when a delta T is given` (equals `'2441317.500488241'`, the pilot's string); `2100-12-31T23:59:59Z is the pilot's last instant` (`'2488434.500789167'`).
  * `shiftJulianDay moves whole days and keeps the fraction` (`('2441317.500488241', -3)` → `'2441314.500488241'`; `+3` → `'2441320.500488241'`).
  * `declarations cover mercury to pluto and never sun or moon` and `every declared body has a backup`, both against the design 5.1 pairs written as literals; `the historical instants are 1953-11-18 and 1956-09-10`.
  * `eight requests, mercury to pluto, 51 times` (Mercury 9, each other body 6; strictly ascending; TT Julian days of the instants from 1972 written as literals; each candidate's three days are t−3, t, t+3; a missing delta T throws).
  * `results pair three rows with each candidate`; a row count that differs throws; `the line shows both steps and the verdict`.
  * `unresolved`: all pass → none; a primary failing with its backup passing → none; primary and backup failing → that body; both Mercury primaries failing with the backup passing → `mercury`; only a backup failing → none.
- [ ] **Step 2:** Run. Expected: compile failure.
- [ ] **Step 3:** Implement them; run (pass). Commit `feat(ZOD-TST-001): add the retrograde candidates and their checks`.
- [ ] **Step 3A: Failing tests, host helper and tool** (`horizons_fetch_test.dart`):
  * host helper, with a recording `ProcessRunner`: the gcc arguments are the old tool's (`-O1 -std=gnu99 -I <upstream> -o <exe> <tool/tt_grid.c> <the nine library sources> -lm`); a non-zero compile or run exit throws `StateError`; `libraryDeltaTSeconds` passes `assets/ephe` first, then one Julian day per instant, parses the lines, and throws if the count differs.
  * usage, with a `get` and `deltaT` that fail the test if called: no arguments; `dataset`, `pilot` or an unknown mode; `--out` missing or without a value; an extra argument; `--out` inside the repository; a non-empty `--out` → 64.
  * a recording fake `get` answering from a text built on the TT sample (target `(<command>)`, rows echoing the requested days, chosen longitudes): exactly the 8 expected URLs in order, written as literals; 7 pauses of 1 s, each between two requests; 8 raw files with the answer bytes; exit 0 when every pair is retrograde, 1 naming the body when unresolved.
  * a refused answer: the raw file is on disk, the error propagates, one request only; a non-200 answer: saved as `.http503.txt`, `HttpException`, one request only.
- [ ] **Step 3B:** Run (compile failure), implement `swiss_host.dart` and the tool, run (pass), format, analyze. Commit `feat(ZOD-TST-001): add the retrograde confirmation tool (not run)`.
- [ ] **Step 3C: Offline checks, no request.** (a) Once, by a scratch script, the real helper: `libraryDeltaTSeconds` for a pre-1972 instant of the old TT fixture equals its `ttMinusUtSeconds` within 1e-9. (b) From a scratch script, print the 8 URLs built with the real delta T, calling no HTTP function. (c) **Timestamp margin:** for all 51 times, the printed calendar time predicted if Horizons rounds and if it truncates, taking the Julian-day string both exactly and as its nearest double; record the largest predicted difference and any time predicted to exceed 1 ms in design 8.3. The tolerance is not changed. (d) `fvm dart run melos run lint` and `… test` exit 0. **Stop and report; 4B waits for approval.**
- [ ] **Step 4 (4B):** Run the mode (8 requests). Expected: exit 0.
- [ ] **Step 5: Apply the rule** of design 5.1 and record all results in the design. If a declared pair failed and its backup passed: replace the pair in `retrogradeDeclarations`. Mercury has two declared instants and one backup, so the backup replaces only one; if both Mercury instants fail, stop and ask (the tool's exit code 1 covers this too). In `_v2Instants` and `_addedInDateSetVersion2` (Task 6), drop a failed instant only if no other declared pair uses it, and add the backup instant. Then recompute and **write into this plan before Task 6**: N instants; rows 10N; instants and rows from 1972; instants before 1972 (also the control rows); backup instants and rows; and every literal in Tasks 6 and 7 that depends on them. Report the substitution to the owner.
- [ ] **Step 6:** Commit `feat(ZOD-TST-001): confirm the retrograde instants with Horizons`.

### Task 5: Dataset mode and device-copy generator

**Files:** Modify `tool/fetch_horizons_reference.dart`, `tool/horizons/horizons.dart`; Create `tool/gen_horizons_copy.dart`; Modify the tool test.

**Interfaces (produces):**

```dart
// horizons.dart
double timeScaleDisagreementArcseconds(double longitudeAtUt, double longitudeAtTt);
String horizonsCopySource(Map<String, Object?> dataset); // the whole Dart file
/// The cross-check request: TT is never used for it.
Map<String, String> utcCrossCheckQuery(String command, List<DateTime> instantsFrom1972);
/// 1 without a previous dataset; else its version, plus 1 if any row was added or changed
/// (changed: any stored value of an existing row differs, even within 0.001″).
int nextDatasetVersion(Map<String, Object?>? previous, Map<String, Object?> next);
/// The sent map as stored: every parameter except COMMAND and TLIST, without the
/// enclosing single quotes ('UT' -> UT); COMMAND is then the body -> number map.
Map<String, Object?> recordedQuery(Map<String, String> sent);
/// Empty only when every gate below passes.
List<String> datasetProblems(Map<String, Object?> dataset, {
    required List<String> instants,
    required Iterable<LongitudeRow> baseline,
    Iterable<LongitudeRow> crossCheckBaseline = const [],
    Map<String, Object?>? previous});
```

Dataset JSON keys: `version` (from `nextDatasetVersion`; 1 for this task), `referenceDatesVersion`, `source`, `retrievedOn`, `apiVersion`, `targetSources` (body → line), `quantity`, `timeScale`, `queryParameters` and `utcCrossCheckQueryParameters` (both built by `recordedQuery` from a map actually sent; the times are held by `entries.jdTt` and `utcCrossCheck.jdUt`), `toleranceArcseconds` (1), `entries` {`body`,`utc`,`jdTt`,`ttMinusUtSeconds`,`longitudeDegrees`}, `utcCrossCheck` {`body`,`utc`,`jdUt`,`longitudeDegrees`} (instants ≥ 1972-01-01; `jdUt` is the string sent), `timeScaleControl` {`utc`,`jdUt`,`tdbMinusUtSeconds`,`jdTtDerived`,`longitudeAtUt`,`longitudeAtTt`} (Moon, instants < 1972), `retrogradeEvidence` {`body`,`utc`,`jdTtBefore`,`longitudeBefore`,`jdTtAfter`,`longitudeAfter`} (3 days).

Generated copy declares: `horizonsDatasetVersion`, `horizonsToleranceArcseconds`, `typedef HorizonsReference = ({String body, String utc, String jdTt, double ttMinusUtSeconds, double longitudeDegrees})`, `typedef HorizonsUtReference = ({String body, String utc, double longitudeDegrees})`, `const horizonsReference`, `const horizonsUtCrossCheck`, with a generated-file header. The tolerance is `const double horizonsToleranceArcseconds`; the version is `const int horizonsDatasetVersion`.

**Mode `dataset --baseline <json> --out <dir>`** (both required, else exit 64; requests of design 8.6). Fixed repository paths resolve against the package root (`Platform.script.resolve('../')`); `--baseline` and `--out` are relative to the current directory, or absolute.

* reads and validates, **before the first request**, `reference_dates.json` (instants and `referenceDatesVersion`) and the baseline: the old Swiss TT fixture or a previous `horizons_reference.json` (both have `entries` with `body`, `utc`, `longitudeDegrees`; the latter also has `utcCrossCheck`, passed as `crossCheckBaseline`);
* if `packages/astro_core/test/fixtures/horizons_reference.json` exists, reads and validates it before the first request as `previous`: it feeds `nextDatasetVersion`, and its `entries` and `utcCrossCheck` are **always** compared by `changedRows`, in addition to `--baseline`. No argument skips this;
* saves raw answers in `--out` (outside the repository);
* asks the control as UT with `30,31`, sets `jdTtDerived = jdUt + tdbMinusUtSeconds/86400` to nine decimals, and asks TT there;
* writes `packages/astro_core/test/fixtures/horizons_reference.json` **once**, after all 30 requests, **only when every parser check passes and `datasetProblems` is empty**; otherwise prints the problems and exits 1.

`datasetProblems` reports: a missing (body, instant) entry; `changedRows` against `baseline` (entries), `crossCheckBaseline`, or `previous` (entries and cross-check); a missing control row for any instant before 1972; a missing evidence row for any declared pair; a missing UT cross-check row from 1972, or one more than 0.002″ from its TT entry; a control row off by more than 0.002″; no control row with |TDB − UT| > 10 s; a declared pair not retrograde.

**There is no override for a changed row.** A legitimate change (a revised Horizons solution, a new leap second, a new library ΔT) stops the tool and needs an owner decision.

- [ ] **Step 1: Failing tests:** `time scale disagreement` (`(10, 10 + 0.003/3600)` ≈ 0.003; wraps at 360); `the cross-check is asked in UT at the Julian day of the UTC instant` (`TIME_TYPE` `'UT'`, `TLIST` equal to `julianDayUt(utc).toStringAsFixed(9)` for two instants; `ArgumentError` before 1972); `version` (no previous → 1; same rows → previous; one row added → previous + 1; one longitude changed by 0.0005″ → previous + 1); `the recorded query is the sent one without quotes` (from `utcCrossCheckQuery('301', [DateTime.utc(2000)])`: `TIME_TYPE` `UT`, `TLIST_TYPE` `JD`, `CENTER` `500@399`, no `TLIST`, `COMMAND` equal to `horizonsCommands`); `a clean synthetic dataset has no problems`; then one test per problem above, each altering one value and expecting a non-empty list (for `previous`: a row that differs by 0.002″ and is absent from `baseline`); `the copy holds every entry and cross-check row` (two-row synthetic dataset: output contains both typedefs, `const int horizonsDatasetVersion = 1;`, each row's body, utc, `jdTt` string and longitude, and no `timeScaleControl`).
- [ ] **Step 2:** Run: compile failure. **Step 3:** Implement the functions, the `dataset` mode and the generator (`gen_horizons_copy.dart` reads `../astro_core/test/fixtures/horizons_reference.json` and writes `../../apps/astro_mobile/integration_test/horizons_reference.dart`, both relative to the package root). **Do not run `dataset` yet.**
- [ ] **Step 4:** Run the tool tests (pass). **Step 5:** Commit `feat(ZOD-TST-001): build the dataset and its device copy`.

### Task 6: Date set version 2, the dataset and every consumer (one commit)

One commit, because the date set, the data and its consumers each fail without the others.

**Files:**
* Modify: `packages/astro_core/test/fixtures/reference_dates.json`, `test/accuracy/reference_dates_test.dart`, `test/accuracy/t_eph_2_mean_node_test.dart`
* Create: `packages/astro_core/test/fixtures/horizons_reference.json`, `test/accuracy/horizons_reference_test.dart`
* Create: `packages/ephemeris_swiss/test/horizons_reference_time_test.dart`
* Create: `apps/astro_mobile/integration_test/horizons_reference.dart` (generated), `test/horizons_reference_match_test.dart`
* Modify: `apps/astro_mobile/integration_test/swiss_ephemeris_accuracy_test.dart`, `packages/ephemeris_swiss/tool/tt_grid.c` (comment names the new tool)
* Delete: `packages/ephemeris_swiss/test/fixtures/reference_longitudes_tt.json`, `test/reference_tt_fixture_test.dart`, `tool/fetch_horizons_tt_reference.dart`, `apps/astro_mobile/integration_test/swiss_reference_longitudes_tt.dart`, `test/swiss_reference_longitudes_tt_match_test.dart`
* Backup (option A, design section 10): `packages/ephemeris_astronomy/test/reference_fixture_test.dart`, `reference_tt_fixture_test.dart`, both `test/fixtures/*.json`, both `tool/fetch_horizons*_reference.dart`, both generated `apps/astro_mobile/integration_test/astronomy_reference_longitudes*.dart`, `astronomy_accuracy_test.dart`, `astronomy_speed_vs_swiss_test.dart`

The 11 version-2 instants (all `Z`): `1953-11-18T00:00:00`, `1956-09-10T00:00:00`, `1971-12-31T23:59:59`, `1972-01-01T00:00:00`, `2012-06-12T00:00:00`, `2023-08-01T00:00:00`, `2023-10-15T00:00:00`, `2049-05-11T00:00:00`, `2100-07-01T00:00:00`, `2100-12-31T00:00:00`, `2100-12-31T23:59:59`.

- [ ] **Step 1: Failing tests, date set.** In `reference_dates_test.dart`: add `_v2Instants` (the 11) and `version 2 holds every version-2 instant` (`version == 2`, `_v1Instants.length + _v2Instants.length == dates.length == 64`, all contained). Rename the window test to `stays between T = −1 and the end of the supported range` with end `SupportedDateRange.end`. As recorded in PROGRESS ("Carry into ZOD-TST-001"), the T = ±1 knowledge moves to T-EPH-2: in its accuracy-bound group add `only the three 2100 instants lie outside T = ±1` (the instants before 1899-12-31T12:00Z are none; those after 2100-01-01T12:00Z equal `2100-07-01T00:00:00Z`, `2100-12-31T00:00:00Z`, `2100-12-31T23:59:59Z`). The existing `is within the bound on every reference date` is unchanged, so the bound is still asserted on all of them. No new production import in that file.
- [ ] **Step 2: Failing tests, dataset** (`horizons_reference_test.dart`):
  * `provenance`: `version == 1`; `referenceDatesVersion` equals the date file's `version`; `source` contains `Horizons`; `retrievedOn`, `apiVersion` non-empty; `targetSources` has the ten bodies; `queryParameters` `CENTER` `500@399`, `EPHEM_TYPE` `OBSERVER`, `QUANTITIES` `31`, `TIME_TYPE` `TT`, `TLIST_TYPE` `JD`, `APPARENT` `AIRLESS`; tolerance 1.
  * `every body at every shared instant, once` (640 keys equal dates × bodies); longitudes in [0, 360); `jdTt` matches `^\d+\.\d{9}$`.
  * `at least 50 instants from 1900 to 2100` (63); `includes 2100-12-31T23:59:59Z and 1999-12-31T23:59:59Z`.
  * `a retrograde instant for each body from mercury to pluto, none for sun or moon`: the (body, utc) set equals the nine declared pairs written as literals; every utc is a shared instant; for each, the shortest signed steps before→at and at→after are both negative.
  * `the UT cross-check holds every body from 1972, and nothing earlier` (420); `utcCrossCheckQueryParameters` has `TIME_TYPE` `UT` and `TLIST_TYPE` `JD`.
  * `retrograde evidence is asked 3 days either side`: `jdTtBefore` and `jdTtAfter` differ from the entry's `jdTt` by −3 and +3 days within 2e-9.
  * `Horizons TIME_TYPE=TT is the same scale as its UT`: 22 control rows equal to the shared instants before 1972; `|atTt − atUt| ≤ 0.002″`; `jdTtDerived` within 2e-9 of `jdUt + tdbMinusUtSeconds/86400`; some `|tdbMinusUtSeconds| > 10`.
- [ ] **Step 3: Failing tests, consumers.** `horizons_reference_time_test.dart` repoints the old test's three conversion tests to the shared dataset, asserting exactly 420, 220 and 420 checked rows (the third compares `entries` with `utcCrossCheck`, 0.002″, with `DateTime.utc(1972)` as a literal; it also asserts, as the old test did, that the cross-check was asked in UT: `utcCrossCheckQueryParameters['TIME_TYPE'] == 'UT'`, and every row's `jdUt == julianDayUt(utc).toStringAsFixed(9)`). `horizons_reference_match_test.dart` requires the copy's version, tolerance, both lengths and every field of every row to equal the JSON.
- [ ] **Step 4:** Run:
  * `Push-Location packages/astro_core; fvm dart test test/accuracy; Pop-Location` → FAIL: `version` is 1; the three 2100 instants are absent; the dataset file is missing.
  * `Push-Location packages/ephemeris_swiss; fvm dart test test/horizons_reference_time_test.dart; Pop-Location` → FAIL: dataset file missing.
  * `Push-Location apps/astro_mobile; fvm flutter test test/horizons_reference_match_test.dart; Pop-Location` → FAIL: the copy's import does not exist.
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

  Replace **every** use of `swissTtToleranceArcseconds`, including those in `the comparison itself` and `damaged files`, with `horizonsToleranceArcseconds`; those and the other tests are otherwise unchanged. Rewrite the file header, which describes UTC input at the reference instants: this is T-EPH-1 and ACC-1, the tests are mandatory (ACC-5), and why no pre-1972 UT value is gated.
- [ ] **Step 9:** Delete the five old files. Run `git grep -nE "swiss_reference_longitudes_tt|fetch_horizons_tt_reference|reference_tt_fixture_test" -- apps packages test tool`. Expected: only `packages/ephemeris_astronomy` and `astronomy_*` hits (the backup's own files of those names).
- [ ] **Step 10: Backup tests (option A).** In both fixture tests, require rows for every shared instant in [1899-12-31T12:00Z, 2100-01-01T12:00Z], and add `only instants after the covered range are left out`: the excluded set equals `{2100-07-01T00:00:00Z, 2100-12-31T00:00:00Z, 2100-12-31T23:59:59Z}`, and the included set contains `1899-12-31T12:00:00Z` and `2100-01-01T12:00:00Z`. Existing boundary tests stay. Run `Push-Location packages/ephemeris_astronomy; fvm dart test test/reference_fixture_test.dart test/reference_tt_fixture_test.dart; Pop-Location`. Expected: each coverage test FAILS at its first missing key, `sun|1953-11-18T00:00:00Z`; `only instants after the covered range are left out` passes at once.
- [ ] **Step 11:** In both backup tools, filter the instants to that same range before building `dateStrings` and the time list; query parameters unchanged. Change the written `instants` provenance string and the header comments to `every instant of reference_dates.json within 1899-12-31T12:00Z to 2100-01-01T12:00Z (N at the time of the fetch)`, and update the "53" comments. Run both from `packages/ephemeris_astronomy` (20 requests). Expected: `wrote 610 entries` each. The two `astronomy_reference_longitudes*_match_test.dart` host tests are unchanged and must pass.
- [ ] **Step 12: Old backup rows unchanged.** A scratch script outside the repository loads each fixture from `git show HEAD:<path>` and from the working tree and requires every old (body, utc) row to be present with identical `longitudeDegrees` (and `utDays`, `ttDays`, `deltaTSeconds`, `jdTt` for the TT fixture). Expected: 530 identical, 0 differences, each. Any difference: stop and report. Format the two generated copies.
- [ ] **Step 13:** `astronomy_accuracy_test.dart`: `hasLength(53)` → `hasLength(61)`, "53 instants" → "61 instants"; tolerance unchanged. `astronomy_speed_vs_swiss_test.dart`: a const set `_addedInDateSetVersion2` (the eight in-range instants), excluded from `referenceInstants`, then `expect(referenceInstants, hasLength(53))`; bounds unchanged.
- [ ] **Step 14:** `fvm dart run melos run lint`; `fvm dart run melos run test`. Expected: exit 0. `git diff --stat main -- ":(glob)**/lib/**"` prints nothing.
- [ ] **Step 15:** Commit `test(ZOD-TST-001): add the shared Horizons dataset and move its consumers to it`.

**If the owner chooses option B instead:** Step 10 makes both tests require the 53 version-1 instants (listed literally) and keeps the same boundary assertions; Steps 11 to 13 are skipped; no backup fixture, tool or device test changes.

### Task 7: Mean node against Swiss Ephemeris

**Files:** Create `packages/ephemeris_swiss/tool/node_grid.c`, `tool/gen_swiss_mean_node.dart`, `packages/astro_core/test/fixtures/swiss_mean_node.json`, `test/accuracy/mean_node_vs_swiss_test.dart`, `apps/astro_mobile/integration_test/swiss_mean_node_test.dart`.

**Interfaces:** `node_grid <data dir> <jd tt>…` prints per Julian day: mean-node longitude and returned flags for `SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_NONUT`, the J2000 variant's longitude (`… | SEFLG_J2000`), and the true node's (`SE_TRUE_NODE`, default flags); exits non-zero on any error or warning. The generator takes the instants and `jdTt` from `horizons_reference.json` and writes `version` 1, `referenceDatesVersion`, `source` (library version, host build), `requestedFlags` 322, `entries` {`utc`,`jdTt`,`meanNodeDegrees`,`returnedFlags`,`j2000Degrees`,`trueNodeDegrees`}.

- [ ] **Step 1: Failing host test** (imports only `astro_core` and `package:test`): `the fixture belongs to the shared dataset` (`version == 1`; `referenceDatesVersion` equals the date file's `version`; `requestedFlags == 322`; every entry's `jdTt` equals the `jdTt` of that `utc` in `horizons_reference.json`); `covers every shared instant once` (64); `the reference is the mean node on the mean equinox of date` (every `returnedFlags`: `& 64 != 0`, `& 32 == 0`, `& 65536 == 0`); `the formula is within 0.01 degrees of Swiss at every shared instant` (`meanAscendingNodeAt(utc).longitude`, shortest angle ≤ 0.01); `controls: J2000 and the true node differ by more than 0.01 degrees` (maximum over the set > 0.01 for each).
- [ ] **Step 2:** Run. Expected: FAIL, fixture missing.
- [ ] **Step 3:** Implement the C tool and generator; run it. **Step 4:** Run the test (pass); the 0.01° test prints the maximum and its instant (planning measured at most 0.00216° over a daily sweep).
- [ ] **Step 5: Device test:** with `SwissEphemerisBinding` and the packaged data: at the 64 instants (`jdTt` from `horizonsReference`) and monthly from 1900-01-01 to 2100-12-01 (2,412 instants, TT by the production rule: `calcUt` before 1972, else `calcTt(julianDayUt(utc + ttMinusUtc))`), `port.position(Body.node, utc)` is within 0.01° of body 10 with flags `seflgSwieph | seflgSpeed | 64`; every flag word returned by the **mean-node reference calls** has 64 set and 32 clear (the J2000 control returns 32 set); J2000 (`| 32`) and body 11 exceed 0.01° somewhere. Print the maxima. Constants for 10, 11, 32 and 64 are declared in the test.
- [ ] **Step 6:** Lint and tests exit 0. Commit `test(ZOD-TST-001): validate the mean node against Swiss Ephemeris`.

### Task 8: Device verification and mutation proofs

Emulator `Pixel_9_Pro_API_36` (x86_64; start with `-memory 3072`, saved configuration unchanged). From `apps/astro_mobile`, one file at a time: `fvm flutter test integration_test/<file> -d emulator-5554`.

- [ ] **Step 1:** `swiss_ephemeris_accuracy_test.dart`, `swiss_mean_node_test.dart`; under option A also `astronomy_accuracy_test.dart`, `astronomy_speed_vs_swiss_test.dart`. Expected: all pass. Record every per-body maximum, in particular at the 2100 instants and the retrograde instants. A result over its bound: stop and report. Under option A also stop and report if a backup body exceeds the 17.6″ matched-TT figure documented in `astronomy_ephemeris.dart` (no `lib/` change is allowed here).
- [ ] **Step 2: Mutation proofs** (temporary, each observed failing, then restored with `git status` clean): one copied longitude +2″ → the T-EPH-1 / ACC-1 gate fails; one Moon `jdTt` +1 s in the copy → the TT pin fails; `meanNodeEpochLongitude` +0.02 → the host node test fails; the device node test's flags without 64 → its flag assertion fails.
- [ ] **Step 3:** Record device, head commit, counts and maxima in the design (a results section). A dropped or disconnected run is void and repeated.

### Task 9: Review, documentation, completion

- [ ] **Step 1:** `superpowers:requesting-code-review`: one fresh reviewer over the whole branch. Fix important findings test-first. **No code of this task has had an independent review yet.** The reviewer's prompt carries the context below and requires an explicit judgement on each item:
  * **Context (owner, 2026-11-26):** the round 1 amendments of plan revision 1 (stricter Task 3) were implemented **without a separate owner approval**; the owner accepted the Tasks 0 to 3 implementation afterwards.
  * the stricter parser rules and their error messages (Task 3);
  * the additional refusal and acceptance tests, including those beyond the plan (Task 3);
  * the reconstruction of request URLs against the original pilot requests (what the repository test pins, and what only a scratch script checked);
  * the 30 mutation checks and whether they cover the parser's failure modes adequately (evidence section below).
- [ ] **Step 2:** `superpowers:verification-before-completion`: lint, full tests, `git diff --stat main -- ":(glob)**/lib/**"` empty, `git status --short`; rerun device files touched by review fixes.
- [ ] **Step 3:** Documentation: task file (criteria ticked with evidence, status, Notes with hand-offs; criteria wording unchanged); `TASKS.md` status; `docs/PROGRESS.md` (completed task, verification with head commit, blockers: backup item still open for ZOD-TST-005, decisions; the "Carry into ZOD-TST-001" item marked done); one line in `docs/decisions/ZOD-EPH-002-time-scale.md` section 9 pointing from the removed test path to `horizons_reference_time_test.dart`; a dated update line in `docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md` section 5 (what is now validated through 2100-12-31, for the primary only); a dated update on the `TASKS.md` ZOD-EPH-004 bullet that still says an owner decision is needed before ZOD-TST-001. Hand-offs recorded in PROGRESS (other task files are not edited; each becomes a Notes line when that task is planned): ZOD-EPH-002 (its 53-instant UTC-input evidence is superseded by the repointed gate), ZOD-TST-004 (build on the repointed gate), ZOD-TST-005 (shared TT is the primary's; the backup's fixtures and speed-test exclusion; time-model discrepancy), ZOD-EPH-006, ZOD-TST-017 (the T-EPH-1 / ACC-1 gate runs on a device, not in CI).
- [ ] **Step 4:** Commit `docs(ZOD-TST-001): record verification and completion`. **Stop: push and PR need the owner's approval.**

## Evidence kept for the Task 9 review (Tasks 0 to 3, not independently reviewed)

**URL reconstruction.** The repository test `the query reproduces the two pilot requests` pins pilot requests 1 and 2 (design 8.5). Requests 3 to 11 were compared only by a scratch script (`parse_all.dart`, planning session scratch folder), which on `6531069` parsed all 11 saved answers (17 rows) and rebuilt all 11 logged URLs identically.

**Mutation checks** (scratch script `mutate.dart`, on `6531069`): each change below was applied alone to `tool/horizons/horizons.dart`, `test/horizons_tool_test.dart` was run, and the file was restored; 30 of 30 made at least one test fail. They were chosen by the author of the code, so their coverage is itself a review item.

| Area | Changes |
|---|---|
| markers, version, scale | marker refusal disabled; API version refusal disabled; scale-suffix refusal disabled; only the `Start time` line read; only the `Stop  time` line read |
| target, centre | target refusal disabled; centre-body clause removed; site refusal disabled; site compared by `contains` |
| columns | calendar, Julian-day, longitude and quantity 30 columns each replaced by a fixed index |
| rows, fields, numbers | `!=` rows → `<`; `!=` fields → `>`; number pattern refusal disabled |
| time | only the calendar echo checked; only the Julian-day echo checked; tolerance × 5; tolerance ÷ 4 |
| values | longitude precision clause removed; quantity 30 decimals 3 → 2; negative longitude allowed; 360 allowed; printed Julian day returned instead of the requested one |
| other functions | `APPARENT` removed from the query; ordering check disabled; retrograde `&&` → `\|\|`; row tolerance 0.001 → 0.002; missing row not reported |

## Plan review

**Round 1 (2026-11-26, `plan-reviewer`, on `e9f7488`): "Needs user decision"** (D1 blocks Task 6); 1 Critical, 5 Important, 10 Minor.

| ID | Finding | Done |
|---|---|---|
| C1 | removed constant still used by other device tests | applied |
| I1 | the UT cross-check could be asked in TT and still pass | applied (query and `jdUt` recorded and asserted) |
| I2 | the `dataset` gates had no tests | applied (`datasetProblems`) |
| I3 | `dataset` inputs and outputs unstated | applied |
| I4 | backup-date substitution not executable | applied |
| I5 | node test accepted a stale or mistimed fixture | applied |
| M1 to M8, M10 | evidence Julian days; version rule; node wording; commands and expected output; backup provenance strings; sample line endings; elongation figure; pilot dates in the approval; boundary tests | applied |
| M9 | documentation and hand-offs | applied differently: the other task files are not edited (project convention: a Notes line when each is planned); the rest applied, including the recorded "move the window check to T-EPH-2" item |

**Design builder check (2026-11-26, fresh general-purpose agent, same commit):** not a plan-review round. Applied: the last-instant coverage probe, the 1972-boundary probe, no override for protected rows, backup rows must be identical, the wording of link 3, the nutation figure (re-measured: 0.00527°), the elongation figure, the two backup match tests. Sent to the owner: D1 (including editing backup tools and fixtures) and D6 (confirm `SEFLG_NONUT`).

**Round 2 (2026-11-26, `plan-reviewer`, focused, `e9f7488..fc8d460`): "Needs user decision"** (only the open D1 to D6); no Critical, 4 Important, 5 Minor; all round 1 findings resolved. All nine applied after the round; **these last corrections have not been re-reviewed** (two rounds is the limit of a cycle).

| ID | Finding | Done |
|---|---|---|
| I1 | recorded query parameters: quoted or not, and which body's | applied (`recordedQuery`) |
| I2 | row protection could be bypassed through `--baseline` | applied (an existing dataset is always compared) |
| I3 | path resolution would break the download command | applied; inputs read before the first request |
| I4 | the pilot did not gate printed precision | applied |
| M1 to M5 | command form; missing-row gates; "changed" defined; wording of the pre-1972 constraint; tolerance type | applied |

D1 to D6 (design section 13) were open after round 2; **the owner approved the recommended answers on 2026-11-26.**

### Revision 1 (2026-11-26): the pilot workflow (owner decision, Option A)

The pilot was run by a throwaway script outside the repository and accepted as the completed pilot. Amendments: Task 2 is now "answers as parser samples" (no `pilot` mode, no repeat); Task 3 pins its checks, their order and their messages to the verified format (centre check corrected: the answers never print `500`; both echoed times; precision gates now enforced by the parser); Task 1 gains a test that the repository's query reproduces the two sample requests; Task 4 now creates the fetch tool (its HTTP behaviour moved from Task 2); stage boundaries added to Global Constraints; design section 8 records the format and results (old 8.1 is now 8.6).

**Revision 1, round 1 (`plan-reviewer`, on `a94d6e7..e6eb9b9`): "Approve after corrections"**; no Critical, 1 Important, 7 Minor, nothing for the owner.

| ID | Finding | Done |
|---|---|---|
| I1 | the refusal word `time` is a prefix of `time scale` | applied (each message starts with the word and a colon) |
| M1 | `NaN` would parse as a number | applied (decimal pattern) |
| M2 | centre-site and line-end matching loose | applied |
| M3 | a row edit could hit a header line; some wrong parsers would pass | applied (edit rule; three refusal and two passing tests) |
| M4 | rounding of the printed milliseconds not established | applied (recorded; integer microseconds; tolerance not widened) |
| M5 | a refused answer might not be on disk | applied |
| M6 | stage-boundary wording | applied |
| M7 | stale PROGRESS wording | applied |

**Revision 1, round 2 (`plan-reviewer`, focused, `e6eb9b9..bae0323`): "Approve"**; no Critical or Important, all eight round 1 findings resolved, nothing for the owner. Two optional wording items, both applied: a PROGRESS separator and commit hashes (M1), and the 0.518 ms figure in a test name (M2). **No open items.**
