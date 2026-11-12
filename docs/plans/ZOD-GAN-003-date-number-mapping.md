# ZOD-GAN-003 — Gann Date/Number Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-GAN-003-date-number-mapping` · **Written:** 2026-11-12

**Goal:** Map a Square of Nine cell's spiral position `n` to the value it displays in each mode (number, calendar date, or date and time in fixed hour steps), find "today's" cell, and format dates as `d.m.yy` and times as `HH:MM`. The mapping follows the spec's "Dates" rules and the product owner's time-zone decision.

**Architecture:**
- Pure functions in `packages/gann_core/lib/src/dates/`:
  - Dates mode uses calendar arithmetic on the anchor's own calendar date, so DST and travel never shift it.
  - Date-and-time mode steps in absolute time and converts to the device's local wall clock through an **injected `LocalTimeZone`**.
  - "Now" is a parameter, not a clock read.
- Everything is deterministic and unit-testable regardless of the machine's zone or clock.

**Tech Stack:** Dart 3.14 (`DateTime`, which uses the device's zone database for `toLocal`). No new dependencies.

**Spec:**
- `docs/development/computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md` (amended 2026-11-12)
- `assets/zodiann-specification.md`: "Dates" (full section), SQ-2 … SQ-7, T-GAN-4, T-FMT-1, NFR-A3, DATA-4, R-4, and the line 74 planning constraint
- `design-reference/zodiann/MASTER.md` §8.2 ("Content" row) and `screens/02-square-of-nine_{dates,datetime}_*.png`

## Product-owner decisions (2026-11-12)

1. **Cycle resolution** (same as EPH-001 / GAN-001 / GAN-002). "T-GAN-4 passes" and "T-FMT-1 passes" were amended to "covered by GAN-003's own unit tests; dedicated T-GAN-4 / T-FMT-1 tracked by ZOD-TST-012 / ZOD-TST-013". The test tasks' notes carry the independence and mutation-proof rules.
2. **Time zone (resolves the spec's open question; NFR-A3's "one rule"):**
   - Date-and-time cells step in **absolute time** and are shown in the **device's current local time zone**. Across DST the displayed hour visibly jumps by one hour, documented and not "corrected".
   - **Today's cell** uses the device zone and the current moment.
   - **Dates mode** uses the anchor's own calendar date plus whole days.
   - The anchor's saved offset (DATA-4) preserves the exact anchor instant.

## Global Constraints

- Pure Dart in `gann_core` (ARCH-2), no new dependencies. Follow `docs/PROGRESS.md` → Architecture Conventions (data model, spiral, highlights).
- **The rules**, exactly:
  - Numbers mode: `value(n) = n`.
  - Dates mode: `date(n) = anchor date + (n − 1)` calendar days, built as a local date (year, month, day + n − 1).
  - Date-and-time mode: `moment(n) = anchor instant + stepHours·(n − 1)` hours in absolute time. `stepHours` comes from `SquareConfig` (default 4; SET-004 makes it editable).
  - Today's cell, dates mode: calendar days from the anchor date to today's local date, + 1.
  - Today's cell, date-and-time mode: ⌊(now − anchor instant) / stepHours⌋ + 1.
- **`n` is the spiral position** (1 = center), matching the GAN-002 convention.
- **Formats:**
  - Date: `d.m.yy`, with no leading zero on day or month and a 2-digit year (`4.1.22`, `31.12.99`, `5.1.05`).
  - Time: `HH:MM`, 24-hour, zero-padded (`04:00`).
- Out of scope:
  - The anchor field, buttons, "Show up to today" and the size expansion (→ SQR-002/004).
  - The today border and tag (→ SQR-008/009).
  - Persisting the anchor (→ DAT-009).
  - The Excel export's time handling (spec line 256: "the file has no time zone" → XLS-*).
  - Localized weekday/month names (→ L10).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Time-zone abstraction | `abstract interface class LocalTimeZone { int offsetMinutesAt(DateTime utc); }`. Implementations: `DeviceTimeZone` (const; offset of `DateTime.fromMicrosecondsSinceEpoch(utc.microsecondsSinceEpoch).timeZoneOffset`) and `FixedOffsetTimeZone(int offsetMinutes)` | The device zone is the decided rule. Injecting it makes DST behaviour testable with a fake zone. `FixedOffsetTimeZone` serves tests and future consumers |
| Calendar date carrier | A date is returned as a **UTC-flagged `DateTime` at 00:00** holding the calendar fields (`DateTime.utc(y, m, d)`), documented as date-only | No new type. `DateTime.utc` normalises month and leap-year overflow (Feb 29) without any zone involvement |
| Wall clock | `DateTime localWallClock(DateTime utcInstant, LocalTimeZone zone)` returns a UTC-flagged `DateTime` holding the local fields (instant + offset), like `OffsetDateTime.wallClock` | One convention for "local fields" across `gann_core` |
| "Now" | Passed in as `DateTime nowUtc` | Pure and deterministic; the UI supplies `DateTime.now().toUtc()` |
| Before the anchor | The today-cell functions return `null` when today or now is before the anchor | SQ-6 shows a message instead. `null` lets the UI do that, with no exception |
| Range | `n ≥ 1`, otherwise `ArgumentError`. A result outside `DateTime`'s range → `ArgumentError`. `stepHours ≥ 1`. All `DateTime` inputs must be UTC (`ArgumentError` otherwise) | Same validation conventions as FND-012 / GAN-001 |

### API (`packages/gann_core/lib/src/dates/`)

- `local_time_zone.dart`: `LocalTimeZone`, `DeviceTimeZone`, `FixedOffsetTimeZone`.
- `cell_values.dart`:
  - `int cellNumber(int n)` (numbers mode; = n)
  - `DateTime cellDate(OffsetDateTime anchor, int n)` (dates mode; date-only)
  - `DateTime cellMoment(OffsetDateTime anchor, int n, {int stepHours = 4})` (UTC instant)
  - `DateTime localWallClock(DateTime utcInstant, LocalTimeZone zone)`
  - `int? todayCellInDatesMode(OffsetDateTime anchor, DateTime nowUtc, LocalTimeZone zone)`
  - `int? nowCellInDateTimeMode(OffsetDateTime anchor, DateTime nowUtc, {int stepHours = 4})`
- `cell_format.dart`: `String formatCellDate(DateTime date)` (`d.m.yy`), `String formatCellTime(DateTime wallClock)` (`HH:MM`).

## Reference values

**Design reference** (`02-square-of-nine_datetime_desktop_he_dark.png`). Anchor `1.11.2026 00:00`; Israel in November is +02:00, with no DST in the window:

| n | moment (UTC) | local display |
|---|---|---|
| 1 | 2026-10-31T22:00Z | `1.11.26` / `00:00` |
| 2 | +4 h | `1.11.26` / `04:00` |
| 52 | +204 h | `9.11.26` / `12:00` (design: "204 hours after the anchor") |
| 169 | +672 h | `29.11.26` / `00:00` (bottom-left of 13×13) |

**DST** uses a fake zone mirroring Israel 2026: +02:00 until `2026-03-27T00:00Z`, +03:00 until `2026-10-24T23:00Z`, then +02:00.

- **Spring** (anchor `2026-03-26T20:00+02:00`): local times 20:00, 00:00, **05:00** (not 04:00: the documented jump), 09:00.
- **Autumn** (anchor `2026-10-24T20:00+03:00`): local times 20:00, 00:00, **03:00** (not 04:00), 07:00.

**Leap year:**
- Anchor `2024-02-27`: dates `27.2.24`, `28.2.24`, `29.2.24`, `1.3.24`.
- Anchor `2026-02-27`: n = 3 → `1.3.26`.

**Today's cell:**
- **Dates mode, DST fake zone, anchor date 2026-03-25.** `nowUtc = 2026-03-27T21:30Z` is local 00:30 on 28.3 → cell **4**. Taking the UTC date would give 3, so the zone matters.
- **Date-and-time mode, design anchor.**
  - now = anchor + 204 h → **52**.
  - now = anchor + 207 h 59 m → 52.
  - now = anchor + 208 h → 53.
  - now = anchor − 1 min → `null`.

## Review Focus

1. **DST:** dates mode must never shift a date. Date-and-time mode must show the documented one-hour jump in both directions, never a silently corrected time. Pinned by the spring and autumn DST tests.
2. **Leap years and month ends:** Feb 29 is present in 2024 and absent in 2026, and month and year rollovers are right (31.12 → 1.1). Pinned by the leap-year tests.
3. **Today near local midnight:** the dates-mode today cell uses the **local** date, not the UTC date. Pinned by the 00:30 test, where the UTC date would be wrong.
4. **Before the anchor and block boundaries:** `null` before the anchor; exact 4-hour boundaries (207 h 59 m vs 208 h). Pinned in the today-cell tests.
5. **Format edges:** single- and double-digit days and months, years 2000–2009 (`05`), and midnight `00:00`. Pinned by the format tests.

---

### Task 1: `LocalTimeZone` + date mapping + today's cell (TDD)

**Files:** create `packages/gann_core/lib/src/dates/{local_time_zone,cell_values}.dart`; modify `packages/gann_core/lib/gann_core.dart`; test `packages/gann_core/test/dates/cell_values_test.dart`.

**Interfaces:** consumes `OffsetDateTime` (FND-012) and `maxSpiralNumber` (GAN-001); produces the API above, minus formatting.

- [ ] **Step 1: Write the failing tests.** The file defines a test-only `_DstZone implements LocalTimeZone` with the Israel-2026-like transitions above.
  - `group('LocalTimeZone')`:
    - `'FixedOffsetTimeZone returns its offset'`;
    - `'DeviceTimeZone matches DateTime.toLocal for sample instants'` (self-consistent on any machine);
    - `'rejects non-UTC input'`.
  - `group('numbers mode')`:
    - `'cellNumber(n) == n, rejects n < 1'`.
  - `group('dates mode')`:
    - `'the anchor cell is the anchor date'`;
    - `'consecutive calendar days, across a month and a year end'`: anchor `2026-12-30+02:00` → 30.12, 31.12, 1.1.2027;
    - `'leap year includes Feb 29; a common year does not'` (reference values);
    - `'is unaffected by DST'`: anchor `2026-03-25T00:00+02:00`, n = 1…5 → 25.3 … 29.3 with no gap or duplicate;
    - `'uses the anchor’s own calendar date, not UTC'`: anchor `2026-03-25T00:30+03:00` (UTC date 24.3) → cell 1 is 25.3;
    - `'rejects n < 1'`.
  - `group('date-and-time mode')`:
    - `'design reference: 1.11.2026 00:00 anchor'`: cells 1, 2, 52 and 169 → the local wall clocks in the table, using `FixedOffsetTimeZone(120)`;
    - `'spring DST: the displayed hour jumps forward by one'`;
    - `'autumn DST: the displayed hour jumps back by one'`;
    - `'honours stepHours'`: `stepHours: 6`, n = 2 → +6 h;
    - `'rejects stepHours < 1 and n < 1'`.
  - `group('today’s cell')`:
    - `'dates mode uses the local date (00:30 local, UTC date one day earlier)'` → 4;
    - `'dates mode: the anchor day is cell 1; before the anchor is null'`;
    - `'date-and-time mode: whole blocks elapsed + 1'`: 52, 52, 53;
    - `'date-and-time mode: before the anchor is null'`;
    - `'rejects non-UTC now'`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/dates`. Expected: compilation FAIL (undefined symbols).
- [ ] **Step 3: Implement.**
  - `cellDate`: `final w = anchor.wallClock; DateTime.utc(w.year, w.month, w.day + n − 1)`.
  - `cellMoment`: `anchor.instant.add(Duration(hours: stepHours * (n − 1)))`. Catch `DateTime` range errors → `ArgumentError`.
  - Today's cell, dates mode: the day difference between `DateTime.utc` dates of the local today and the anchor date, via `inDays` on UTC midnights, + 1.
  - Today's cell, date-and-time mode: `(now − anchor.instant).inMinutes ~/ (60·stepHours) + 1`, floored, with `null` when negative.
  - **Doc comments** state the decided time-zone rule (device zone, absolute steps, visible DST jump; dates mode calendar-only) and cite NFR-A3 and the GAN-003 notes.
- [ ] **Step 4:** Same command, then `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: all PASS / exit 0.
- [ ] **Step 5: Mutation proof.** Each change below must FAIL the suite; then restore:
  - (a) date-and-time mode uses wall-clock addition instead of absolute (`anchor.wallClock + hours`): the DST tests fail;
  - (b) dates mode uses `anchor.instant` (UTC date) instead of `anchor.wallClock`: the anchor-date test fails;
  - (c) today's cell (dates mode) uses the UTC date instead of the local one: the 00:30 test fails;
  - (d) the today-cell formula drops the `+ 1`.

  Record the results in the commit message.
- [ ] **Step 6:** Commit `feat(ZOD-GAN-003): map cells to dates and moments; today's cell; device-zone rule`.

### Task 2: Cell formatting `d.m.yy` / `HH:MM` (TDD)

**Files:** create `packages/gann_core/lib/src/dates/cell_format.dart`; modify `gann_core.dart`; test `packages/gann_core/test/dates/cell_format_test.dart`.

- [ ] **Step 1: Write the failing tests.**
  - `formatCellDate` (literal expectations):
    - `DateTime.utc(2022, 1, 4)` → `4.1.22`;
    - `(2024, 1, 4)` → `4.1.24`;
    - `(1999, 12, 31)` → `31.12.99`;
    - `(2005, 1, 5)` → `5.1.05`;
    - `(2026, 11, 1)` → `1.11.26`;
    - `(2026, 10, 9)` → `9.10.26`.
  - `formatCellTime`: 00:00 → `00:00`; 04:00 → `04:00`; 12:05 → `12:05`; 23:59 → `23:59`.
  - `'formats the design reference cells'`: cells 2, 52 and 169 combine to `1.11.26 / 04:00`, `9.11.26 / 12:00`, `29.11.26 / 00:00`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/dates`. Expected: compilation FAIL.
- [ ] **Step 3: Implement.** The date is `'${d.day}.${d.month}.${(d.year % 100).toString().padLeft(2, '0')}'`. The time pads hours and minutes to 2 digits. The doc comments cite SQ-3 / SQ-4 / T-FMT-1 and MASTER.md §8.2.
- [ ] **Step 4:** Same command, then lint and the full test run. Expected: all PASS / exit 0.
- [ ] **Step 5: Mutation proof.** Padding the day, padding the month, or using a 4-digit year must each FAIL. Restore afterwards and record the results.
- [ ] **Step 6:** Commit `feat(ZOD-GAN-003): format cell dates d.m.yy and times HH:MM`.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch code review (`requesting-code-review`), then resolve any important findings. Re-run lint and test.
- [ ] **Step 2:**
  - Set `Status: Done` in the task file and `TASKS.md`, and tick the acceptance criteria. (The GAN-003, TST-012 and TST-013 notes are committed in the planning commits.)
  - Update `docs/PROGRESS.md`: the decided time-zone rule as a convention (NFR-A3), the decision rows, verification, and the next task.
- [ ] **Step 3:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as amended 2026-11-12) | Proven by |
|---|---|
| Implemented and covered by own unit tests: anchor cell = anchor date; today's cell correct across a DST boundary and in a leap year; T-GAN-4 → TST-012 | Task 1: anchor-date tests, dates-mode DST test, today's cell at 00:30 local in the DST zone, the leap-year sequence, block boundaries |
| Own unit tests: `d.m.yy`, no leading zero, single- and double-digit day/month; T-FMT-1 → TST-013 | Task 2 literal format tests plus mutation proof |
| A 4-hour date-and-time square crossing DST shows the documented one-hour jump, not a corrected time | Task 1 spring and autumn DST tests (05:00 and 03:00 where 04:00 would be "corrected"), mutation (a) |

## Risks

- **Real-device DST behaviour depends on the OS zone database** used by `DateTime.toLocal`. `DeviceTimeZone` is a thin wrapper, its self-consistency is tested here, and real-device checks belong to NFR/QA.
- **The Excel export has no time zone** (spec line 256). It may show a different hour than the app on DST days. That's documented in the spec and owned by the XLS tasks.
