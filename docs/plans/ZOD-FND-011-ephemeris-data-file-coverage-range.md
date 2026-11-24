# ZOD-FND-011 Ephemeris data-file coverage range: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). Nothing here is independent enough for subagents: Task 1's constant is read by Tasks 2 to 4, and Task 5 records what Tasks 1 to 4 produced. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Record the owner's decision (Option 2): the existing Swiss Ephemeris file pair `sepl_18` + `semo_18` (physical coverage 1800 to 2400) stays, and the user-facing supported date range is **1900-01-01 through 2100-12-31 inclusive**. Define that range once, in code and in a decision record, with exact boundary behavior, the "outside range" message copy, and the hand-offs to every consumer.

**Architecture:** Two ranges are kept apart everywhere. *Physical coverage* (what the data files contain, 1800 to 2400) belongs to the Swiss adapter (EPH-002). *The supported product range* (what the app lets a user use, 1900 to 2100) is one pure-Dart constant in `astro_core`, read by every consumer and by the core query API, so the UI alone never enforces it. This task adds the constant, a guard on the packaged file set, the two message strings (ARB, en + he), and the decision record. It does **not** change `EphemerisPort`, the sealed `EphemerisFailure`, or any adapter; it specifies the behavior EPH-002 must implement and records the proposed contract wording for the owner (the ZOD-EPH-004 precedent: proposed, unapplied).

**Tech Stack:** Dart 3.14 / Flutter 3.50.0 (`.fvmrc`). Every SDK command runs as `fvm dart ...` / `fvm flutter ...` and Melos as `fvm dart run melos ...` (PROGRESS conventions; the bare global `dart` is 3.6 and cannot resolve this workspace). `package:test` in `astro_core` and `ephemeris_swiss`, `flutter_test` in `shared_ui`, `fvm flutter gen-l10n`.

**Spec:** `assets/zodiann-specification.md`: "Data files" row (line 393), "Computation settings that must be fixed and documented" Date range row (line 368), R-2 (line 729), WH-16 (line 128), SQ-5 (line 152; SQ-10 is the square *size*, see Finding F4), "Limits that will remain in the file" (line 257), ACC-1 (line 381), NFR-R2 (line 640). Task file: `docs/development/foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md`.

## Owner decision (recorded, 2026-11-25)

**APPROVED: Option 2.** Keep `sepl_18` and `semo_18` (1800 to 2400); limit the user-facing supported range to 1900 to 2100 inclusive. Plan only, no implementation before this plan is approved. Constraints from the same message, all binding here: do not add neighbouring 600-year blocks; do not claim validated accuracy for 1800 to 1900 or 2100 to 2400; keep the far-future (ΔT forecast) warning; Excel's pre-1900 limit applies to square date-anchor export only; no silent fallback to the lower-accuracy built-in ephemeris; preserve every acceptance criterion and technical contract; do not edit task files, code, dependencies or documentation until the plan is approved.

## Global Constraints

- **R-2 (spec line 729):** outside the date range the library guarantees, "limit the date range in the interface and show a clear message on an overrun". Never an approximate position.
- **NFR-R2 (line 640):** invalid input is rejected "with a clear message, with no crash".
- **WH-16 (line 128):** "a date range of up to 3,660 days"; default "from today to one year ahead". **Product limits (line 299):** "a range of up to 3,660 days, and up to 2,500 displayed rows".
- **ARCH-2:** `astro_core` and `ephemeris_swiss` stay Flutter-free (`pure_dart_test`, `dependency_closure_test`); **L-9:** they never reach localization (`no_l10n_in_core_test`), so message copy lives in `shared_ui`, never in `astro_core`.
- **Every `DateTime` is UTC at the port** (`EphemerisPort`); callers convert local time first.
- **AGPL / no new dependency:** no dependency is added (in particular `ephemeris_swiss` does **not** gain an `astro_core` edge: that is the edge EPH-002 introduces); no network (`no_network_test`).
- **Existing guards stay green:** Lint with `--fatal-infos`, `format:check`, `l10n:check` (fails on stale `gen-l10n` output), `arb` key parity and description guards, `sentence_case_test`, `no_text_literals_test`, every `Full suite` job.
- **Spec text is not edited.** The task file's wording (including its "SQ-10" citation) is not edited without owner approval (Finding F4).

## Findings from inspection (facts the plan relies on)

- **F1. Data files and size (existing measured evidence, `docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md` section 4).** `sepl_18.se1` 484,061 B + `semo_18.se1` 1,304,771 B = 1,788,832 B raw; 1,662,654 B stored in the APK (432,691 + 1,229,963); release APK grows **+1,663,124 B per ABI** (arm64-v8a 18,537,162 to 20,200,286 B; armeabi-v7a 16,157,122 to 17,820,246 B; x86_64 19,788,968 to 21,452,092 B). Option 2 adds **no** bytes: it is the spike's file pair. iOS size is added by ZOD-IOS-009. Measured on Android emulator builds only.
- **F2. `coveredRange` has two meanings today.** `EphemerisPort.coveredRange` is documented as "the inclusive UTC range in which this source guarantees its stated accuracy" **and** "the app's UI uses it to limit date input". Under Option 2 these split (files 1800 to 2400, accuracy validated 1900 to 2100). See Decision D3 and open question Q1.
- **F3. The backup's range is narrower than the approved range.** `AstronomyEphemeris.coveredRange` is 1899-12-31T12:00Z to **2100-01-01T12:00Z** (`packages/ephemeris_astronomy/lib/src/astronomy_ephemeris.dart:78-80`). If the backup is ever selected (EPH-002 owns selection), 2100-01-01T12:00Z to 2100-12-31 returns `OutOfCoveredRange` *inside* the supported range. Open question Q2.
- **F4. Citation error in the task file.** The task file cites **SQ-10** for "square anchors"; SQ-10 is the square *size* (9x9 to 61x61). Anchors are **SQ-5**. Not corrected silently (owner approval; listed in Task 6).
- **F5. The Square does not use the ephemeris.** `packages/feature_square` and `packages/gann_core` have no `astro_core` or `EphemerisPort` dependency (grep over `packages/feature_square` and `packages/gann_core`, 2026-11-25: no import, no pubspec entry); dates are calendar arithmetic (SQ-3, SQ-4). Applying 1900 to 2100 to square anchors would be a **product rule, not an accuracy rule**; the only spec-stated square limit is Excel's pre-1900 export limit. Open question Q3.
- **F6. ACC-1's actual dataset span.** `packages/astro_core/test/fixtures/reference_dates.json` (53 instants) runs from **1899-12-31T12:00Z to 2100-01-01T12:00Z** (the +-100-year ends, T = -1 and +1). So the *dataset* validates the Swiss model to 2100-01-01T12:00Z; the last 364 days of the approved range (2100-01-01T12:00Z to 2100-12-31) are not in any reference instant. The spec's ACC-1 wording is "from 1900 to 2100". Open question Q2 (the file is add-only; ZOD-TST-001 may add instants and must bump `version`).
- **F7. Excel and 1900.** Excel's default 1900 date system counts a non-existent 1900-02-29, so serial numbers for 1900-01-01 to 1900-02-28 differ by one day from LibreOffice and Google Sheets (which use the 1899-12-30 epoch). The export uses `=Anchor + k` (EX-9), so an anchor in January or February 1900 could disagree by one day between applications. **Not decided here:** recorded as a finding and an open question for XLS-017/XLS-001 (whether the export floor is 1900-01-01 per the spec, or 1900-03-01); the spec text "before the year 1900" is unchanged. To be verified in the three applications by those tasks, not asserted as measured.
- **F8. The wheel's moment can cross the edge by many routes:** the date field (WHL-014), Now (WHL-014, WHL-023: a device clock outside the range), step buttons (WHL-016), playback at one step per 110 ms (WHL-017, the likeliest to run past an edge), change-date drag (WHL-011), keyboard and accessibility actions (WHL-012, WHL-013), tap a crossing row (WHL-019/022). The crossing table's From/To (WHL-020, CRS-004): the default "today to one year ahead" and a 3,660-day span both run past 2100 from 2095 onwards.
- **F10. A spec row says something different from Option 2.** The spec "Date range" row (line 368) reads "According to the coverage of the data files that are packaged". The approved product range (1900 to 2100) is narrower than the packaged files (1800 to 2400). The spec text is **unchanged**; the deviation is recorded in the decision record (Task 4) and Q6 asks the owner to confirm the row stays as written or is reworded. Only the owner edits the specification.
- **F9. Real physical guard is per call.** The library silently falls back to Moshier when a file is missing or out of range (spike section 6, item 1: flags 260 and a warning at 1799-12-31). The authoritative physical guard is `SwissCalcResult.usedSwissEphemerisFiles` on every call (EPH-002). Nominal file edges (1800-01-01 and 2400-01-01 from the upstream block names) are **informational until EPH-002 measures them on a device**; the native library does not load on the host, so no host test can measure them. The approved range sits 100 years and about 299 years inside the nominal edges, so the exact edge instants cannot affect any supported date.

## Decisions (D1 is the owner's; D2 to D7 are this plan's, for the owner to check)

- **D1 (owner, 2026-11-25): Option 2**, as above.
- **D2 (exact bounds, UTC instants).** `supportedStart = 1900-01-01T00:00:00Z`; `supportedEnd = 2100-12-31T23:59:59.999999Z` (the last representable microsecond of 2100-12-31, so the whole day is inside; both ends inclusive, same convention as `UtcRange`). Range membership is judged on the **UTC instant after the caller's local-to-UTC conversion**, never on the local calendar date: a local 1900-01-01 00:00 at UTC+14 is 1899-12-31T10:00Z and is *outside*; a local 2100-12-31 23:00 at UTC-10 is 2101-01-01T09:00Z and is *outside*. Date pickers must validate the converted instant and say so in the message (the message names the range in the user's date format). *My call: judging on the instant is the only reading consistent with the port's UTC contract and it cannot be bypassed by a time-zone change.* The alternative (judge on local calendar date) lets the same instant be valid in one time zone and rejected in another.
- **D3 (what `coveredRange` means). Proposed, owner decision, not applied (Q1).** *Recommended A:* the Swiss adapter's `coveredRange` reports **physical coverage** (what the data files contain), and a product-range guard enforces 1900 to 2100 in front of every source: a small `EphemerisPort` decorator in `astro_core` (EPH-002 builds it) that returns a **new** sealed subtype `OutsideSupportedRange(requested, supported)` for any instant outside `SupportedDateRange`, for **all bodies including the node** (the product range is a limit on the wheel, not on one source; the port's "node works for any utc" wording needs an exception for the decorator). This keeps the two cases distinguishable: `OutsideSupportedRange` (user chose an unsupported date) versus `OutOfCoveredRange` (data missing for a date the product allows: a defect, never hidden). It requires amending the `coveredRange` doc comment (the UI limits input with `SupportedDateRange`, not `coveredRange`) and adding a sealed subtype, which makes every exhaustive `switch` over `EphemerisFailure` handle it. Both are FND-002 contract edits and are **not made by this task**. *Alternative B:* `coveredRange` = 1900 to 2100 for every source and the physical edge stays internal to the adapter; no contract change, but both failures return `OutOfCoveredRange` and the physical-versus-product distinction is no longer observable. A is recommended because the owner asked for the distinction to be preserved.
- **D4 (messages: two, not one).** `outside supported range` (user input; names the range) and `position data unavailable` (data missing inside the range). Different failures, different remedies; EPH-002's `OutOfCoveredRange` maps to the second, `OutsideSupportedRange` to the first. The ΔT-forecast banner is a third message owned by NFR-017 and is **untouched**.
- **D5 (enforcement points, not UI only).** The constant is read by: the position decorator (D3), the core crossing API (CRS-004: From and To must lie inside the range and the span stays at most 3,660 days; typed rejection, never silent clamping in the core), and each UI input route in F8 (validate the converted instant, clamp or reject with the D4 message per NFR-R2, WHL-020 already allows "rejected or clamped"). Hand-offs are in the ownership table (Task 6).
- **D6 (no second definition).** Only `supported_date_range.dart` holds the literals 1900 and 2100 as the product range. `AstronomyEphemeris`'s own `_coveredRange` is that source's validity, not a product range, and stays.
- **D7 (data packaging).** Keep the regular `ephemeris_swiss` dependency in `apps/astro_mobile/pubspec.yaml` (the release app carries the files; spike section 5 deferred this confirmation to FND-011), update the stale spike comment in `packages/ephemeris_swiss/pubspec.yaml`, and pin the packaged set by a test so a neighbouring block cannot be added unnoticed.

## Boundary behavior (the specification EPH-002 and every consumer implement)

`P = [1900-01-01T00:00:00Z, 2100-12-31T23:59:59.999999Z]` (`SupportedDateRange`). `F` = the Swiss data files' physical coverage (nominal 1800-01-01T00:00Z to 2400-01-01T00:00Z). Assumes D3-A.

| Requested instant `t` (UTC) | Through the decorator (what the app sees) | Swiss adapter alone (tests, oracles) |
|---|---|---|
| `t < P.start` (including `P.start - 1 us`) | `OutsideSupportedRange`; the adapter is not called | `t` in `F`: a true Swiss position. `t < F.start`: `OutOfCoveredRange` (files not used, never Moshier) |
| `P.start <= t <= P.end` and files used | `EphemerisSuccess` | `EphemerisSuccess` |
| `P.start <= t <= P.end` and `usedSwissEphemerisFiles` is false | `OutOfCoveredRange` (data unavailable; **no** automatic Moshier, no backup swap) | same |
| `t > P.end` (including `P.end + 1 us`) | `OutsideSupportedRange` | `t` in `F`: a true Swiss position. `t >= F.end`: `OutOfCoveredRange` |
| any `t`, `t.isUtc == false` | `ArgumentError` (unchanged) | `ArgumentError` |
| Node, any `t` | inside `P`: formula result; outside `P`: `OutsideSupportedRange` (decorator only; this contradicts the current port doc "node works for any utc", `ephemeris_port.dart:59-61`, and is part of Q1) | formula result for any `t` (unchanged) |

Selecting Moshier (ZOD-EPH-003) or the backup is only ever an explicit user choice (EPH-002 owns automatic selection); the decorator applies to every source.

## Accuracy statement and widening checklist

- **Validated today:** ACC-1's reference set (F6) spans 1899-12-31T12:00Z to 2100-01-01T12:00Z. **Not validated, and not claimed:** 1800 to 1899-12-31, 2100-01-01T12:00Z to 2400, and (until Q2 is resolved) the last 364 days of the product range.
- **Evidence required before widening the product range** (changing one constant plus tests): (1) a reference dataset for the new span with the ACC-1 shape (at least 50 dates, year starts, retrograde neighbourhoods, both ends), from JPL Horizons at identical settings, all ten bodies; (2) Swiss Ephemeris within one arcsecond of it for the Sun and Moon (T-EPH-1), and the per-body bounds recorded for the rest; (3) the ZOD-TST-001 vs ΔT decision applied to the new far ends (the Moon at far-future UT instants); (4) the crossing oracle (T-CRS-2) rerun over the new span; (5) if the span leaves 1800 to 2400, new data blocks, a re-measured size (F1) and a new FND-011 record; (6) the Excel floor (F7) rechecked; (7) the owner's approval.
- **ΔT warning stays.** It is an in-range concern (2030 to 2100) as well as a far-future one; EPH-002 exposes the flag and NFR-017 shows it. This task invents no threshold.

## Review Focus

1. **Time zone at the edge.** A user at UTC+14 types 1900-01-01 00:00 local (= 1899-12-31T10:00Z), or at UTC-10 types 2100-12-31 23:00 local (= 2101-01-01T09:00Z). Expected: rejected with the supported-range message, never accepted by one zone and refused in another. Test: Task 1 boundary tests at +-1 microsecond and the two converted instants.
2. **Playback and step buttons running past 2100-12-31.** Expected: stop at the last supported instant (or refuse the step) with the message, no crash, no frozen playback. Hand-off to WHL-016/WHL-017; pinned here by `SupportedDateRange.classify` returning `after` for `end + 1 us`.
3. **The default crossing filter from 2095 onwards, and a 3,660-day span from 2095.** Expected: the core rejects a To after `P.end` with a typed error; the UI clamps or rejects with the message; the solver never probes beyond To (a probe past the range end would abort the last crossing of 2100-12-31). Hand-off to CRS-004/WHL-020.
4. **A device clock outside the range** (wrong clock, or year 2101+). The wheel opens at "now" (WH-14, WHL-023) and Now sets "now". Expected: the out-of-range message, not a crash, not a position. Hand-off to WHL-014/WHL-023/NFR-017.
5. **A neighbouring data block quietly added later**, or a file renamed so the pair no longer covers the range. Expected: a test fails. Test: Task 2 (`data_files_test.dart`).
6. **A Hebrew or English message that drops the range or shows a raw `{start}`.** Expected: both placeholders present in both languages and the key parity guards green. Test: Task 3.

## File structure

- Create `packages/astro_core/lib/src/ephemeris/supported_date_range.dart`; modify `packages/astro_core/lib/astro_core.dart` (one `export`); create `packages/astro_core/test/ephemeris/supported_date_range_test.dart`.
- Create `packages/ephemeris_swiss/test/data_files_test.dart`; modify `packages/ephemeris_swiss/pubspec.yaml` (comment only).
- Modify `packages/shared_ui/lib/l10n/app_en.arb`, `app_he.arb`; regenerate `packages/shared_ui/lib/l10n/zodiann_localizations*.dart`; create `packages/shared_ui/test/l10n/range_copy_test.dart`.
- Create `docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md`.
- Task 6 (after approval of this plan; Notes lines only if Q6b is answered "apply", no criterion changed): the task files in the ownership table; unconditionally, `docs/development/TASKS.md` and `docs/PROGRESS.md`.

## Tasks

### Task 1: The central supported-range constant (test first)

**Files:** Create `packages/astro_core/lib/src/ephemeris/supported_date_range.dart`; modify `packages/astro_core/lib/astro_core.dart`; test `packages/astro_core/test/ephemeris/supported_date_range_test.dart`.

**Interfaces:**
- Consumes: `UtcRange` (`utc_range.dart`).
- Produces: `abstract final class SupportedDateRange` with `static final DateTime start`, `static final DateTime end`, `static final UtcRange range`, `static SupportedRangeSide classify(DateTime utc)` (throws `ArgumentError` if `!utc.isUtc`, like `UtcRange.contains`), and `enum SupportedRangeSide { before, inside, after }`. Pure Dart; no localization.

- [ ] **Step 1: Write the failing tests** in `supported_date_range_test.dart`: `start` equals `DateTime.utc(1900, 1, 1)` and `end` equals `DateTime.utc(2100, 12, 31, 23, 59, 59, 999, 999)`; `range == UtcRange(start, end)`; `classify(start)` is `inside` and `classify(start.subtract(Duration(microseconds: 1)))` is `before`; `classify(end)` is `inside` and `classify(end.add(Duration(microseconds: 1)))` is `after`; `classify(DateTime.utc(2100, 12, 31, 12))` is `inside` (a whole 2100-12-31); `classify(DateTime.utc(1899, 12, 31, 10))` is `before` (the UTC+14 local 1900-01-01 00:00 case); `classify(DateTime.utc(2101, 1, 1, 9))` is `after` (the UTC-10 local 2100-12-31 23:00 case); `classify(DateTime.utc(2000, 1, 1, 12))` is `inside`; `classify(DateTime(2000))` (local) throws `ArgumentError`; `range.contains(DateTime.utc(1900, 1, 1))` is true and `range.contains(DateTime.utc(1899, 12, 31, 12))` is false; and a fixture check reads `test/fixtures/reference_dates.json` (key `dates`) and asserts every instant from 1900-01-01T00:00Z onward is inside and the only instant outside is 1899-12-31T12:00Z.
- [ ] **Step 2: Run to verify failure.** `cd packages/astro_core && fvm dart test test/ephemeris/supported_date_range_test.dart`. Expected: FAIL, `SupportedDateRange` is not defined.
- [ ] **Step 3: Implement** `SupportedDateRange` and `SupportedRangeSide` in `supported_date_range.dart`, with a library doc comment that states the two ranges are different things (physical coverage 1800 to 2400 belongs to the adapter; this is the product range, 1900 to 2100, judged on the UTC instant after local-to-UTC conversion, Decision D2) and names the consumers. `range` is built from `start` and `end`; `classify` checks `isUtc` once (same `ArgumentError` style as `UtcRange`) and then uses `range.contains`. Export it from `astro_core.dart`.
- [ ] **Step 4: Run** `cd packages/astro_core && fvm dart test test/ephemeris/supported_date_range_test.dart`. Expected: PASS. Then `fvm dart test` in `packages/astro_core` and `fvm dart analyze --fatal-infos` there: all green, existing `ephemeris_port_contract_test.dart` unchanged.
- [ ] **Step 5: Commit** `git add packages/astro_core/lib/src/ephemeris/supported_date_range.dart packages/astro_core/lib/astro_core.dart packages/astro_core/test/ephemeris/supported_date_range_test.dart`; message `feat(ZOD-FND-011): add the central supported date range (1900 to 2100)`.

### Task 2: Pin the packaged data-file set (test first) and update the stale comment

**Files:** Create `packages/ephemeris_swiss/test/data_files_test.dart`; modify `packages/ephemeris_swiss/pubspec.yaml` (comment lines 24 to 26 only).

**Interfaces:**
- Consumes: the directory `packages/ephemeris_swiss/assets/ephe/`. `ephemeris_swiss` has **no** `astro_core` dependency (verified in its pubspec); this task does not add one and does not touch the pubspec dependencies.
- Produces: nothing for other tasks (a guard).

- [ ] **Step 1: Write the guard test** `data_files_test.dart`: the files in `assets/ephe/` are exactly `semo_18.se1` and `sepl_18.se1` (no neighbouring block, no other file); sizes are 1,304,771 and 484,061 bytes (the measured raw sizes, F1); test-local literals `productStart = DateTime.utc(1900)` and `productEnd = DateTime.utc(2100, 12, 31, 23, 59, 59, 999, 999)` (comment: must equal `SupportedDateRange`; Task 1's test pins that constant) and `nominalStart = DateTime.utc(1800)`, `nominalEnd = DateTime.utc(2400)` (comment: nominal, from the upstream block names, informational until EPH-002 measures the edges on a device, F9) satisfy `nominalStart` before `productStart` by at least 36,500 days and `productEnd` before `nominalEnd` by at least 100,000 days. Use a path relative to the package, as `packages/ephemeris_astronomy/test/reference_fixture_test.dart` does for its fixture. (If the owner prefers a real link instead of literals, the alternative is `astro_core` as a **dev** dependency, which then must pass `dependency_closure_test`; the literals are recommended.)
- [ ] **Step 2: Run, expecting PASS** (a guard over existing state, so there is no red phase): `cd packages/ephemeris_swiss && fvm dart test test/data_files_test.dart`. Then three mutation checks, restoring after each with `git checkout -- packages/ephemeris_swiss/assets/ephe` and deleting any dummy file: (a) add a dummy `sepl_19.se1`, expect FAIL on the exact-file-set assertion; (b) rename `sepl_18.se1`, expect FAIL; (c) truncate only `semo_18.se1`, expect FAIL on the size assertion. Record the three results in the commit body.
- [ ] **Step 3: Update the comment** in `packages/ephemeris_swiss/pubspec.yaml` to say FND-011 decided: keep the `_18` pair only (1800 to 2400), the product range is 1900 to 2100 (`SupportedDateRange`), no neighbouring blocks. Nothing else in the file changes; the regular dependency in `apps/astro_mobile/pubspec.yaml` stays.
- [ ] **Step 4: Run** `fvm dart test` in `packages/ephemeris_swiss` and, from the root, `fvm dart test test/architecture/pure_dart_test.dart test/architecture/dependency_closure_test.dart test/architecture/swisseph_vendored_test.dart`. Expected: PASS.
- [ ] **Step 5: Commit** the test and the pubspec comment; message `test(ZOD-FND-011): pin the packaged ephemeris data-file set`.

### Task 3: The two message strings, English and Hebrew (test first)

**Files:** Modify `packages/shared_ui/lib/l10n/app_en.arb`, `app_he.arb`; regenerate `packages/shared_ui/lib/l10n/zodiann_localizations.dart`, `zodiann_localizations_en.dart`, `zodiann_localizations_he.dart`; test `packages/shared_ui/test/l10n/range_copy_test.dart`.

**Interfaces:**
- Consumes: the `ZodiannLocalizations` pattern; callers format dates per L10-010 and digits per L10-012 and pass Strings.
- Produces: `String rangeOutsideSupported(String start, String end)` and `String get rangeDataUnavailable` on `ZodiannLocalizations`, read later by NFR-017, WHL-014/020 and others. Each key has an `@key` description; the placeholders are `String` with examples.

- [ ] **Step 1: Write the failing test** `range_copy_test.dart` in the style of `screen_copy_test.dart`: for en and he, `rangeOutsideSupported('1.1.1900', '31.12.2100')` contains both arguments and no `{`; `rangeDataUnavailable` is non-empty and contains no `{`; the English text starts with a capital letter and does not end with a stack of punctuation (sentence case); the Hebrew texts contain Hebrew letters. Registers `ZodiannLocalizations.delegate` per the app convention.
- [ ] **Step 2: Run to verify failure.** `cd packages/shared_ui && fvm flutter test test/l10n/range_copy_test.dart`. Expected: FAIL, the getters do not exist.
- [ ] **Step 3: Add the keys** to both ARB files (key parity): `rangeOutsideSupported` en "This date is outside the supported range ({start} to {end}). Choose a date within it." he "התאריך מחוץ לטווח הנתמך ({start} עד {end}). בחרו תאריך בתוך הטווח."; `rangeDataUnavailable` en "Position data for this date is not available on this device." he "נתוני המיקום לתאריך זה אינם זמינים במכשיר." Descriptions say: R-2, FND-011, `outside supported range` is shown for any moment outside 1900 to 2100 (user input) and `data unavailable` only when the data is missing inside the range (a defect); callers supply `start` and `end` already formatted. **Copy rule:** PROGRESS Architecture Conventions make `kit.js` the only source of UI copy, with owner-approved exceptions; `design-reference/zodiann/_source/kit.js` has no range or outside-range copy, so **both the English and the Hebrew are new text and need an owner-approved exception (Q5)**; the Hebrew is also my draft. **This task is gated on that approval: if the owner declines, Task 3 is dropped and criterion 2 is met by the copy recorded in the decision record (Task 4).** Criterion 2 is not ticked before the owner approves the copy. Run `fvm flutter gen-l10n` in `packages/shared_ui` to regenerate the committed output.
- [ ] **Step 4: Run** the test, then from the root `fvm dart run tool/check_l10n.dart` and `fvm dart test test/architecture`. Expected: PASS and no stale-output failure.
- [ ] **Step 5: Commit** the ARB files, the three generated files and the test; message `feat(ZOD-FND-011): add the outside-range and data-unavailable messages (en, he)`.

### Task 4: The decision record

**Files:** Create `docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md`.

**Interfaces:** Produces the document EPH-002, NFR-017, CRS-004, WHL-0xx, SQR-002 and XLS-017 read.

- [ ] **Step 1: Write the record** with these sections, in order: the decision (Option 2, date, owner); the two ranges and the exact bounds (D2); the data-file set and the size impact (F1) with the Android-only caveat; the boundary-behavior table above verbatim; the accuracy statement and the widening checklist; the consumer and enforcement map (F8, D5) with, per consumer, the task that owns it; the Excel cross-check (the 1900 limit is satisfied by the product range for every ephemeris date; the Square is not ephemeris-bound (F5); the export rule is XLS-017's; F7 recorded as an open item); a "Spec deviation" section (F10: spec line 368 versus the narrower product range; spec text unchanged); the proposed, **unapplied** `EphemerisPort`/`EphemerisFailure` wording for D3-A (exact doc-comment text for `coveredRange`, the `OutsideSupportedRange` subtype and the node exception); the message keys and their copy; and the open questions Q1 to Q6.
- [ ] **Step 2: Verify** every number in it against its source: F1 against spike section 4; F3 against `astronomy_ephemeris.dart:78-80`; F6 by reading `reference_dates.json`'s first and last instants again; every relative link in the record points at an existing file (list each target with `ls`).
- [ ] **Step 3: Commit** `git add docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md`; message `docs(ZOD-FND-011): record the coverage-range decision`.

### Task 5: Review and verification

- [ ] **Step 1: Independent whole-branch review** (`requesting-code-review`, a fresh reviewer): checks that the constant is the only product-range definition (D6), that nothing in `EphemerisPort`, `EphemerisFailure`, any adapter or any task file changed outside Task 6, that no claim of validated accuracy outside 1899-12-31T12:00Z to 2100-01-01T12:00Z exists, and that the boundary table matches the tests.
- [ ] **Step 2: Resolve findings test-first** (defects) and rerun.
- [ ] **Step 3: Verify** (`verification-before-completion`), recording the commands and results with the branch head: `fvm dart test` in `astro_core` and `ephemeris_swiss`; `fvm flutter test` in `shared_ui` (if Task 3 ran); `fvm dart run tool/check_l10n.dart`; `fvm dart test test/architecture`; `fvm dart run melos run lint` and `fvm dart run melos run test`. The CI jobs (`Core`, `Lint`, `Full suite`) cannot run locally; they run on the PR. Expected: all local commands pass; the pre-existing suites are unchanged.

### Task 6: Ownership hand-offs and documentation (the Notes lines are conditional on Q6)

No acceptance criterion, status, scope or dependency of any other task changes. The table is the proposed hand-off list. **Whether the Notes lines are written into the other task files is Q6:** recommended, they live only in the decision record's consumer map (Task 4) and a short Notes line is added to a task file when that task is planned. Only FND-011's own criteria ticks and the `TASKS.md` and `PROGRESS.md` updates are unconditional.

| Task | Note to add | Why |
|---|---|---|
| ZOD-EPH-002 | Implements D3-A (if approved) and the boundary table; keeps the per-call `usedSwissEphemerisFiles` guard; measures the physical edge instants on a device (F9); owns the ΔT-forecast flag | Exact boundary behavior lives here |
| ZOD-EPH-003, ZOD-EPH-004 | The product range also applies to Moshier and the backup; the backup's range is narrower (Q2) | One range for every source |
| ZOD-CRS-004 | Core rejects From/To outside `SupportedDateRange` with a typed error; the solver never probes beyond To | Core, not UI, enforces |
| ZOD-WHL-011, 012, 013, 014, 016, 017, 019, 020, 022, 023 | Each input route validates the converted UTC instant; playback and steps stop at the edge; Now and the initial state handle a clock outside the range | F8 |
| ZOD-NFR-017 | The out-of-range banner uses `rangeOutsideSupported`; data-missing uses `rangeDataUnavailable`; ΔT banner threshold stays its own | D4 |
| ZOD-SQR-002 (and SQR-004) | The Square anchor is **not** limited to 1900 to 2100 (pending Q3); only the Excel export rule applies | F5 |
| ZOD-XLS-017 (and XLS-001/012 for F7) | The pre-1900 rejection is export-only; decide the floor question (F7) | Excel finding |
| ZOD-TST-001 | May add reference instants up to 2100-12-31 (add-only file, bump `version`), pending Q2 | F6 |
| ZOD-ABT-003, ZOD-REL-002 | Display the range from `SupportedDateRange`; REL-002 re-checks the data-file size; iOS size stays ZOD-IOS-009 | One source, F1 |
| ZOD-FND-011 | Criteria ticked with evidence; the SQ-10 citation corrected to SQ-5 only if the owner approves (F4) | Traceability |
| `docs/development/TASKS.md`, `docs/PROGRESS.md` | Status, plan path, decision, verification (branch head) | Skill step 7 |

- [ ] **Step 1:** Tick FND-011's criteria only with the evidence from Tasks 1 to 5 (criterion 2 only after the Q5 copy approval) and update `TASKS.md` and `PROGRESS.md`; apply the other tasks' Notes lines **only if Q6 is answered "apply"**. **Step 2:** check every relative link in the files changed (list each target with `ls`); commit with explicit staging paths; then push and open the PR per the skill, and stop for the owner's merge decision.

## Acceptance criteria mapping (FND-011, unchanged)

1. *A documented date range is chosen and recorded:* Tasks 1 and 4 (constant plus decision record).
2. *The "outside range" message text exists and is ready for translation (feeds ZOD-L10):* Task 3 (en + he in the ARB files, key parity and generated output green; Hebrew pending owner review); **gated on Q5**: if the owner declines, the copy is recorded in the decision record (Task 4) and criterion 2 is met by that; not ticked before approval.
3. *The chosen range is cross-checked against the Excel pre-1900 limitation:* Task 4 (every supported date is at or after 1900-01-01; the limit concerns the square export only; F7 recorded).

## Unresolved questions for the owner

- **Q1. Contract (D3).** Approve A (Swiss `coveredRange` = physical; a decorator returns a new sealed `OutsideSupportedRange` for all bodies including the node; amend the `coveredRange` doc comment), or choose B (no contract change; the distinction becomes internal)? Nothing is edited until you decide; EPH-002 implements the choice.
- **Q2. The last 364 days and the backup.** The ACC-1 dataset ends at 2100-01-01T12:00Z and the backup's range ends there too, while the approved range ends 2100-12-31. Choose: (a) add reference instants to 2100-12-31 in ZOD-TST-001 (recommended) and accept that the backup returns `OutOfCoveredRange` for 2100-01-01T12:00Z onwards if ever selected; (b) end the product range at 2100-01-01T12:00Z (I did not change it); or (c) keep as approved and document the gap only.
- **Q3. Square anchors.** The Square never calls the ephemeris. Confirm anchors stay unrestricted except by Excel's export rule (recommended), or that you want the product range applied to the Square as well.
- **Q4. Excel floor (F7).** Keep the export limit as the spec words it (anchor before 1900-01-01 rejected) or move the floor to 1900-03-01 because of Excel's phantom leap day? Decided in XLS-017/XLS-001 after a three-application check; the question is raised here, not answered.
- **Q5. New copy and the SQ-10 citation.** The project's copy rule is kit.js-only with owner-approved exceptions, and kit.js has no range copy. Approve the two new messages (English and Hebrew, drafts in Task 3, Hebrew edited as you wish) as an exception, or decline and Task 3 is dropped with the copy kept in the decision record only. Also approve correcting "SQ-10" to "SQ-5" in the FND-011 task file (F4), or leave it.
- **Q6. Spec row and the hand-off Notes.** (a) Spec line 368 ("According to the coverage of the data files that are packaged") no longer matches the narrower product range (F10): leave the spec as written with the deviation recorded (recommended), or reword it (your edit). (b) Write the hand-off Notes into about 25 other task files now (Task 6), or keep them only in the decision record and add each when that task is planned (recommended, since you asked for them documented and not applied).

## Out of scope

Any adapter, `EphemerisPort`, `EphemerisFailure` or decorator code (EPH-002); the date-picker, banner and filter UI (WHL, NFR-017, UI-012); the crossing API (CRS-004); the Excel export (XLS); new data blocks; the ΔT warning threshold; iOS size and iOS verification (ZOD-IOS-001, -009); the ZOD-TST-001 vs ΔT decision; editing the specification.

## Execution

Sequential, native (`executing-plans`): each task consumes the previous one and the whole scope is small. Independent whole-branch code review by a fresh reviewer (Task 5) is mandatory.

## Plan review

Reviewer: `plan-reviewer`, two rounds (static review; no tests run). Round 2 was a focused review of the revision at `d5e70f6`.

**Round 1: needs user decision.**

| ID | Severity | Finding | Done |
|---|---|---|---|
| C1 | Critical | Task 2 imported `astro_core`, which `ephemeris_swiss` does not depend on | Applied: test-local literals, no dependency edge, stated in Global Constraints and Task 2 |
| I1 | Important | Spec line 368 ("coverage of the data files that are packaged") conflicts with the narrower product range | Applied: Finding F10, "Spec deviation" section in Task 4, question Q6a |
| I2 | Important | Task 6 applied ownership Notes to about 25 task files although the owner asked for "documented, not applied" | Applied as a conditional: Task 6 and Q6b, recommended default is the decision record only |
| I3 | Important | New copy versus the kit.js-only copy rule | Applied: Task 3 gated, Q5, criterion 2 not ticked before approval |
| I4 | Important | Vague fixture assertion in Task 1 | Applied: concrete assertions |
| I5 | Important | Commands did not follow the `fvm` convention | Applied (one residual, see round 2) |
| I6 | Important | Task 2 had no real RED step | Applied: PASS expected plus three mutation checks |
| M1 to M5 | Minor | Link-check command, node-row note, `classify` detail, F5 reproducibility, architecture tests named | Applied |

**Round 2: approve after corrections.** Critical none. Important: one bare `dart` command in Task 1 Step 2 (applied). Minor: "Q1 to Q5" now Q1 to Q6; criterion 2 mapping and the File structure Task 6 bullet made conditional; wrong precedent path for `reference_fixture_test.dart` (all applied). Task 2 margins verified (36,524 and 109,207 days against the 36,500 and 100,000 floors). No new owner decision.

**Open items for the owner:** Q1 (contract A or B), Q2 (the last 364 days of 2100 and the backup's range), Q3 (Square anchors), Q4 (Excel floor), Q5 (new copy as an exception to kit.js-only, the SQ-10 citation), Q6 (spec row 368; whether to write hand-off Notes into other task files now).
