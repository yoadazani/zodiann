# ZOD-TST-012 — T-GAN-4 Gann Date-Mapping Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: 2 rounds, Approve), approved and implemented 2026-11-12 (see PROGRESS.md) · **Branch:** `task/ZOD-TST-012-gann-date-mapping-suite` (from `main` @ `8655a9d`) · **Written:** 2026-11-12

**Goal:** Independently verify ZOD-GAN-003's date mapping (T-GAN-4). The anchor cell is the anchor date, and today's cell is marked exactly, at daylight-saving boundaries and in leap years. Behaviour follows the decided time-zone rule (R-4's accepted one-hour jump), and a mutation proof shows the suite catches a wrong date in a single cell.

**Architecture:**
- **Test-only deliverable:** one suite, `packages/gann_core/test/accuracy/t_gan_4_date_mapping_test.dart`, following the "Accuracy tests" convention in PROGRESS.md. There are no production changes.
- **Expectations are independent of production.** They come from:
  - literal dates and times;
  - a test-local Gregorian calendar (`_daysInMonth`, `_nextDay`, `_dayNumber`), self-checked against literals;
  - test-local fake zones that mirror **real 2026 DST rules** for Israel (positive offset) and New York (negative offset);
  - plain `DateTime` microsecond arithmetic.
- Production is imported with a `show` list of the code under test only.

**Tech Stack:** Dart 3.14, `package:test` (existing dev dependency). No new dependencies.

**Spec:**
- `docs/development/testing-qa/ZOD-TST-012-author-the-gann-date-mapping-test-suite-t-gan-4.md` (Notes dated 2026-11-12)
- `assets/zodiann-specification.md`: T-GAN-4 (line 661), R-4 (line 731), "Dates" (lines 338–340), planning constraint (line 74), NFR-A3
- `docs/development/computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md` Notes: the decided time-zone rule

## Product-owner decisions already in force (2026-11-12)

1. **TST-012 owns the dedicated T-GAN-4 verification** (GAN-003's criterion points here). Expected dates come from an independent source, never from production helpers, and the suite needs a mutation proof (TST-012 Notes).
2. **The time-zone rule (GAN-003 Notes):**
   - Date-and-time cells are absolute `stepHours` steps shown in the device zone, so the one-hour jump at DST is visible and not corrected.
   - Dates mode is calendar-day arithmetic on the anchor's own date.
   - Use an injected fake zone with a known DST transition (TST-012 Notes).

No new product decisions are needed.

## Global Constraints

- **Test-only.** No file under `lib/` changes. Pure Dart; the ARCH-2 guard stays green.
- **Independence:** the suite imports `package:gann_core/gann_core.dart` with `show cellDate, cellMoment, localWallClock, todayCellInDatesMode, nowCellInDateTimeMode, LocalTimeZone, OffsetDateTime`.
  - **Not** imported: `FixedOffsetTimeZone`, `DeviceTimeZone`, `daysAfterAnchor` / `hoursAfterAnchor`, `formatCellDate` / `formatCellTime` (T-FMT-1 is TST-013), and spiral or highlight APIs.
  - Expected values never call production. In particular, `cellDate` / `cellMoment` results are never used to compute another expectation.
- **No machine-zone dependence:** all zones are test-local fakes; `DeviceTimeZone` is not used.
- Follow `docs/PROGRESS.md` → Architecture Conventions ("Square of Nine dates", "Accuracy tests").
- **Out of scope:**
  - format strings (TST-013);
  - UI today marking and live update (ZOD-SQR-009, ZOD-SQR-008), and the 3,721-cell cap message (SQR tasks);
  - the anchor-field offset capture (SQR-002).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Location | `packages/gann_core/test/accuracy/t_gan_4_date_mapping_test.dart` | PROGRESS "Accuracy tests" convention (`test/accuracy/`); its first `gann_core` use |
| "Real time zone" | Two test-local fakes mirroring the real 2026 rules:<br>**`_Israel2026`**: +02:00 until 2026-03-27T00:00Z (Fri 02:00 → 03:00); +03:00 until 2026-10-24T23:00Z (Sun 25.10, 02:00 → 01:00); then +02:00.<br>**`_NewYork2026`**: −05:00 until 2026-03-08T07:00Z (Sun 02:00 → 03:00); −04:00 until 2026-11-01T06:00Z (Sun 02:00 → 01:00); then −05:00.<br>Each throws `StateError` unless `DateTime.utc(2026) <= utc < DateTime.utc(2027)`, so it can't silently model a year it doesn't know | The task asks for "a known DST transition in at least one real time zone". The negative-offset zone is where the local date lags the UTC date (the late-evening cases). Deterministic on any machine |
| Fixed zones (leap cases) | Test-local `_Fixed(offsetMinutes)` | Leap cases are about the calendar, not DST; avoids importing `FixedOffsetTimeZone` |
| Independent calendar | `_isLeap(y)` (Gregorian 4/100/400), `_daysInMonth(y, m)`, `_nextDay((y, m, d))`, `_dayNumber((y, m, d))` (Hinnant's days-from-civil), all on records, never `DateTime` date arithmetic. **Self-checked by literals** (`_isLeap` 2024/2000 true, 2026/2100/1900 false; `_daysInMonth(2024, 2) == 29`, `(2100, 2) == 28`; `_dayNumber((1970, 1, 1)) == 0`, `((2000, 3, 1)) == 11017`) | An oracle that can itself be wrong must be pinned first. Records keep it free of `DateTime`'s own normalization |
| "No cell skipped or duplicated" | **Dates mode:** over a full 61×61 square (3,721 cells), consecutive cells are exactly the independent `_nextDay` sequence. **Date-and-time mode:** consecutive instants are exactly `stepHours` apart in absolute time (no skip or duplicate). The displayed local clock jumps once, by +1 h (spring) or −1 h (autumn), at the transition only | R-4's risk restated precisely: absolute steps never skip or duplicate; the display shows the documented jump once |
| R-4's displayed duplicate or skip | With `stepHours: 1`: autumn shows **01:00 twice**, and spring never shows **02:00**, in both zones. Asserted as documented behaviour | NFR-A3 / R-4 "accepted, not fixed": the suite pins what the user sees |
| Today-marking sweep | Every 30 min over 72 h around each transition. Dates mode: expected = `_dayNumber(local date) − _dayNumber(anchor date) + 1`, with the local date taken from the fake's offset plus `DateTime` field reads. Date-and-time mode: expected = `(now − anchorInstant).inMicroseconds ~/ (stepHours·3.6e9) + 1`, using a literal anchor instant | Exactness at every half hour, not just spot checks. Literal spot checks pin the sweep's oracle |

## File Structure

```
packages/gann_core/test/accuracy/
  t_gan_4_date_mapping_test.dart    T-GAN-4: independent calendar and fake zones; DST, leap, today marking
```

## Review Focus

1. **A self-validating oracle:** if the expected sequence were built with `cellDate` or `DateTime(y, m, d + k)` arithmetic, a shared bug would hide. The record-based `_nextDay` / `_dayNumber` are pinned by literal self-checks, and the `show` list makes reusing production helpers a compile error. (Task 1.)
2. **A local date behind UTC at night** (negative offset): an anchor of 30.10 23:30 −04:00 has a UTC date of 31.10. Its cell 1 must be 30.10, and "today" at 03:59Z on 31.10 is still cell 1. (Task 1.)
3. **A single wrong cell inside a large square** (T-GAN-4's stated failure): only a full-square comparison finds one bad date among 3,721. Mutants M5 and M6 inject exactly this. (Tasks 1–2.)
4. **Century leap rules:** 2100 has no Feb 29, while 2000 has one. A "divisible by 4" error passes every 2024 test. (Task 2.)
5. **Today exactly at a block or midnight boundary across DST:** 01:59Z vs 02:00Z for the date-and-time block, and 03:59Z vs 04:00Z for New York local midnight. Off-by-one floor/ceil errors show only there. (Task 1.)

## Reference values (verified by a scratch run against `main` @ `8655a9d`)

| Case | Input | Expected |
|---|---|---|
| D-IL-dates | anchor `2026-03-20T00:00+02:00`, `cellDate` n = 1, 7, 8, 9, 81 | 20.3.2026, 26.3, 27.3 (DST day), 28.3, 8.6.2026 |
| D-NY-dates | anchor `2026-10-30T23:30-04:00`, n = 1, 2, 3, 4, 3721 | 30.10.2026, 31.10, 1.11 (DST day), 2.11, 5.1.2037 |
| DT-IL-spring | anchor `2026-03-26T20:00+02:00` (instant 18:00Z), step 4, `_Israel2026`, n = 1–4 | 26.3 20:00, 27.3 00:00, 27.3 **05:00**, 27.3 09:00 |
| DT-IL-autumn | anchor `2026-10-24T20:00+03:00` (17:00Z), step 4 | 24.10 20:00, 25.10 00:00, 25.10 **03:00**, 25.10 07:00 |
| DT-NY-spring | anchor `2026-03-07T20:00-05:00` (2026-03-08T01:00Z), step 4 | 7.3 20:00, 8.3 00:00, 8.3 **05:00**, 8.3 09:00 |
| DT-NY-autumn | anchor `2026-10-31T20:00-04:00` (2026-11-01T00:00Z), step 4 | 31.10 20:00, 1.11 00:00, 1.11 **03:00**, 1.11 07:00 |
| R4-IL-autumn | anchor `2026-10-24T23:00+03:00`, step 1, n = 1–5 | 24.10 23:00, 25.10 00:00, **01:00, 01:00**, 02:00 |
| R4-IL-spring | anchor `2026-03-26T23:00+02:00`, step 1, n = 1–4 | 26.3 23:00, 27.3 00:00, 01:00, **03:00** |
| R4-NY-spring | anchor `2026-03-07T23:00-05:00`, step 1, n = 1–4 | 7.3 23:00, 8.3 00:00, 01:00, **03:00** |
| R4-NY-autumn | anchor `2026-10-31T23:00-04:00`, step 1, n = 1–5 | 31.10 23:00, 1.11 00:00, **01:00, 01:00**, 02:00 |
| Today-IL-dates | anchor D-IL-dates; now `2026-03-26T22:30Z` / `2026-03-27T21:30Z` | 8 / 9 (both 00:30 local, either side of the switch) |
| Today-NY-dates | anchor D-NY-dates; now `2026-10-31T03:00Z` / `03:59Z` / `04:00Z` / `2026-11-01T04:30Z` / `2026-11-02T04:30Z` / `2026-11-02T05:30Z` | 1 / 1 / 2 / 3 / 3 / 4 |
| Today-IL-datetime | anchor DT-IL-spring; now `2026-03-27T01:59Z` / `02:00Z` / `03:00Z` | 2 / 3 / 3 |
| Today-travel-dates | anchor D-IL-dates, zone `_NewYork2026`; now `2026-03-20T16:00Z` (NY 20.3 12:00) | 1 (the anchor's own date 20.3, not NY's 19.3) |
| Today-NY-before | anchor D-NY-dates, `_NewYork2026`; now `2026-10-30T02:00Z` (NY 29.10 22:00) | `null` |
| DT-travel | anchor DT-IL-autumn shown in `_NewYork2026`, cell 1 | 24.10 13:00 |
| Leap-dates | `2024-02-25` n = 1, 5, 6 · `2026-02-25` n = 4, 5 · `2100-02-27` n = 2, 3 · `2000-02-28` n = 2, 3 (all `T00:00+02:00`) | 25.2.2024, 29.2.2024, 1.3.2024 · 28.2.2026, 1.3.2026 · 28.2.2100, 1.3.2100 · 29.2.2000, 1.3.2000 |
| Leap-full | anchors `2023-12-01T00:00+02:00` and `2096-01-01T00:00+02:00`, 3,721 cells | last cells 6.2.2034 and 10.3.2106; full sequence = `_nextDay` chain |
| Leap-datetime | anchor `2024-02-28T16:00+02:00`, step 4, `_Fixed(120)`, n = 1, 3, 8, 9 | 28.2.2024 16:00, 29.2 00:00, 29.2 20:00, 1.3 00:00 |
| Leap-today | anchor `2024-02-01T00:00+02:00`, `_Fixed(120)`: now `2024-02-29T10:00Z` / `2024-03-01T10:00Z` / `2024-02-28T22:30Z`; anchor `2026-02-01`: now `2026-03-01T10:00Z` | 29 / 30 / 29 / 29 |

## Tasks

TDD note: production already exists, so each new test is expected to **pass** on its first run. The RED evidence for this suite is the mutation proof (Task 2): each mutant must turn the suite red.

### Task 1: Independent oracle, anchor cell, DST cases and today marking

**Files:** create `packages/gann_core/test/accuracy/t_gan_4_date_mapping_test.dart`.

**Interfaces:** Consumes GAN-003's `cellDate(OffsetDateTime, int)`, `cellMoment(OffsetDateTime, int, {required int stepHours})`, `localWallClock(DateTime, LocalTimeZone)`, `todayCellInDatesMode(OffsetDateTime, DateTime, LocalTimeZone)` and `nowCellInDateTimeMode(OffsetDateTime, DateTime, {required int stepHours})`.

- [ ] **Step 1: Write the header and helpers.**
  - Write a header comment stating the independence rules: the `show` list, the literal and test-local oracle, the fake zones that mirror the real 2026 rules, and that the file never calls `DeviceTimeZone`.
  - Build anchors with `OffsetDateTime.parse('<literal>')` (seconds are optional; the strict parser accepts them).
  - Write the zones `_Israel2026`, `_NewYork2026` and `_Fixed`, each a test-local `LocalTimeZone` that rejects non-UTC input. The two 2026 zones throw `StateError` outside 2026.
  - Write the calendar helpers `_isLeap`, `_daysInMonth`, `_nextDay` and `_dayNumber` on `(int, int, int)` records.
  - Write `_dateOf(DateTime carrier) → (y, m, d)` and `_clockOf(utc, zone) → (y, m, d, hh, mm)`, built from `utc.add(Duration(minutes: zone.offsetMinutesAt(utc)))` field reads, **not** from `localWallClock`.
- [ ] **Step 2: Write the tests, grouped as follows.**
  - `'oracle self-check'`: the literal checks from the design table.
  - `'anchor cell is the anchor date'`:
    - in dates mode, cell 1 of D-IL-dates, D-NY-dates and the four Leap-dates anchors (2024-02-25, 2026-02-25, 2100-02-27, 2000-02-28) equals the literal anchor date;
    - in date-and-time mode, cell 1 of each DT anchor equals its literal anchor instant (for example `DateTime.utc(2026, 3, 26, 18)`), and its `localWallClock` in the matching zone shows the anchor's literal wall time.
  - `'dates mode across DST: calendar days, none skipped or duplicated'`:
    - the D-IL-dates and D-NY-dates literals;
    - for each of the two anchors, all 3,721 cells equal the `_nextDay` chain from the literal anchor date.
  - `'date-and-time mode across DST: the documented one-hour jump'`:
    - the four DT literals, compared through `localWallClock` in the matching fake;
    - for each, over 169 cells (13×13): consecutive `cellMoment`s differ by exactly `Duration(hours: 4)`;
    - `localWallClock(cellMoment(a, n + 1, stepHours: 4), zone).difference(localWallClock(cellMoment(a, n, stepHours: 4), zone)).inMinutes` (differences of the UTC-flagged wall-clock carriers) is 240 for every pair except exactly one: 300 in spring, 180 in autumn. This goes through production's display path; `_clockOf` is used only in the sweep oracles.
  - `'R-4: with 1-hour steps the transition hour shows twice or not at all'`: the four R4 literals.
  - `'today is marked exactly across DST'`:
    - the Today-IL-dates, Today-NY-dates, Today-IL-datetime, Today-travel-dates, Today-NY-before and DT-travel literals;
    - the sweeps from the design table, for D-IL-dates and D-NY-dates (dates mode) and for DT-IL-spring and DT-NY-autumn (date-and-time mode, step 4): every 30 min from 36 h before to 36 h after the transition instant;
    - nows before the anchor expect `null`.
- [ ] **Step 3: Run the suite.**
  - Run: `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy`
  - Expected: all pass. If a test fails, re-derive the value by hand from the literal rules.
    - If the test or oracle is wrong, fix it and record a ruling.
    - If production is wrong, stop and report it to the user as a GAN-003 defect.
    - Never edit `lib/` in this task, and never change an expectation to match production.
- [ ] **Step 4: Run the gates.**
  - Run: `fvm dart run melos run lint` and `fvm dart run melos run test`.
  - Expected: exit 0.
- [ ] **Step 5: Commit** `test(ZOD-TST-012): T-GAN-4 independent oracle, DST and today-marking cases`.

### Task 2: Leap-year cases and mutation proof

**Files:** modify `packages/gann_core/test/accuracy/t_gan_4_date_mapping_test.dart`.

- [ ] **Step 1: Add the group `'leap years: Feb 29 present exactly when Gregorian rules say'`.**
  - The Leap-dates literals.
  - Leap-full: each of the two anchors' 3,721 cells equals the `_nextDay` chain, with literal last cells.
  - The Leap-datetime literals, through `localWallClock` with `_Fixed(120)`.
  - The Leap-today literals.
- [ ] **Step 2: Run the suite and the gates** (same commands). Expected: all pass, exit 0.
- [ ] **Step 3: Mutation proof.**
  - Before mutating, copy `packages/gann_core/lib/src/dates/cell_values.dart` to the session scratch directory.
  - Apply each mutant, then run `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy` (the Task 1 Step 3 command; never a bare `dart`, which is the wrong SDK on PATH).
  - Confirm **test failures, not compile errors**.
  - Copy the file back, then confirm that `git diff --exit-code -- packages/gann_core/lib` exits 0.
  - Record the failing-test counts.

  | # | Mutant | Must fail |
  |---|---|---|
  | M1 | date-and-time adds to `anchor.wallClock` instead of `anchor.instant` | DT literals, the anchor-instant test |
  | M2 | dates mode uses the UTC date of `anchor.instant` | D-NY-dates (30.10 → 31.10) |
  | M3 | today (dates mode) uses the UTC date of `nowUtc` | Today-NY-dates, Today-IL-dates, sweeps |
  | M4 | today (dates mode) drops the `+ 1` | every today literal |
  | M5 | single wrong cell: `cellDate` returns 1.3 for any Feb 29 | Leap-dates, Leap-full |
  | M6 | single wrong cell: `cellDate` returns 28.3.2026 for 27.3.2026 (the DST day) | D-IL-dates, full-square chain |
  | M7 | date-and-time today rounds up: `(elapsedHours + stepHours − 1) ~/ stepHours + 1` | Today-IL-datetime (01:59Z), sweeps |
  | M8 | `localWallClock` ignores DST: `zone.offsetMinutesAt(DateTime.utc(2026))` | DT-*, R4-*, the jump-count check |
  | M9 | today (dates mode) derives the anchor date as `localWallClock(anchor.instant, zone)` | Today-travel-dates |

- [ ] **Step 4: Commit** `test(ZOD-TST-012): T-GAN-4 leap-year cases; mutation proof M1–M9`, with the mutant results in the body.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch code review (`requesting-code-review`, fresh reviewer on the most capable model). Re-grade the findings and fix the important ones test-first.
- [ ] **Step 2: Documentation.**
  - The TST-012 task file: set `Status: Done` and tick both criteria.
  - Set the `TASKS.md` row to Done.
  - In `docs/PROGRESS.md`:
    - completed row, verification table and Current / Next task;
    - extend the "Accuracy tests" convention: `gann_core` suites live in `test/accuracy/` as well; DST cases use test-local fakes mirroring real rules, never the machine zone;
    - add a "Carry into TST-013" note: use the same independence pattern.
  - Leave `TASKS.md` §6.4 R-4 unchanged (it has no status column).
- [ ] **Step 3:** Commit, push, open a PR, then record the PR link (`docs(ZOD-TST-012): record PR link`).

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| The DST-boundary case passes with the documented one-hour jump for date-and-time mode (R-4's accepted tradeoff), and with dates-mode calendar-day arithmetic unaffected by DST | Task 1: DT literals (05:00 / 03:00) in two real-rule zones; one jump in 169 cells; the R-4 duplicate/skip literals; full 3,721-cell `_nextDay` chains across both transitions; mutants M1, M2, M6, M8 |
| The leap-year case correctly includes Feb 29 without an off-by-one | Task 2: Leap-dates (2024, 2000 yes; 2026, 2100 no), full chains across 2024–2034 and 2096–2106, Leap-datetime and Leap-today literals; mutants M4, M5 |
| (T-GAN-4) The anchor cell is the anchor date; today's cell is marked exactly | Task 1 anchor-cell group (incl. the negative-offset late-evening anchor); today literals and 30-min sweeps; mutants M3, M4, M7, M9 |

## Risks

- **Oracle error:** the test-local calendar could share a misconception with production. Mitigation: literal self-checks, and Hinnant's algorithm is structurally unlike `DateTime`'s.
- **Fake-zone drift from reality:** the fakes encode the 2026 rules as constants. Their transition instants are cited in the header (Israel: Friday before the last Sunday of March / the last Sunday of October; US: the second Sunday of March / the first Sunday of November). They only need to be *a* real transition, not every year's.
- **Runtime:** 2 × 3,721 + 2 × 3,721 cells, plus sweeps of about 4 × 145 instants. Well under a second.

## Plan review

**Round 1: Approve after corrections.** The reviewer re-derived every reference value and DST instant independently, and all were correct.
- **C1 (Critical), applied.** The mutation command used a bare `dart` (SDK 3.6 on PATH). It now uses the `fvm dart run melos exec --scope=gann_core` command.
- **I1 (Important), applied.** The jump-count check used the test-local `_clockOf`, so M8 could not fail it. It now goes through production `localWallClock(cellMoment(…))`.
- **I2 (Important), applied.** No test caught re-deriving the anchor date through the zone. Added Today-travel-dates, Today-NY-before and DT-travel, plus mutant M9.
- **Minors M1–M6, all applied:**
  - the restore procedure;
  - the `StateError` bound;
  - the failure guidance;
  - SQR-009/008 named as out-of-scope owners;
  - the R-4 row left unchanged;
  - anchors built with `OffsetDateTime.parse`.

**Round 2: Approve.** All round-1 corrections were verified, including the new literals. M9 is caught by Today-travel-dates and by no other test.
- Minor M1 (the jump-difference wording, now `.difference(...).inMinutes`) and M2 (the leap anchors named), both applied. M3 is this record.
- No open items, no user decisions.

